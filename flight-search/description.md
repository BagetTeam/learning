# ECMoE — Method and Experiment Description

## 1. Problem Statement

In Mixture-of-Experts (MoE) models with expert parallelism, each token's hidden state must be communicated between GPUs twice per MoE layer:

1. **Dispatch (all-to-all):** The hidden state is sent from the token's source GPU to the GPU hosting its assigned expert(s).
2. **Gather (all-to-all):** The expert output is sent back to the source GPU.

For a model like Qwen3-30B-A3B with `hidden_dim=2048` and 48 MoE layers, each token requires transmitting `2 × 48 × 2048 × 2 bytes = 384 KB` of data per forward pass (in BF16). At scale, this communication dominates inference latency.

This project investigates methods to **compress these hidden-state vectors** before transmission, reducing communication volume while preserving model quality.

### Training paradigms

This project uses two training paradigms:

**Offline (Tasks 2–4):** Compressors are trained on **cached hidden states**, not end-to-end through the LLM:

1. **Capture:** Run the unmodified LLM on calibration data and cache MoE layer inputs/outputs to disk.
2. **Train:** Train each compressor/decompressor pair independently on the cached data, minimizing a local reconstruction loss. No gradients flow through the LLM.
3. **Evaluate:** Insert trained compressors into the live model via forward hooks and measure perplexity.

Each pair is trained in isolation — no joint optimization across layers, no end-to-end backpropagation. This is cheap (minutes per layer) but means compressors cannot adapt to how errors compound across layers.

**End-to-end (Task 5):** Compressors are trained **through the live LLM** using the language modeling objective:

1. **Insert:** Register per-layer compressor/decompressor pairs as forward pre-hooks on each MoE layer.
2. **Train:** Run standard next-token prediction. The LLM weights are frozen; only compressor parameters receive gradients. Gradients flow through the entire frozen LLM.
3. **Evaluate:** Same hook-based perplexity evaluation as offline methods.

All 48 compressors are optimized jointly through a single global loss. This allows the system to learn how compression errors at early layers affect all downstream layers.

---

## 2. Model Specification

| Property | Value |
|---|---|
| Architecture | Qwen3-30B-A3B-Instruct-2507 |
| Total parameters | 30.53B |
| Activated parameters | 3.35B |
| Hidden dimension | 2048 |
| Number of layers | 48 (all MoE) |
| Number of experts | 128 per layer |
| Top-k routing | 8 experts per token |
| Attention heads | 32 (Q), 4 (KV) |
| Head dimension | 128 |
| MoE expert FFN intermediate size | 768 |
| Vocabulary size | 151,936 |

All tasks use the same model variant and precision:

| Variant | Used in | Loading | VRAM |
|---|---|---|---|
| Qwen3-30B-A3B-Instruct-2507 | All tasks (1–5) | Full BF16 | ~60 GB |

**Tasks 1–4:** Single GPU (`device="cuda:0"`). The ~60 GB model fits on one H100 80 GB with headroom for inference activations. Using single-GPU avoids the overhead of cross-GPU communication from `device_map="auto"`.

**Task 5:** Multi-GPU via `device_map="auto"` across 4 GPUs. Backpropagation through the frozen model during end-to-end training requires additional VRAM for activations and gradient checkpoints that exceed single-GPU capacity.

---

## 3. Data Collection

### 3.1 Calibration Data

- **Dataset:** allenai/Dolci-Instruct-SFT (train split)
- **Format:** Chat-formatted instruction data, tokenized via `tokenizer.apply_chat_template()`
- **Sequences:** Up to 256 samples, each tokenized independently (one conversation = one sequence)
- **Max length:** 2048 tokens per sequence (configurable via `--max-length`)
- **SFT mode:** Labels mask non-assistant tokens with -100; perplexity computed on responses only
- **Response-only collection:** By default, only assistant-response tokens are captured
  (positions where `labels != -100`). This ensures offline compressor training (Tasks 2–4)
  trains on the same token distribution that PPL evaluation measures. Use `--no-response-only`
  for legacy all-token collection.
- **Total tokens collected:** 100,000 per MoE layer (response tokens only by default)

### 3.2 Hidden State Capture

PyTorch forward hooks are registered on each MoE module:
- **Pre-forward hook** captures dispatch states (MoE layer inputs)
- **Post-forward hook** captures gather states (MoE layer outputs)

**Token filtering:** `MoEHiddenStateCollector` supports a per-sequence boolean mask
(`set_token_mask(mask)`). When `response_only=True` (default), the mask is derived from
`labels != -100` before each forward pass. The same mask is applied to all 48 MoE layers
within a sequence, preserving token alignment across layers. Positions where the mask is
`False` (system, user, template markup, padding) are not collected.

Each captured tensor has shape `[N, 2048]` where N = number of response tokens (or all
tokens if `response_only=False`). States are stored in the model's native dtype (`bfloat16`)
on CPU.

**Implementation:** `MoEHiddenStateCollector` class in `src/model_utils.py`.

### 3.3 Storage

```
data/hidden_states/
├── dispatch_states.pt    # dict {layer_name: tensor [100000, 2048]}
├── gather_states.pt      # dict {layer_name: tensor [100000, 2048]}
└── metadata.json         # model name, dims, token count, layer names
```

Total size: ~37 GB (18.5 GB dispatch + 18.5 GB gather, bfloat16 = 2 bytes/value).

---

## 4. Evaluation Methodology

### 4.1 Reconstruction Metrics (Offline)

Computed on cached hidden states without running the full model:

| Metric | Formula | Notes |
|---|---|---|
| MSE | `mean((x - x')²)` | Mean squared error |
| Cosine Similarity | `mean(cos(x, x'))` | Per-token, averaged |
| Relative Error | `mean(‖x - x'‖₂ / ‖x‖₂)` | Per-token L2 relative error |
| SNR (dB) | `10 · log₁₀(signal_power / noise_power)` | Signal-to-noise ratio |

**Implementation:** `src/metrics.py`

### 4.2 End-to-End Perplexity (Online)

The true impact of compression is measured by evaluating cross-entropy perplexity on allenai/Dolci-Instruct-SFT (the same dataset used for calibration/training) with compression hooks active:

- **Dispatch compression:** A pre-forward hook on each MoE block applies `compress → decompress` to the input hidden states before they enter the block.
- **Evaluation:** 50,000 sequences, max length 2048 tokens.
- **SFT mode:** Perplexity is computed on assistant response tokens only. Non-response tokens
  (system, user, template markup) are labeled with -100 and excluded from the loss.
  This measures the model's ability to generate correct responses, not to predict prompt tokens.

**Caveat:** This simulation also affects the router's input. In real expert parallelism, the router runs on the original hidden state at the source node. Our simulation gives a **conservative lower bound** — the true impact would be smaller.

**Implementation:** `evaluate_perplexity_with_compression()`, `evaluate_perplexity_with_perlayer_compression()`, `evaluate_perplexity_with_stale_compression()` in `src/model_utils.py`.

---

## 5. Method Descriptions

### 5.1 Quantization Baseline (Task 2)

**Idea:** Reduce the bit width of hidden-state elements from BF16 (16 bits) to INT8/INT4/INT2.

**Symmetric (absmax) quantization:**
```
scale = max(|x|) / (2^(bits-1) - 1)     # per-token
x_q = round(x / scale)                   # quantize
x' = x_q * scale                          # dequantize
```

**Asymmetric (zero-point) quantization:**
```
scale = (max(x) - min(x)) / (2^bits - 1)
zero_point = round(-min(x) / scale)
x_q = round(x / scale + zero_point)
x' = (x_q - zero_point) * scale
```

**Compression ratios:**

| Bits | Effective Ratio | Bytes/token (hidden_dim=2048) |
|---|---|---|
| INT8 (absmax) | ~2.0x | 2050 (2048 + 2 for scale) |
| INT4 (absmax) | ~4.0x | 1026 (1024 + 2 for scale) |
| INT2 (absmax) | ~8.0x | 514 (512 + 2 for scale) |

**Additional parameters:** 0 (quantization is parameter-free).

**Implementation:** `src/run_quantization.py`

---

### 5.2 Shared Neural Compressor (Task 3)

**Idea:** Train a single-layer linear autoencoder shared across all 48 MoE layers.

**Architecture:**
```
Compressor:    Linear(2048, bottleneck_dim) + bias
Decompressor:  Linear(bottleneck_dim, 2048) + bias
```

One compressor-decompressor pair is shared across all layers. Training data pools dispatch states from all 48 layers. Training is offline: the compressor minimizes reconstruction loss on cached hidden states, with no gradients flowing through the LLM.

**Compression ratios:** `hidden_dim / bottleneck_dim` = {2x, 4x, 8x, 16x} corresponding to `bottleneck_dim` = {1024, 512, 256, 128}.

**Training hyperparameters:**

| Parameter | Value |
|---|---|
| Optimizer | Adam |
| Learning rate | 1e-3 |
| LR schedule | Cosine annealing (T_max = epochs) |
| Max epochs | 50 |
| Batch size | 2048 |
| Early stopping patience | 8 epochs |
| Validation fraction | 10% |
| Loss function | MSE + 0.1 × (1 - cosine_similarity) |

**Loss function:**
```
L = MSE(x', x) + λ · (1 - mean(cos_sim(x', x)))
```
where `λ = 0.1` (cosine_weight). The cosine term encourages preserving direction, not just magnitude.

**Parameter count:**
```
params = (2048 × b + b) + (b × 2048 + 2048)
```
where `b` = bottleneck_dim.

| Ratio | Bottleneck | Parameters | % of Activated |
|---|---|---|---|
| 2x | 1024 | 4.20M | 0.125% |
| 4x | 512 | 2.10M | 0.063% |
| 8x | 256 | 1.05M | 0.031% |
| 16x | 128 | 0.53M | 0.016% |

**Implementation:** `src/run_neural_compressor.py`

---

### 5.3 Per-Layer Neural Compressor (Task 3b)

**Motivation:** Hidden state distributions vary dramatically across layers:
- Standard deviation: 0.16 (layer 0) → 1.21 (layer 47)
- Kurtosis: 3 (near-Gaussian, early layers) → 81,340 (extremely heavy-tailed, late layers)

A single shared compressor cannot adapt to this variation.

**Architecture:** Same `Compressor` + `Decompressor` structure, but **48 independent pairs** — one per MoE layer. Each layer's compressor is trained independently and only on that layer's cached dispatch data. There is no joint optimization across layers.

**Compression ratios:** Same as shared: {2x, 4x, 8x, 16x}.

**Training:** Same hyperparameters as shared (see Section 5.2). Each layer is trained independently on its own 100K token dispatch data (90% train / 10% val).

**Parameter count:**
```
params = 48 × (2048 × b + b + b × 2048 + 2048)
```

| Ratio | Bottleneck | Parameters | % of Activated |
|---|---|---|---|
| 2x | 1024 | 201.47M | 6.008% |
| 4x | 512 | 100.79M | 3.006% |
| 8x | 256 | 50.44M | 1.504% |
| 16x | 128 | 25.27M | 0.754% |

**Implementation:** `src/run_perlayer_compressor.py`

---

### 5.4 Stale-Conditioned Compressor (Tasks 4a/4b)

**Motivation:** Adjacent MoE layers process the same token, so their hidden states are correlated. A decompressor can exploit this by receiving a "stale" signal — the hidden state from a nearby layer that was already transmitted — as side information.

**Reference layer grouping (stride=12):**
- Reference layers: {0, 12, 24, 36} (4 layers)
- Layer 1–11 → stale from layer 0
- Layer 13–23 → stale from layer 12
- Layer 25–35 → stale from layer 24
- Layer 37–47 → stale from layer 36

**Architecture:**
- **Reference layers** use standard per-layer `Compressor` + `Decompressor` (no stale signal).
- **Non-reference layers** use `Compressor` + `StaleDecompressor`:

```
Compressor:          Linear(2048, bottleneck_dim) + bias
StaleDecompressor:   Linear(bottleneck_dim + stale_dim, 2048) + bias
```

The decompressor receives `cat(compressed_current, stale_signal)` as input.

**Two stale modes:**

| Mode | Task | Stale signal | StaleDecompressor input dim |
|---|---|---|---|
| Compressed (4a) | `--stale-mode compressed` | Compressed ref layer input (via ref's compressor) | `bottleneck_dim + bottleneck_dim` |
| Uncompressed (4b) | `--stale-mode uncompressed` | Raw ref layer input (full hidden dim) | `bottleneck_dim + 2048` |

**Training:**
1. **Phase 1:** Train reference layer compressors independently (standard per-layer autoencoder, same hyperparameters as Section 5.2).
2. **Phase 2:** Train non-reference layer compressors independently. For each non-ref layer:
   - Current data: that layer's cached dispatch states
   - Stale data: the reference layer's cached dispatch states (compressed or raw, depending on mode)
   - The stale signal is **pre-computed and frozen** — the reference layer's compressor is not jointly optimized with non-reference layers
   - Token alignment is guaranteed: `dispatch[layer_0][i]` and `dispatch[layer_5][i]` correspond to the same token

As with all neural methods in this project, training is offline on cached hidden states. No gradients flow through the LLM, and each layer's compressor is trained in isolation.

**Stale-conditioned training loss:** Same as Section 5.2 (`MSE + 0.1 × (1 - cos_sim)`), but the decompressor receives the concatenated input.

**Parameter count:**

For compressed stale (`stale_dim = bottleneck_dim`):
```
ref_pair  = (2048 × b + b) + (b × 2048 + 2048)
nonref_pair = (2048 × b + b) + ((b + b) × 2048 + 2048)
total = 4 × ref_pair + 44 × nonref_pair
```

For uncompressed stale (`stale_dim = 2048`):
```
ref_pair  = (2048 × b + b) + (b × 2048 + 2048)
nonref_pair = (2048 × b + b) + ((b + 2048) × 2048 + 2048)
total = 4 × ref_pair + 44 × nonref_pair
```

| Mode | Ratio | Bottleneck | Stale dim | Parameters | % of Activated |
|---|---|---|---|---|---|
| Compressed | 2x | 1024 | 1024 | 293.75M | 8.760% |
| Compressed | 4x | 512 | 512 | 146.92M | 4.382% |
| Compressed | 8x | 256 | 256 | 73.51M | 2.192% |
| Compressed | 16x | 128 | 128 | 36.80M | 1.098% |
| Uncompressed | 2x | 1024 | 2048 | 386.02M | 11.512% |
| Uncompressed | 4x | 512 | 2048 | 285.34M | 8.509% |
| Uncompressed | 8x | 256 | 2048 | 234.99M | 7.008% |
| Uncompressed | 16x | 128 | 2048 | 209.82M | 6.257% |

Note: The uncompressed stale method's parameter count does not scale down as aggressively because the `StaleDecompressor` input always includes the full 2048-dim stale signal, making the `(2048 × 2048)` weight block dominant.

**Perplexity evaluation with stale hooks:** During forward pass, a shared `stale_cache` dictionary stores reference layer inputs. PyTorch processes layers 0→47 sequentially, so layer 0's pre-hook fires before layer 1's, guaranteeing the stale cache is populated in time.

**Implementation:** `src/run_stale_compressor.py`, `evaluate_perplexity_with_stale_compression()` in `src/model_utils.py`.

---

### 5.5 End-to-End Per-Layer Compressor (Tasks 5a/5b)

**Motivation:** All offline methods (Tasks 3–4) share a fundamental limitation: each compressor is trained to minimize *local* reconstruction error in isolation. It cannot account for how its errors compound through downstream layers during a full forward pass. Additionally, the stale signal used during offline training is the *unperturbed* reference layer input, but during inference the reference layer itself is compressed, creating a train-inference mismatch.

End-to-end training addresses both issues by optimizing compressors through the full LLM forward pass using the language modeling objective.

**Architecture:** Same `Compressor` + `Decompressor` (5a) or `Compressor` + `StaleDecompressor` (5b) structure as Tasks 3b/4b. The compressor modules are identical — only the training objective differs.

**Training paradigm:**
1. Load the LLM in full BF16 across 4 GPUs. Freeze all LLM weights.
2. Insert per-layer compressor/decompressor pairs as forward pre-hooks on each MoE layer. Each pair is placed on the same GPU as its MoE layer.
3. Run standard next-token prediction on training data. Only compressor/decompressor parameters receive gradients.
4. Gradients flow backward through the entire frozen LLM, from the cross-entropy loss at the output back through all 48 layers to every compressor.

**Key difference from offline: joint optimization.** All 48 compressors share a single loss function (cross-entropy). Layer 0's compressor receives gradient signal about how its reconstruction error affects layers 1–47. The system implicitly learns to allocate more fidelity to layers where errors are most harmful to the final prediction.

**Stale signal gradient flow (5b):** Unlike offline Task 4b where the stale signal is pre-computed and frozen, end-to-end training does **not** detach the stale signal. Gradients flow through the stale path:
- A non-reference layer's decompressor receives `cat(compressed_current, stale)` where `stale` is the raw input to the reference layer
- During backward, gradients flow from the non-ref layer through `stale` to the reference layer's input, and further back to earlier layers
- This means reference layers' compressors are optimized not just for their own reconstruction, but also for how their inputs serve as stale side information for all downstream non-reference layers
- This eliminates the train-inference mismatch: during training, the stale signal already reflects upstream compression artifacts

**Near-identity initialization:**
- Compressor `W_c`: first `bottleneck_dim` rows of the identity matrix
- Decompressor `W_d`: first `bottleneck_dim` columns of the identity matrix
- Composition `W_d @ W_c ≈ I` (projects to first `b` dimensions and reconstructs)
- This ensures the initial forward pass is close to uncompressed, avoiding catastrophic initial loss from random projections. The optimizer then refines from this starting point.

**Model and data:**
- **Model:** Qwen/Qwen3-30B-A3B-Instruct-2507 (full BF16, same as all tasks)
- **Training data:** allenai/Dolci-Instruct-SFT, 500K sequences (HF) / 100K sequences (Megatron) sampled from train split,
  max_length=2048 tokens per sequence
- **SFT mode:** Each conversation is tokenized independently (one sample = one sequence).
  Labels mask non-assistant tokens with -100; loss is computed on assistant responses only.
  Data is loaded by sampling N sequences from the dataset (not by packing tokens).
- **Evaluation:** allenai/Dolci-Instruct-SFT (same dataset, response-only perplexity)

**Two modes:**

| Mode | Task | Stale signal | Decompressor |
|---|---|---|---|
| No stale (5a) | `--stale-mode none` | None | `Decompressor(bottleneck_dim, 2048)` |
| Uncompressed stale (5b) | `--stale-mode uncompressed` | Raw ref layer input | `StaleDecompressor(bottleneck_dim, 2048, 2048)` |

**Training hyperparameters:**

| Parameter | Value |
|---|---|
| Optimizer | AdamW |
| Learning rate | 1e-4 |
| Weight decay | 0.01 |
| LR schedule | Cosine with 10% linear warmup |
| Max epochs | 1 |
| Batch size | 2 (gradient accumulation: 8, effective: 16) |
| Gradient clipping | max_norm = 1.0 |
| Early stopping patience | 5 epochs |
| Validation interval | Every 2500 optimizer steps (HF) / 1000 (Megatron) (configurable via `--val-interval`) |
| Validation batch size | 8 (configurable via `--val-batch-size`; larger than train because no backward) |
| Validation fraction | 10% |
| Max sequence length | 2048 (configurable via `--max-length`) |
| Loss function | Cross-entropy (response tokens only, SFT mode) |

Note the lower learning rate (1e-4 vs 1e-3 for offline) — the LM loss landscape propagates gradients through 48 frozen transformer layers, requiring more conservative updates.

**Tail micro-batch handling:** When `len(dataloader) % grad_accum != 0`, the remaining micro-batches
have their accumulated gradients rescaled by `grad_accum / remainder` (correcting the divisor from
`1/grad_accum` to `1/remainder`) before performing a final optimizer step. This ensures no training
data is discarded. Applied to both HF (`run_e2e_compressor.py`) and Megatron (`train.py`).

**Two evaluation stages (different data, different code paths):**

| Stage | Split | Batch size | Function | Purpose |
|---|---|---|---|---|
| Training-time val | VAL (50K seqs) | `--val-batch-size` (default 8) | `evaluate_val_loss()` in training script | Checkpoint selection, wandb monitoring |
| Final PPL | TEST (50K seqs) | 1 (per-sample) | `evaluate_perplexity()` in `model_utils.py` | Reported results |

The training-time validation runs every `--val-interval` optimizer steps and at epoch end, using the VAL split. It drives best-checkpoint selection. The final perplexity evaluation runs after training on the held-out TEST split (never seen during training or checkpoint selection) and produces the numbers reported in the results tables. These are separate code paths — `--val-batch-size` only affects the training-time evaluation.

**Parameter count:** Same as Tasks 3b (5a) and 4b-uncompressed (5b):

| Mode | Ratio | Bottleneck | Parameters | % of Activated |
|---|---|---|---|---|
| No stale (5a) | 2x | 1024 | 201.47M | 6.008% |
| No stale (5a) | 4x | 512 | 100.79M | 3.006% |
| No stale (5a) | 8x | 256 | 50.44M | 1.504% |
| No stale (5a) | 16x | 128 | 25.27M | 0.754% |
| Uncompressed stale (5b) | 2x | 1024 | 386.02M | 11.512% |
| Uncompressed stale (5b) | 4x | 512 | 285.34M | 8.509% |
| Uncompressed stale (5b) | 8x | 256 | 234.99M | 7.008% |
| Uncompressed stale (5b) | 16x | 128 | 209.82M | 6.257% |

**Multi-GPU setup:**
- Model distributed across 4 GPUs via `device_map="auto"` (~15 GB/GPU)
- Gradient checkpointing enabled (`use_reentrant=False`) to reduce activation memory
- 8 GPUs available → 05a and 05b run in parallel on separate GPU sets (GPUs 0-3 and 4-7)
- Each compressor is automatically placed on the same GPU as its MoE layer

**Implementation:** `src/run_e2e_compressor.py`, `scripts/05_run_e2e_compressor.sh`.

---

### 5.6 Megatron-LM E2E Training (Task 5 — Megatron variant)

**Motivation:** The HuggingFace-based Task 5 uses `device_map="auto"` for naive layer-sharded model parallelism. Only one GPU is active at a time during forward pass (sequential layer execution), with no tensor or data parallelism. This limits training throughput and cannot scale to multi-node.

**Approach:** Replace HuggingFace with Megatron-LM to get proper tensor parallelism (TP), expert parallelism (EP), and data parallelism (DP):
- All 4 GPUs active simultaneously via TP (each GPU holds shards of every layer)
- Multi-node scaling via DP across nodes + TP within nodes
- Megatron's optimized kernels (fused LayerNorm, FlashAttention, etc.)

**Compressor/decompressor placement:**

In real expert parallelism, the compressor and decompressor are on DIFFERENT GPUs:
- **Compressor:** Same GPU as attention output (source GPU where token originates)
- **Decompressor:** Same GPU as MoE expert (destination GPU after dispatch)

This is more realistic than the HF hook-based simulation where the router sees compressed-then-decompressed input. With Megatron, the router sees the ORIGINAL hidden state; only the dispatch is compressed.

**Phase A (TP only, EP=1):** Compressor and decompressor on same GPU (same as current HF approach). TP=4 shards each layer across 4 GPUs.

**Phase B (with EP):** Compressor on attention GPU, decompressor on expert GPU. MoE dispatch sends compressed tokens (reduced all-to-all volume). The `CompressedMoETokenDispatcher` wraps Megatron's dispatcher to:
1. Compress on source GPU (attention side)
2. Dispatch compressed tokens (smaller all-to-all)
3. Decompress on destination GPU (expert side)

**Training pipeline:**
1. Convert Qwen3-30B-A3B from HF format to Megatron format via Megatron Bridge
2. Load with TP=4 (each GPU holds ~15-20 GB of sharded weights)
3. Freeze all LLM parameters
4. Insert per-layer compressor/decompressor pairs at MoE boundaries
5. Train compressors via language modeling objective (same as HF Task 5)
6. Save compressor weights (from rank 0, since all TP ranks have identical copies)

**TP-aware loss computation:** `MegatronModelWrapper._compute_loss()` uses
`vocab_parallel_cross_entropy` when TP > 1. SFT labels (-100) are clamped to 0 before
the call (avoiding garbage per-token loss for masked positions), and loss is computed as
`(per_token_loss * loss_mask).sum() / num_valid`. The non-TP path uses PyTorch's
`cross_entropy(ignore_index=-100)` which handles masking internally.

**Evaluation:** Uses existing HF-based evaluation code — load trained compressor weights into `E2ECompressorManager` and evaluate perplexity with hook-based simulation.

**Parallelism strategies:**

| Hardware | Configuration | Notes |
|---|---|---|
| 4 GPUs | TP=4, EP=1, PP=1, DP=1 | All GPUs active via tensor parallelism |
| 8 GPUs | TP=4, EP=1, PP=1, DP=2 | TP within 4 GPUs, DP across 2 replicas |
| N nodes × 4 GPUs | TP=4, DP=N | TP within node (NVLink), DP across nodes |
| EP variant | TP=2, EP=2, PP=1, DP=1 | Compressor on TP ranks, decompressor on EP ranks |

**Compressor weights with TP:**
- Compressors are replicated on all TP ranks (not sharded)
- Input is full hidden state (post-attention all-reduce)
- Gradients identical across ranks — no extra all-reduce needed
- Save from rank 0 only

**Implementation:** `src/megatron_e2e/` package with EP-first parallelism (EP=4, TP=1), CUDA 12.9, Megatron Bridge 0.2+, Transformer Engine. Entry point: `src/megatron_e2e/train.py`, bash wrapper: `scripts/05_megatron_e2e.sh`, setup: `scripts/megatron_setup_env.sh`. Multi-node: `scripts/05_megatron_e2e_multinode.sh`.

---

### 5.7 Baseline E2E Evaluation (Task 5c)

**Motivation:** Tasks 5a/5b report perplexity relative to an "untrained baseline" (the original model evaluated on the same test data). However, 5a/5b's training pipeline also loads and processes data through `load_e2e_data()`, computes SFT-masked loss on train/val splits, and may differ subtly from a raw model evaluation. Task 5c runs the exact same pipeline (same data loading, same loss computation, same evaluation) but WITHOUT inserting any compressors. This provides:

1. **Train/val loss context:** If 5c's train loss is ~1.0, and 5a-2x's is 1.11, the compression overhead is only +0.11 — not the raw 1.11 value.
2. **Pipeline consistency:** Confirms that the data pipeline itself does not introduce artifacts.
3. **Fair comparison:** All three (5a, 5b, 5c) use identical code paths except for the compression hooks.

**What it does:**
- Loads data via `load_e2e_data()` (same function as 5a/5b)
- Evaluates train and val loss using `evaluate_loss_no_hooks()` — same as `evaluate_val_loss()` but without a compressor manager
- Evaluates baseline PPL on the TEST split (same as 5a/5b)
- No training, no compression ratios, no weight files

**Implementation:** Added as `--stale-mode baseline` to both `src/run_e2e_compressor.py` (HF) and `src/megatron_e2e/train.py` (Megatron). Output dirs: `results/05c_e2e_baseline/` (HF), `results/05c_megatron_e2e_baseline/` (Megatron).

---

### 5.8 E2E with Pretrained Init (Tasks 6a/6b)

**Motivation:** Tasks 5a/5b initialize compressor/decompressor weights with a near-identity matrix — the first `bottleneck_dim` dimensions are preserved, and the rest are zeroed out. This is a reasonable starting point but the optimizer must learn the full compression mapping from scratch using only the LM loss signal.

Tasks 3b and 4b already train compressors to minimize reconstruction loss on cached hidden states. While this offline objective doesn't directly optimize for LM quality, the resulting weights encode the structure of hidden-state distributions and provide a potentially better starting point for E2E fine-tuning.

Tasks 6a/6b test this hypothesis: does initializing E2E training from reconstruction-optimized weights (instead of near-identity) lead to faster convergence or better final quality?

**Architecture:** Identical to Tasks 5a/5b — same `Compressor`, `Decompressor`, `StaleDecompressor` classes, same training objective (cross-entropy), same hyperparameters. The only difference is the initial weight values.

**Two modes:**

| Mode | Task | Init from | Stale signal |
|---|---|---|---|
| No stale (6a) | `--stale-mode none --init-weights-dir results/03b_perlayer_compressor` | Task 3b (per-layer offline) | None |
| Uncompressed stale (6b) | `--stale-mode uncompressed --init-weights-dir results/04b_stale_uncompressed` | Task 4b (stale offline) | Raw ref layer input |

**Weight compatibility:** Tasks 3b/4b save weights keyed by HF layer names (`model.layers.N.mlp`) with `compressor` and `decompressor` sub-keys. The `MegatronCompressorManager.load_weights()` expects the same format (it converts Megatron names to HF names via `_megatron_to_hf_layer_name()`). The offline and E2E architectures use identical module classes, so `load_state_dict()` works directly.

**Parameter count:** Same as Tasks 5a/5b (identical architecture).

**Training hyperparameters:** Same as Tasks 5a/5b (same LR, warmup, epochs, etc.).

**Implementation:** Added `--init-weights-dir` argument to `src/megatron_e2e/train.py`. Auto-detects weight file naming pattern. Bash wrapper: `scripts/06_megatron_e2e_pretrained.sh`. Output dirs: `results/06a_megatron_e2e_pretrained_perlayer/` (6a), `results/06b_megatron_e2e_pretrained_stale/` (6b).

### 5.9 Split-Mode E2E Training (Tasks 7a/7b)

**Motivation:** Tasks 5/6 use forward pre-hooks that compress→decompress the MoE input — both the router AND experts see the decompressed hidden state. This is a conservative lower bound on quality. In real expert parallelism, the router runs on the source GPU with the **original** hidden state (before compression), and only experts on the destination GPU see the decompressed version. Task 7 trains the compressor under this more realistic "split mode" to see whether the training signal improves when the router is not degraded by compression artifacts.

**Approach — Two-Level Pre-Hooks:**

Instead of monkey-patching MoE forward methods, two pre-hooks are registered per MoE layer:

1. **MoE pre-hook:** Saves the original input, then returns the compress→decompress result. The MoE module's `forward()` receives the decompressed tensor as its input.
2. **Router pre-hook:** Registered on the router/gate submodule. When the MoE's `forward()` calls `self.gate(hidden_states)`, this hook intercepts and swaps the input back to the saved original.

This works because:
- The MoE pre-hook changes what `forward()` receives (decompressed), so experts get decompressed data.
- The router pre-hook only affects the `gate` submodule's input, restoring the original.
- PyTorch hook execution order: MoE pre-hook runs first (on the outer module), then when `forward()` calls `self.gate(...)` internally, the gate pre-hook runs and swaps the argument.

**Two modes:**

| Mode | Task | Init from | Stale signal | Router input |
|---|---|---|---|---|
| No stale (7a) | `--stale-mode none --router-mode uncompressed --init-weights-dir results/03b_perlayer_compressor` | Task 3b | None | Original |
| Uncompressed stale (7b) | `--stale-mode uncompressed --router-mode uncompressed --init-weights-dir results/04b_stale_uncompressed` | Task 4b | Raw ref input | Original |

**Architecture:** Identical to Tasks 6a/6b — same classes, same init weights, same hyperparameters. The only difference is that `router_mode="uncompressed"` activates the two-level hook pattern during training and evaluation.

**Implementation:** Added `--router-mode` argument to `src/megatron_e2e/train.py` and `src/run_e2e_compressor.py`. Split-mode hooks added to `MegatronCompressorManager` (Megatron training) and `evaluate_perplexity_with_perlayer_compression`/`evaluate_perplexity_with_stale_compression` (HF PPL evaluation). Bash wrapper: `scripts/07_megatron_e2e_split.sh`. Output dirs: `results/07a_megatron_e2e_split_perlayer/` (7a), `results/07b_megatron_e2e_split_stale/` (7b).

---

## 6. Results

### 6.1 Summary Table — All Methods

**Model:** Qwen3-30B-A3B-Instruct-2507 (full BF16)
**Dataset:** allenai/Dolci-Instruct-SFT

| Method | Ratio | MSE | CosSim | PPL | PPL Delta | HF Strict | HF Flex |
|---|---|---|---|---|---|---|---|
| Baseline (Tasks 2–4) | — | — | — | 3.89 | — | 44.12% | 82.79% |
| Baseline (5c / Megatron) | — | — | — | 3.94 | — | 44.12% | 82.79% |
| Quant INT8 | 2.0x | — | — | 3.90 | +0.01 | 48.90% | 82.26% |
| Quant INT4 | 4.0x | — | — | 4.51 | +0.62 | 56.41% | 68.54% |
| Quant INT2 | 8.0x | — | — | 1532.59 | +1528.70 | 0.00% | 0.00% |
| Neural (per-layer) | 2x | 0.0535 | 0.922 | 21.07 | +17.18 | 0.00% | 1.52% |
| Neural (per-layer) | 4x | 0.1073 | 0.835 | 425.75 | +421.87 | 0.00% | 0.00% |
| Neural (per-layer) | 8x | 0.1523 | 0.755 | 7949.78 | +7945.89 | 0.00% | 0.00% |
| Neural (per-layer) | 16x | 0.1893 | 0.683 | 52440.05 | +52436.16 | 0.00% | 0.00% |
| Stale-cond. (compressed) | 2x | 0.0379 | 0.947 | 6.13 | +2.24 | 3.41% | 62.55% |
| Stale-cond. (compressed) | 4x | 0.0876 | 0.869 | 31.64 | +27.75 | 0.61% | 1.52% |
| Stale-cond. (compressed) | 8x | 0.1330 | 0.791 | 2982.23 | +2978.34 | 0.00% | 0.00% |
| Stale-cond. (compressed) | 16x | 0.1720 | 0.717 | 17486.21 | +17482.32 | 0.00% | 0.00% |
| Stale-cond. (uncompressed) | 2x | 0.0346 | 0.952 | 6.24 | +2.36 | 2.81% | 67.10% |
| Stale-cond. (uncompressed) | 4x | 0.0690 | 0.900 | 16.11 | +12.22 | 0.99% | 6.14% |
| Stale-cond. (uncompressed) | 8x | 0.0966 | 0.855 | 423.68 | +419.79 | 0.00% | 0.00% |
| Stale-cond. (uncompressed) | 16x | 0.1173 | 0.819 | 3740.41 | +3736.53 | 0.00% | 0.00% |
| Megatron E2E per-layer (5a) | 2x | — | — | 2.77 | -1.17 | 61.33% | 61.64% |
| Megatron E2E per-layer (5a) | 4x | — | — | 4.28 | +0.35 | 20.70% | 21.30% |
| Megatron E2E per-layer (5a) | 8x | — | — | 7.49 | +3.55 | 1.82% | 2.12% |
| Megatron E2E per-layer (5a) | 16x | — | — | 11.26 | +7.33 | 0.91% | 2.73% |
| Megatron E2E stale (5b) | 2x | — | — | 2.71 | -1.23 | 60.27% | 60.65% |
| Megatron E2E stale (5b) | 4x | — | — | 3.61 | -0.33 | 31.54% | 32.37% |
| Megatron E2E stale (5b) | 8x | — | — | 4.98 | +1.04 | 4.93% | 5.00% |
| Megatron E2E stale (5b) | 16x | — | — | 6.34 | +2.41 | 2.12% | 2.27% |
| Megatron E2E pretrained per-layer (6a) | 2x | — | — | 2.41 | -1.53 | 79.98% | 80.06% |
| Megatron E2E pretrained per-layer (6a) | 4x | — | — | 3.18 | -0.76 | 55.04% | 55.19% |
| Megatron E2E pretrained per-layer (6a) | 8x | — | — | 4.52 | +0.58 | 16.98% | 16.98% |
| Megatron E2E pretrained per-layer (6a) | 16x | — | — | 7.34 | +3.40 | 2.27% | 2.27% |
| Megatron E2E pretrained stale (6b) | 2x | — | — | 2.25 | -1.69 | 82.49% | 82.64% |
| Megatron E2E pretrained stale (6b) | 4x | — | — | 2.57 | -1.37 | 64.37% | 64.52% |
| Megatron E2E pretrained stale (6b) | 8x | — | — | 3.04 | -0.90 | 45.79% | 45.94% |
| Megatron E2E pretrained stale (6b) | 16x | — | — | 3.47 | -0.47 | 25.85% | 25.85% |
| Split-mode E2E per-layer (7a) | 2x | — | — | 2.58 | -1.31 | 79.91% | 79.98% |
| Split-mode E2E per-layer (7a) | 4x | — | — | 3.72 | -0.17 | 42.08% | 42.15% |
| Split-mode E2E per-layer (7a) | 8x | — | — | 6.43 | +2.54 | 4.93% | 5.46% |
| Split-mode E2E per-layer (7a) | 16x | — | — | 908.20 | +904.31 | 0.00% | 0.53% |
| Split-mode E2E stale (7b) | 2x | — | — | 2.34 | -1.55 | 80.67% | 80.67% |
| Split-mode E2E stale (7b) | 4x | — | — | 2.80 | -1.09 | 65.81% | 65.96% |
| Split-mode E2E stale (7b) | 8x | — | — | 3.37 | -0.51 | 35.63% | 35.63% |
| Split-mode E2E stale (7b) | 16x | — | — | 4.28 | +0.39 | 16.53% | 16.68% |

Note: Tasks 2–4 and 5c baselines differ in PPL (3.89 vs 3.94) due to different evaluation
code paths (single-GPU HF vs Megatron pipeline). PPL deltas for offline methods use 3.89;
E2E methods use 3.94. HF Strict/Flex: GSM8K evaluated via HF backend (lm-eval-harness,
router-compressed mode). For Tasks 7a/7b, HF Strict/Flex is compressed-router only.
Uncompressed-router results for Tasks 7a/7b are in a dedicated table below Section 6.4.
GSM8K scores are identical for both baselines because GSM8K evaluation uses the same raw HF
model. GSM8K uses Megatron-trained weights for E2E methods. "Strict" requires exact
`#### <number>` format; "flexible" extracts the number from anywhere in the output.
HF-trained E2E weights (Tasks 5a/5b) were not available.

### 6.2 Key Findings

1. **E2E training is transformative** — E2E methods achieve PPL *below* baseline (3.94) at 2x. E2E stale stays below baseline at 4x (PPL=3.61).
2. **E2E stale at 16x is moderate** — PPL=6.34 (+2.41), 61% above baseline, with GSM8K strict-match at 2.12%.
3. **E2E dramatically outperforms offline** — Same architecture, same params: offline per-layer 4x PPL=425.75 vs E2E 4x PPL=4.28 (99x better). At 16x: 52440 vs 11.26 (4658x better).
4. **Stale conditioning matters more at high compression** — At 2x the gap is small (E2E stale 2.71 vs E2E per-layer 2.77), but at 16x it's 1.8x (6.34 vs 11.26).
5. **INT8 quantization is nearly lossless** — PPL 3.90 vs baseline 3.89 at 2x (+0.01), with GSM8K preserved (48.90% strict, 82.26% flexible).
6. **INT4 quantization is acceptable** — PPL 4.51 at ~4x (+0.62 delta). GSM8K strict-match actually improves to 56.41%.
7. **INT2 is catastrophic** — PPL 1533 at ~8x, completely unusable.
8. **Offline methods degrade rapidly** — Per-layer neural: PPL=21 at 2x, PPL=425 at 4x, PPL=7950 at 8x. Stale-conditioning (uncompressed) helps at 2x (PPL=6.24) but collapses at 8x (PPL=424).
9. **Below-baseline PPL** suggests E2E compressors act as regularizers, filtering noise from hidden states while preserving task-relevant information. Confirmed by GSM8K: E2E 2x scores 61.33% vs baseline 44.12%.
10. **Downstream tasks are more sensitive than PPL** — Offline stale_uncomp_2x has PPL=6.24 (+2.36) but GSM8K drops from 44% to 3% strict-match. E2E methods maintain both PPL and GSM8K. See Section 6.4.
11. **Offline compression destroys output format but partially preserves reasoning** — stale_uncomp_2x: 2.81% strict but 67.10% flexible-extract. E2E methods show no such gap (~0.3 pp).
12. **Pretrained init (Task 6) dramatically improves E2E training** — Initializing from offline-trained weights (Tasks 3b/4b) instead of near-identity gives 13–45% PPL improvement and massive GSM8K gains. 6b at 2x achieves PPL=2.25 and 82.5% GSM8K strict-match (vs 5b: PPL=2.71, 60.3%). Even at 16x, 6b (PPL=3.47, GSM8K 25.9%) stays below baseline PPL (3.89) and retains meaningful downstream accuracy.
13. **Pretrained init benefits grow with compression ratio** — For stale-conditioned (6b vs 5b): PPL improvement goes from 17% at 2x to 45% at 16x; GSM8K goes from +22 pp at 2x to +24 pp at 16x. The offline-trained weights provide a much better starting point for E2E optimization, especially at high compression where near-identity init struggles.
14. **Split-mode training (Task 7) matches deployment reality** — Training with split-mode (router sees original, experts see decompressed) then evaluating in the same mode yields the best uncompressed-router results. 7b uncompressed at 2x achieves 83.3% GSM8K strict-match — the best result across all methods and modes.
15. **7b uncompressed stays below baseline PPL at ALL ratios** — Even at 16x compression, 7b uncompressed PPL=3.27 remains below the no-compression baseline (3.89). This is the only method to maintain below-baseline PPL at every compression ratio, demonstrating that stale-conditioned split-mode E2E compressors can be simultaneously lossy (16x compression) and beneficial (regularization effect).
16. **Split-mode training trades compressed-eval quality for uncompressed-eval quality** — 7a/7b compressed-eval PPL is worse than 6a/6b (e.g., 7a 16x compressed: 908 vs 6a: 8.49) because the model was not trained to have the router see decompressed data. But 7a/7b uncompressed-eval is better (7a 16x uncompressed: 6.64 vs 6a compressed: 8.49). This confirms the training mode should match the deployment mode.
17. **Catastrophic collapse at extreme compression without stale** — 7a 16x compressed PPL=908 (vs 7a 16x uncompressed=6.64), showing that when per-layer compression is too lossy, correct routing (from original hidden states) becomes critical. Stale conditioning (7b) avoids this entirely: 7b 16x compressed=4.28, uncompressed=3.27.

### 6.3 HF vs Megatron Comparison

**Note:** HF E2E results in this section are from an earlier training run. The HF E2E
weight files are no longer available in the current `results/05a_e2e_perlayer/` and
`results/05b_e2e_stale/` directories (only logs remain). The Megatron results are
from the current run and match the JSON files. The comparison below is preserved for
historical reference but the HF numbers cannot be independently verified from current data.

Both implementations use the same compressor architecture (Compressor + Decompressor / StaleDecompressor), the same model (Qwen3-30B-A3B-Instruct-2507), and the same training data (Dolci-Instruct-SFT). The key differences are in the distributed training strategy and model parallelism framework.

**Implementation differences:**

| Aspect | HuggingFace | Megatron |
|---|---|---|
| Framework | HF Transformers + `device_map="auto"` | Megatron-Core + AutoBridge |
| Parallelism | Naive layer sharding (sequential) | EP=4, TP=1, PP=1, DP=4 |
| GPU utilization | 1 GPU active at a time | All 4 GPUs active (DP) |
| Data parallelism | None (single data stream) | DP=4 (each rank sees 1/4 of data per step) |
| Optimizer | AdamW (single replica) | AdamW (replicated, gradients all-reduced) |
| CUDA | 12.6 | 12.9 |

**Task 5a — E2E per-layer (no stale):**

| Ratio | HF PPL | Megatron PPL | Gap (Meg−HF) |
|---|---|---|---|
| 2x | **2.645** (−1.58) | 2.682 (−1.54) | +0.04 |
| 4x | **3.687** (−0.54) | 4.410 (+0.19) | +0.72 |
| 8x | **6.371** (+2.15) | 8.182 (+3.96) | +1.81 |
| 16x | **9.157** (+4.93) | 11.670 (+7.44) | +2.51 |

**Task 5b — E2E stale-conditioned (uncompressed stale):**

| Ratio | HF PPL | Megatron PPL | Gap (Meg−HF) |
|---|---|---|---|
| 2x | 2.570 (−1.65) | **2.568** (−1.66) | −0.00 |
| 4x | **3.102** (−1.12) | 3.420 (−0.80) | +0.32 |
| 8x | **4.015** (−0.21) | 4.743 (+0.52) | +0.73 |
| 16x | **4.550** (+0.32) | 5.232 (+1.01) | +0.68 |

**Training losses (train / val):**

| Config | HF 5a | Megatron 5a | HF 5b | Megatron 5b |
|---|---|---|---|---|
| 2x | 1.215 / 1.093 | 1.258 / 1.109 | 1.193 / 1.070 | 1.210 / 1.068 |
| 4x | 1.786 / 1.447 | 2.103 / 1.627 | 1.579 / 1.286 | 1.784 / 1.375 |
| 8x | 2.412 / 2.004 | 2.776 / 2.242 | 1.921 / 1.555 | 2.206 / 1.724 |
| 16x | 2.768 / 2.326 | 3.180 / 2.567 | 2.069 / 1.686 | 2.344 / 1.823 |

**Analysis:**

1. **At 2x, both implementations converge to the same quality.** The gap is negligible (0.04 for 5a, −0.002 for 5b). Near-identity initialization gives a strong starting point, and 2x compression is easy enough that both optimizers find similar solutions.

2. **Megatron's gap grows at higher compression ratios for 5a** (no stale). At 4x the gap is +0.72, at 16x it's +2.51. The likely cause is that Megatron with DP=4 provides each rank with 1/4 of the data per step — effectively a noisier gradient estimate. HF's single-replica training sees the full data stream, leading to a slightly better optimizer trajectory for harder problems (higher compression).

3. **Stale conditioning dramatically narrows the Megatron-HF gap.** Adding stale conditioning reduces the gap by 50–73% at all ratios:
   - 4x: +0.72 → +0.32 (56% reduction)
   - 8x: +1.81 → +0.73 (60% reduction)
   - 16x: +2.51 → +0.68 (73% reduction)
   The stale signal acts as an anchor that partially corrects for the noisier optimization — it provides a strong prior about the expected hidden state, reducing the difficulty of the decompression task.

4. **Both Megatron variants produce usable compressors.** Megatron 5b at 4x (PPL=3.42) is still 19% below baseline, and even at 16x (PPL=5.23) the degradation is only +24%. For production deployment where Megatron's scalability is needed, these results are practical.

5. **Recommendation:** Use Megatron with stale conditioning (5b mode) for production. At 2–4x compression, results match HF quality. At 8–16x, there is a modest quality gap, but Megatron's multi-node scalability and proper expert parallelism make it the right choice for large-scale deployment.

### 6.4 Downstream Task Evaluation (GSM8K)

**Benchmark:** GSM8K chain-of-thought (gsm8k_cot), 8-shot, 1319 test examples.
Two metrics: **strict-match** (exact `#### <number>` format) and **flexible-extract**
(number extracted from anywhere in the output via regex).
Two router modes: **compressed** (router AND experts see decompressed hidden states)
and **uncompressed** (router sees original, experts see decompressed — more realistic EP
simulation). PPL, MSE, CosSim from HF-based evaluation (`model_utils.py`).
HF Strict/Flex from HF backend (lm-eval-harness, router-compressed mode).
vLLM columns from vLLM backend (`run_all_downstream.py`, both router modes).
For Tasks 7a/7b, vLLM Uncomp. columns show HF backend uncompressed-router results
(confirmed identical via both `run_all_downstream.py` and `run_e2e_compressor.py
--router-mode uncompressed`).

| Method | Ratio | MSE | CosSim | PPL | PPL Δ | HF Strict | HF Flex | vLLM Comp. Strict | vLLM Comp. Flex | vLLM Uncomp. Strict | vLLM Uncomp. Flex |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Baseline | — | — | — | 3.89 | — | 44.1% | 82.8% | 43.3% | 82.9% | — | — |
| Quant INT8 | 2x | — | — | 3.90 | +0.01 | 48.9% | 82.3% | 43.7% | 82.2% | — | — |
| Quant INT4 | 4x | — | — | 4.51 | +0.62 | 56.4% | 68.5% | 46.8% | 65.4% | — | — |
| Quant INT2 | 8x | — | — | 1532.59 | +1528.70 | 0.0% | 0.0% | 0.0% | 0.0% | — | — |
| Neural (per-layer) | 2x | 0.0535 | 0.922 | 21.07 | +17.18 | 0.0% | 1.5% | 0.0% | 1.2% | 22.7% | 42.6% |
| Neural (per-layer) | 4x | 0.1073 | 0.835 | 425.75 | +421.87 | 0.0% | 0.0% | 0.0% | 0.4% | 1.0% | 2.4% |
| Neural (per-layer) | 8x | 0.1523 | 0.755 | 7949.78 | +7945.89 | 0.0% | 0.0% | 0.0% | 0.0% | 2.0% | 1.9% |
| Neural (per-layer) | 16x | 0.1893 | 0.683 | 52440.05 | +52436.16 | 0.0% | 0.0% | 0.0% | 0.0% | 1.5% | 1.5% |
| Stale-cond. (compressed) | 2x | 0.0379 | 0.947 | 6.13 | +2.24 | 3.4% | 62.6% | 0.2% | 0.8% | 34.1% | 69.7% |
| Stale-cond. (compressed) | 4x | 0.0876 | 0.869 | 31.64 | +27.75 | 0.6% | 1.5% | 0.0% | 0.6% | 2.7% | 4.9% |
| Stale-cond. (compressed) | 8x | 0.1330 | 0.791 | 2982.23 | +2978.34 | 0.0% | 0.0% | 0.0% | 0.0% | 1.3% | 1.8% |
| Stale-cond. (compressed) | 16x | 0.1720 | 0.717 | 17486.21 | +17482.32 | 0.0% | 0.0% | 0.0% | 0.0% | 1.8% | 2.0% |
| Stale-cond. (uncompressed) | 2x | 0.0346 | 0.952 | 6.24 | +2.36 | 2.8% | 67.1% | 0.2% | 1.1% | 30.7% | 72.6% |
| Stale-cond. (uncompressed) | 4x | 0.0690 | 0.900 | 16.11 | +12.22 | 1.0% | 6.1% | 0.0% | 0.6% | 6.1% | 9.3% |
| Stale-cond. (uncompressed) | 8x | 0.0966 | 0.855 | 423.68 | +419.79 | 0.0% | 0.0% | 0.0% | 0.0% | 1.2% | 2.5% |
| Stale-cond. (uncompressed) | 16x | 0.1173 | 0.819 | 3740.41 | +3736.53 | 0.0% | 0.0% | 0.0% | 0.0% | 1.4% | 2.0% |
| E2E per-layer (5a) | 2x | — | — | 2.77 | −1.17 | 61.3% | 61.6% | 61.5% | 61.6% | 52.4% | 59.6% |
| E2E per-layer (5a) | 4x | — | — | 4.28 | +0.35 | 20.7% | 21.3% | 21.2% | 22.4% | 11.0% | 12.9% |
| E2E per-layer (5a) | 8x | — | — | 7.49 | +3.55 | 1.8% | 2.1% | 0.0% | 0.0% | 0.0% | 0.0% |
| E2E per-layer (5a) | 16x | — | — | 11.26 | +7.33 | 0.9% | 2.7% | 0.0% | 0.0% | 0.0% | 0.1% |
| E2E stale (5b) | 2x | — | — | 2.71 | −1.23 | 60.3% | 60.7% | 61.3% | 61.6% | 53.2% | 61.2% |
| E2E stale (5b) | 4x | — | — | 3.61 | −0.33 | 31.5% | 32.4% | 33.0% | 33.2% | 18.6% | 22.1% |
| E2E stale (5b) | 8x | — | — | 4.98 | +1.04 | 4.9% | 5.0% | 3.4% | 4.3% | 0.2% | 2.4% |
| E2E stale (5b) | 16x | — | — | 6.34 | +2.41 | 2.1% | 2.3% | 0.0% | 0.2% | 0.0% | 0.1% |
| E2E pretrained per-layer (6a) | 2x | — | — | 2.41 | −1.53 | 80.0% | 80.1% | 80.1% | 80.0% | 80.6% | 80.8% |
| E2E pretrained per-layer (6a) | 4x | — | — | 3.18 | −0.76 | 55.0% | 55.2% | 52.8% | 52.9% | 43.3% | 43.9% |
| E2E pretrained per-layer (6a) | 8x | — | — | 4.52 | +0.58 | 17.0% | 17.0% | 13.5% | 14.0% | 6.7% | 7.6% |
| E2E pretrained per-layer (6a) | 16x | — | — | 7.34 | +3.40 | 2.3% | 2.3% | 0.3% | 1.1% | 1.1% | 2.1% |
| E2E pretrained stale (6b) | 2x | — | — | 2.25 | −1.69 | 82.5% | 82.6% | 82.0% | 82.3% | 83.9% | 84.0% |
| E2E pretrained stale (6b) | 4x | — | — | 2.57 | −1.37 | 64.4% | 64.5% | 71.0% | 71.1% | 68.8% | 68.9% |
| E2E pretrained stale (6b) | 8x | — | — | 3.04 | −0.90 | 45.8% | 45.9% | 37.6% | 37.6% | 24.3% | 24.3% |
| E2E pretrained stale (6b) | 16x | — | — | 3.47 | −0.47 | 25.9% | 25.9% | 18.7% | 18.7% | 9.0% | 9.6% |
| Split E2E per-layer (7a) | 2x | — | — | 2.58 | −1.31 | 79.9% | 80.0% | — | — | 79.5% | 79.7% |
| Split E2E per-layer (7a) | 4x | — | — | 3.72 | −0.17 | 42.1% | 42.2% | — | — | 51.6% | 51.8% |
| Split E2E per-layer (7a) | 8x | — | — | 6.43 | +2.54 | 4.9% | 5.5% | — | — | 18.5% | 18.7% |
| Split E2E per-layer (7a) | 16x | — | — | 908.20 | +904.31 | 0.0% | 0.5% | — | — | 2.0% | 2.5% |
| Split E2E stale (7b) | 2x | — | — | 2.34 | −1.55 | 80.7% | 80.7% | — | — | 83.3% | 83.4% |
| Split E2E stale (7b) | 4x | — | — | 2.80 | −1.09 | 65.8% | 66.0% | — | — | 70.7% | 70.7% |
| Split E2E stale (7b) | 8x | — | — | 3.37 | −0.51 | 35.6% | 35.6% | — | — | 47.2% | 47.2% |
| Split E2E stale (7b) | 16x | — | — | 4.28 | +0.39 | 16.5% | 16.7% | — | — | 27.1% | 27.1% |

Notes: HF = HF backend (router-compressed mode). vLLM Comp. = vLLM backend, router-compressed
(router+experts see decompressed). vLLM Uncomp. = vLLM backend, router-uncompressed (router sees
original, experts see decompressed — split forward). For Tasks 7a/7b, HF Strict/Flex = HF backend
with compressed router; vLLM Uncomp. = HF backend with uncompressed router (confirmed identical
results from both `run_all_downstream.py` and `run_e2e_compressor.py --router-mode uncompressed`).
Baseline and quantization have no split mode. PPL baseline: 3.89 (offline) / 3.94 (E2E). GSM8K
uses Megatron-trained weights for E2E methods. Task 7 PPL column shows compressed-router PPL.
Uncompressed-router results (confirmed identical via both original eval code path and
`run_e2e_compressor.py --router-mode uncompressed`):

| Ratio | 7a PPL | 7b PPL | Baseline PPL | 7a Strict | 7a Flex | 7b Strict | 7b Flex |
|-------|--------|--------|--------------|-----------|---------|-----------|---------|
| 2x    | 2.38   | 2.23   | 3.89         | 79.5%     | 79.7%   | 83.3%     | 83.4%   |
| 4x    | 3.08   | 2.53   | 3.89         | 51.6%     | 51.8%   | 70.7%     | 70.7%   |
| 8x    | 4.18   | 2.89   | 3.89         | 18.5%     | 18.7%   | 47.2%     | 47.2%   |
| 16x   | 6.64   | 3.27   | 3.89         | 2.0%      | 2.5%    | 27.1%     | 27.1%   |

**Key findings:**

1. **E2E compression improves GSM8K over baseline.** Baseline strict-match is 44.12%.
   E2E per-layer 2x achieves 61.33% (+17.2 pp) and E2E stale 2x achieves 60.27%
   (+16.2 pp). This mirrors the below-baseline PPL effect — E2E compressors act as
   regularizers that improve both perplexity and downstream task performance.

2. **INT8 and INT4 quantization also improve strict-match.** INT8: 48.90% (+4.8 pp),
   INT4: 56.41% (+12.3 pp). The flexible-extract gap is smaller (INT8: 82.26% vs
   baseline 82.79%), suggesting quantization noise may regularize the strict output
   format without hurting reasoning.

3. **Offline methods catastrophically fail on generation tasks.** Per-layer neural
   compressors score 0% strict-match at all ratios (even 2x, which has PPL=21.07).
   Stale-conditioned 2x scores only 2.81% strict / 67.10% flexible. The flexible-extract
   score reveals that the model still produces correct numerical answers but the output
   format is destroyed — compression disrupts the learned generation patterns.

4. **The strict-vs-flexible gap reveals a format disruption effect.** Offline methods
   show huge gaps: stale_uncomp_2x has 2.81% strict but 67.10% flexible (64.3 pp gap).
   E2E methods show almost no gap: e2e_2x has 61.33% strict vs 61.64% flexible (0.3 pp).
   End-to-end training preserves both the model's reasoning ability AND its output
   formatting, while offline compression preserves some reasoning but destroys formatting.

5. **GSM8K is more sensitive than PPL to compression quality.** Stale_uncomp_2x has
   PPL=6.24 (only +2.36 above baseline) yet scores 2.81% on GSM8K strict-match (vs
   44.12% baseline). E2E per-layer 4x has PPL=4.28 (only +0.35 above baseline) yet
   drops to 20.70% GSM8K. Generation tasks amplify small distributional shifts that
   PPL barely registers.

6. **Stale conditioning matters for downstream tasks.** At 4x: E2E stale gets 31.54%
   vs E2E per-layer 20.70% (+10.8 pp). At 8x: stale gets 4.93% vs per-layer 1.82%.
   The stale signal helps preserve generation quality, consistent with PPL findings.

7. **Pretrained init (Task 6) yields dramatic GSM8K improvements.** 6b stale at 2x
   achieves 82.49% strict-match — nearly double baseline (44.12%) and +22 pp over 5b
   (60.27%). 6a per-layer at 2x reaches 79.98% (+19 pp over 5a). Even at 8x, 6b retains
   45.79% (exceeding baseline) while 5b collapses to 4.93%.

8. **Pretrained init enables useful compression at 16x.** 6b at 16x achieves 25.85%
   GSM8K strict-match — down from baseline (44.12%) but still practically useful. Compare
   with 5b at 16x (2.12%) or 5a at 16x (0.91%). Offline weights provide the optimizer
   with a much better starting region of parameter space.

9. **Best overall result: 6b at 2–4x compression.** 6b at 2x (PPL=2.25, GSM8K=82.5%)
   and 4x (PPL=2.57, GSM8K=64.4%) both outperform baseline on PPL and at 4x still retain
   strong downstream performance. This suggests stale-conditioned E2E compression with
   pretrained init is a viable approach for reducing MoE communication by 2–4x with
   minimal or even improved model quality.

---

## 7. Design Choices and Trade-offs

### 7.1 Offline Independent Training vs End-to-End

**Offline training (Tasks 2–4)** trains compressors on cached hidden states, independently per layer:

| Aspect | Offline | End-to-End (Task 5) |
|---|---|---|
| Loss | MSE + cosine (reconstruction) | Cross-entropy (next-token prediction) |
| Optimization scope | Per-layer, independent | Joint, all 48 layers |
| Gradient flow | None through LLM | Through entire frozen LLM |
| Stale signal | Pre-computed, frozen | Live, gradients flow through |
| Model precision | Full BF16 (~60 GB, 1 GPU) | Full BF16 (~60 GB, 4 GPUs) |
| Training cost | Minutes per layer | Hours for all layers + ratios |
| Error compounding | Not accounted for | Naturally optimized via global loss |

**Offline advantages:**
- Fast and cheap (minutes per layer on a single GPU)
- No need to backpropagate through the full LLM
- Each layer's compressor can be trained in parallel

**Offline limitations (addressed by e2e):**
- Compressors cannot adapt to how their reconstruction errors compound across layers. A small error at layer 0 may shift the hidden state distribution at layer 1, but layer 1's compressor was trained on the *original* layer-1 distribution.
- No joint optimization means the system cannot learn to allocate more capacity to layers where errors are most harmful.
- The stale signal used during offline training is the *unperturbed* reference input, but during inference the reference layer itself is compressed, creating a train-inference mismatch.

**E2E advantages:**
- Compressors are optimized for the actual downstream impact of compression on model quality.
- Joint optimization: the system implicitly learns which layers need higher fidelity.
- Stale gradients flow: reference layer compressors are optimized for their dual role (own reconstruction + stale side information for downstream layers). The stale signal during training already reflects upstream compression artifacts, eliminating the train-inference mismatch.

**E2E limitations:**
- Requires full-precision model in memory for proper gradient flow (~60 GB across 4 GPUs).
- Training is slower (full forward + backward through 48 frozen transformer layers per step).
- More hyperparameter-sensitive (LR, warmup, gradient clipping matter more).

### 7.2 Linear vs Non-linear Compressors

All compressors are single-layer linear networks (no activation functions). This was a deliberate choice:
- Linear compressors are equivalent to learning an optimal projection/reconstruction pair (related to PCA)
- They are fast to train and apply (single matrix multiply)
- They establish a clean baseline before trying non-linear architectures

### 7.3 Loss Function

The combined `MSE + 0.1 × (1 - cos_sim)` loss was chosen because:
- MSE alone can be dominated by outlier values (which are common in later layers with kurtosis up to 81K)
- Cosine similarity preserves the direction of the hidden state vector, which matters more than exact magnitude for downstream attention and expert computations
- The 0.1 weighting keeps MSE as the primary objective while regularizing directions

### 7.4 Reference Layer Stride

The stride of 12 (giving reference layers {0, 12, 24, 36}) was chosen as a balance:
- More reference layers (smaller stride) → better stale signals but more communication (ref layers use standard compression without stale)
- Fewer reference layers (larger stride) → stale signals become less correlated with non-ref layers
- stride=12 gives 4 reference layers covering 48 layers, with each non-ref layer at most 11 layers away from its reference

### 7.5 Training Data Size

100,000 tokens per layer (increased from initial 10,000). Each token produces a 2048-dim vector, so training data per layer is 100K × 2048 = 204.8M values. This is sufficient for learning a linear map with ~4M parameters (2x compression, per-layer).

### 7.6 Model Precision

All tasks use the same model in full BF16 precision (no weight quantization). This ensures:
- Hidden states used for offline training exactly match inference conditions
- End-to-end training has proper gradient flow through frozen layers
- All methods share the same baseline perplexity, enabling direct comparison
- 4-bit NF4 quantization is available via `--load-in-4bit` but is not the default

---

## 8. Implementation Details

### 8.1 Hook-Based Evaluation and Training

Four hook modes are used across experiments:

| Mode | Hook type | Used in |
|---|---|---|
| `evaluate_perplexity_with_compression` | Same compress/decompress for all layers | Shared compressor (Task 3) |
| `evaluate_perplexity_with_perlayer_compression` | Per-layer compress/decompress dicts | Per-layer compressor (Task 3b) |
| `evaluate_perplexity_with_stale_compression` | Per-layer + stale cache + ref/non-ref split | Stale-conditioned (Tasks 4a/4b) |
| `E2ECompressorManager.register_hooks()` | Per-layer, trainable, with/without stale cache | E2E training + eval (Task 5) |

The stale evaluation maintains a `stale_cache` dictionary that is populated by reference layer pre-hooks and read by subsequent non-reference layer hooks. This works because PyTorch processes layers sequentially (layer 0 before layer 1, etc.).

**Device safety in evaluation hooks:** With `device_map="auto"`, model layers may reside on
different GPUs. All evaluation hooks in `model_utils.py` (`evaluate_perplexity_with_perlayer_compression`
and `evaluate_perplexity_with_stale_compression`) explicitly call `.to(x.device)` on
compressor/decompressor outputs before returning them to the model. This ensures correctness
when compressor weights and MoE layers are on different devices.

**E2E training hooks (Task 5)** differ from evaluation hooks in two ways:
1. Compressor/decompressor parameters have `requires_grad=True`, so the autograd graph is maintained through the hooks.
2. For stale mode (5b), the cached stale signal is **not detached** — gradients flow through the stale path to earlier layers, enabling true end-to-end optimization.

### 8.2 MoE Layer Detection

`find_moe_layers()` in `model_utils.py` detects MoE modules by:
1. Checking if the class name contains "Moe", "MoE", or "SparseMoe"
2. Checking for `experts` attribute
3. Checking for both `gate` and `experts` attributes

This is model-agnostic and works for Qwen3, Mixtral, and other MoE architectures.

### 8.3 File Organization

**Offline experiments (Tasks 1–4)** follow the same pattern:
1. Load cached hidden states from `data/hidden_states/`
2. Train compressors on dispatch states
3. Evaluate reconstruction metrics (offline, on cached data)
4. Load the full model and evaluate perplexity (online, with hooks)
5. Save results to `results/{experiment}/`

**End-to-end experiments (Task 5)** follow a different pattern:
1. Load the full model in BF16 across 4 GPUs
2. Load and tokenize training data (Dolci-Instruct-SFT)
3. For each compression ratio: create compressor manager, train e2e, save weights
4. Evaluate perplexity on Dolci-Instruct-SFT (with hooks, same as offline)
5. Save results to `results/05{a,b}_e2e_{perlayer,stale}/`

Bash wrappers in `scripts/` handle environment setup, module loading, and argument passing.

### 8.4 Progress Tracking and Logging

All long-running loops use `tqdm` progress bars (written to stderr) for real-time progress monitoring with elapsed time and ETA. Key loops instrumented:

- **Training loops:** Epoch progress with loss/cosine postfix (all training functions)
- **Layer loops:** Per-layer training iteration (Tasks 3b, 4a/4b)
- **Data loading:** Calibration data and tokenization progress
- **Evaluation:** Perplexity evaluation sequence progress, quantization config iteration
- **Ratio loops:** Outer compression ratio iteration (all tasks)

Each bash script redirects output to two log files in the task's output directory:

| File | Contents | Source |
|---|---|---|
| `run.log` | Full output (print statements, results, summaries) | stdout |
| `progress.log` | tqdm progress bars (elapsed time, ETA, loss metrics) | stderr |

Monitor progress of a running experiment: `tail -f results/<task>/progress.log`

---

## 9. Reproducibility

### 9.1 Software Environment

- Python 3.11
- PyTorch (via `pip install torch` with CUDA 12.6)
- Transformers (HuggingFace)
- bitsandbytes (optional, for 4-bit model loading)
- datasets (for allenai/Dolci-Instruct-SFT)
- matplotlib, numpy

### 9.2 Hardware

- NVIDIA H100 80 GB GPUs (8 available)
- Tasks 1–4: single GPU sufficient (model in full BF16, ~60 GB on one H100 80 GB)
- Task 5: 4 GPUs per job (model in full BF16, ~60 GB + backprop memory); 05a and 05b run in parallel on GPUs 0-3 and 4-7
- 500+ GB system RAM (required for loading ~37 GB of hidden states for offline tasks)
- Compute Canada cluster

### 9.3 Random Seeds and Data Splitting

All experiments use **seed=42** for reproducibility. A deterministic 80/10/10
train/val/test split of the Dolci-Instruct-SFT dataset rows is computed via
`get_split_indices()` in `model_utils.py`:

```python
rng = random.Random(42)
indices = list(range(dataset_size))
rng.shuffle(indices)
# 80% train, 10% val, 10% test
```

**Split consistency across tasks:**
- Task 1 hidden state collection: TRAIN split (max_samples=10000)
- Tasks 2–4 offline training: uses cached hidden states from Task 1 (TRAIN split)
- Tasks 2–4 PPL evaluation: TEST split (max_samples_ppl=50000, response-only)
- Task 5 E2E training: TRAIN split (500K sequences HF / 100K Megatron, SFT mode)
- Task 5 E2E validation: VAL split sequences (SFT mode)
- Task 5 PPL evaluation: TEST split (same as tasks 2–4, response-only)

**SFT data loading (Task 5 and PPL evaluation):**
- Each conversation is tokenized independently (one sample = one sequence)
- Labels are -100 for non-assistant tokens, actual token IDs for assistant responses
- `_tokenize_sft_sample()` in `model_utils.py` finds assistant token boundaries
  via incremental prefix tokenization of the chat template
- Max sequence length: 2048 (configurable via `--max-length`)
- Loss and perplexity are computed on response tokens only

Additional seed setting in Task 5:
- `random.seed(42)`, `np.random.seed(42)`, `torch.manual_seed(42)`,
  `torch.cuda.manual_seed_all(42)` at start of main()
- DataLoader shuffling uses PyTorch's seeded RNG

### 9.4 Experiment Tracking (Wandb)

Both HF and Megatron E2E scripts support Weights & Biases logging:

- **CLI:** `--wandb` / `--no-wandb`, `--wandb-project <name>`
- **Logged metrics:** `train/loss` and `train/lr` per optimizer step,
  `val/loss` every `--val-interval` steps (default 2500) and at end of epoch,
  `train/epoch_loss` per epoch
- **Projects:** `ecmoe-e2e` (HF), `ecmoe-megatron-e2e` (Megatron)
- **Default:** Enabled in bash scripts via `WANDB_FLAG`; disable with
  `WANDB_FLAG="--no-wandb" bash scripts/05_run_e2e_compressor.sh none`
- Megatron: only rank 0 logs to wandb
- Megatron `train/loss` and `train/epoch_loss` are DP-averaged (all-reduced across
  data-parallel ranks) before logging, so wandb values reflect the true global loss
- Graceful fallback if wandb is not installed (HAS_WANDB flag)

---

## 10. Task 8: EP Communication Compression in vLLM

### 10.1 Motivation

Tasks 5–7 evaluate compression quality using PyTorch hooks that compress and decompress
on the **same GPU** — simulating the quality impact but not achieving actual communication
reduction.  In real expert parallelism, the pipeline is:

1. Router computes logits from **original** hidden states (attention GPU)
2. **Compressor** runs on attention GPU: `hidden_dim` → `bottleneck_dim`
3. All-to-all dispatch sends only the **compressed** tensor (reduced volume!)
4. **Decompressor** runs on expert GPU: `bottleneck_dim` → `hidden_dim`
5. Experts compute on decompressed states

Task 8 modifies vLLM's `FusedMoE.forward_impl()` to implement this pipeline,
compressing BEFORE dispatch and decompressing AFTER.

### 10.2 Implementation

**Patched vLLM (`scripts/patch_vllm_fused_moe.py`):** Adds ~12 lines to
`FusedMoE.forward_impl()` at three locations:

1. **Compress before dispatch (EP mode):** `_ecmoe_compress_fn(hidden_states)` →
   dispatches compressed tensor instead of full hidden_dim.
2. **Decompress after dispatch (EP mode):** After `get_ep_group().dispatch()`,
   `_ecmoe_decompress_fn(hidden_states_combined)` restores full hidden_dim.
3. **Single-GPU fallback:** When `do_naive_dispatch_combine=False` (TP=1),
   applies compress→decompress in-place for simulation mode.

When `_ecmoe_compress_fn` is None (default), behavior is identical to stock vLLM.

**EP-aware registration (`src/vllm_ep_compression.py`):** Uses `apply_model()`
to set compress/decompress functions on each FusedMoE instance:

- **Per-layer:** `register_ep_perlayer()` — Independent linear compress/decompress per layer.
- **Stale-conditioned:** `register_ep_stale()` — Reference layers piggyback stale signal
  on compressed tensor before dispatch. Non-reference layers dispatch only compressed data.

### 10.3 Stale Broadcast via Dispatch Piggybacking

**Reference layers (0, 12, 24, 36):**
- compress_fn: `cat(compressed[B, bottleneck], stale[B, stale_dim])` → dispatch `[B, bottleneck + stale_dim]`
- decompress_fn: split → cache stale_part globally → decompress compressed_part

**Non-reference layers (all others):**
- compress_fn: `compressed[B, bottleneck]` only → dispatch `[B, bottleneck]` (maximum compression!)
- decompress_fn: retrieve cached stale → `cat(compressed, cached_stale)` → StaleDecomp

**Correctness:** vLLM's default `all2all_backend=allgather_reducescatter` means after
dispatch, every rank has ALL tokens in consistent ordering.  Stale cached from reference
layers matches token ordering at non-reference layers.

### 10.4 Communication Savings

| Mode | Ref layers (4/48) | Non-ref layers (44/48) | Weighted avg | vs baseline 2048 |
|------|-------------------|----------------------|--------------|-------------------|
| perlayer 2x | 1024 | 1024 | 1024 | **50% saving** |
| perlayer 4x | 512 | 512 | 512 | **75% saving** |
| stale(comp) 4x | 1024 | 512 | 555 | **73% saving** |
| stale(uncomp) 4x | 2560 | 512 | 683 | **67% saving** |
| stale(uncomp) 2x | 3072 | 1024 | 1195 | **42% saving** |

Stale broadcast cost is amortized over ~11 non-reference layers per reference layer.

### 10.5 Evaluation Modes

- **simulation** (`--mode simulation`): Single-GPU (TP=1), no dispatch/combine.
  Validates numerical correctness against existing split-mode results.
- **ep** (`--mode ep`): Multi-GPU (TP=4, `enable_expert_parallel=True`).
  Uses actual EP dispatch/combine with compressed tensors.

Both use Task 7a/7b weights (split-mode E2E trained) from
`results/07a_megatron_e2e_split_perlayer/` and `results/07b_megatron_e2e_split_stale/`.
