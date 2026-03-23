# CLAUDE.md — Rules for AI Assistants (ECMoE Project)

## MANDATORY FIRST STEPS

**Before taking ANY action on a task, you MUST:**

1. Tell the user you have read CLAUDE.md and how you'll follow the THREE RULES
2. **Actually read these files** (not optional):
   - **README.md** — Directory structure, setup, how to run experiments
   - **JOURNAL.md** — Recent bugs, what's broken/fixed, latest results
   - **description.md** — Detailed method descriptions, design choices, hyperparameters

**Do NOT skip this to "get to work faster."** Skipping causes you to use wrong directories, miss known issues, and waste time on already-solved problems.

---

## THE THREE RULES

### 1. EDIT, NEVER REWRITE
- **ALWAYS edit existing code, NEVER rewrite from scratch**
- Find the exact file/function, make surgical changes with Edit tool
- If you're about to write 50+ lines of new code doing something similar to existing code, STOP
- Reuse existing classes: `Compressor`, `Decompressor`, `StaleDecompressor`, `train_compressor`, etc.

### 2. VALIDATE DATA BEFORE PLOTTING
- Always load results from JSON files, never hardcode values
- If a number looks different than expected, investigate before proceeding
- Check `results/summary/all_results_summary.json` for the canonical results

### 3. COMMIT AND DOCUMENT IMMEDIATELY
- `git commit` after every fix (no remote configured — push when available)
- Update `JOURNAL.md` right after committing
- Don't batch changes — commit as you go

---

## MINDSET: NO SHORTCUTS

- Academic rigor means doing things RIGHT, not just doing things FAST
- Be skeptical of your own first approach — question whether it could be better
- Don't simplify the requirement — solve the actual problem

---

## Communication

**When showing results or finishing tasks:**
- ALWAYS provide the **full absolute path** to any files created or modified
- Example: "View the result at: `/project/6004852/lfy/ECMoE/results/summary/ppl_vs_ratio_all.png`"

---

## Project-Specific Rules

### Environment Setup (Compute Canada)

```bash
# Modules MUST be loaded BEFORE activating venv
module load cuda/12.6 arrow/22.0.0
source .venv/bin/activate

# HuggingFace cache goes to persistent project dir (home quota is small)
export HF_HOME=/home/lfy/projects/rrg-bengioy-ad/lfy/ECMoE/.cache/huggingface
```

### Directory Structure

```
src/                        # Python source code
scripts/                    # Bash wrappers for each experiment
results/                    # ALL experiment outputs (gitignored)
  01_distribution/          # Task 1: distribution analysis
  02_quantization/          # Task 2: quantization baseline
  03_neural_compressor/     # Task 3: shared neural compressor
  03b_perlayer_compressor/  # Task 3b: per-layer neural compressor
  04a_stale_compressed/     # Task 4a: stale-conditioned (compressed stale)
  04b_stale_uncompressed/   # Task 4b: stale-conditioned (uncompressed stale)
  05a_e2e_perlayer/         # Task 5a: e2e per-layer compressor (no stale)
  05b_e2e_stale/            # Task 5b: e2e stale-conditioned compressor
  05c_e2e_baseline/         # Task 5c: baseline (no compression, same pipeline)
  05c_megatron_e2e_baseline/ # Task 5c: baseline (Megatron variant)
  06a_megatron_e2e_pretrained_perlayer/ # Task 6a: e2e with 3b init (Megatron)
  06b_megatron_e2e_pretrained_stale/    # Task 6b: e2e with 4b init (Megatron)
  07a_megatron_e2e_split_perlayer/      # Task 7a: split-mode e2e (router=original)
  07b_megatron_e2e_split_stale/         # Task 7b: split-mode e2e + stale
  08_ep_compression/        # Task 8: EP compression eval (uses 7a/7b weights)
  summary/                  # Cross-method comparison plots and tables
data/hidden_states/         # Cached MoE hidden states (gitignored, ~37 GB in bfloat16)
```

### Key Code Architecture

- **`src/model_utils.py`** — Central library: model loading, MoE detection, hidden state
  collection, ALL perplexity evaluation functions (baseline, shared, per-layer, stale)
- **`src/metrics.py`** — Reconstruction metrics: MSE, cosine similarity, relative error, SNR
- **`src/run_neural_compressor.py`** — Defines `Compressor`, `Decompressor`, `train_compressor()`.
  Other scripts import from here — never duplicate these classes
- **`src/run_stale_compressor.py`** — Defines `StaleDecompressor`, `train_stale_compressor()`
- **`src/run_e2e_compressor.py`** — End-to-end training of per-layer compressors via LM loss.
  Defines `E2ECompressorManager`, `SFTDataset`. Uses Dolci-Instruct-SFT with SFT mode
  (response-only training). `_tokenize_sft_sample()` in `model_utils.py` handles the
  response-only label masking.
- **`src/vllm_ep_compression.py`** — EP-aware compress/decompress registration for vLLM.
  Sets `_ecmoe_compress_fn` / `_ecmoe_decompress_fn` on FusedMoE instances via
  `apply_model()`. Supports per-layer and stale-conditioned methods. Requires patched
  vLLM (`.venv_vllm_exp`).
- **`src/run_ep_compression_eval.py`** — Task 8 entry point: evaluates EP compression
  with actual dispatch/combine in vLLM. Two modes: `simulation` (single-GPU) and `ep`
  (multi-GPU with `enable_expert_parallel=True`). Uses Task 7a/7b weights.
- **`src/visualize_all_results.py`** — Generates all cross-method comparison plots and tables
- **`src/downstream_eval.py`** — Shared utility for downstream task evaluation via lm-eval-harness.
  Provides hook registration functions (`register_quantization_hooks`, `register_perlayer_hooks`,
  `register_stale_hooks`, `register_e2e_hooks`), `run_lm_eval()` wrapper, and result saving.
  Imported by each task script when `--downstream-tasks` is specified.
  Also provides vLLM backend support via apply_model pattern: `create_vllm_backend()`,
  `register_perlayer_hooks_vllm()`, `register_stale_hooks_vllm()`,
  `register_quantization_hooks_vllm()`, `remove_hooks_vllm()`.
  Split (router-uncompressed) mode: `register_perlayer_hooks_split()`,
  `register_stale_hooks_split()` for HF, and `register_perlayer_hooks_split_vllm()`,
  `register_stale_hooks_split_vllm()` for vLLM. In split mode, the router sees original
  hidden states while experts see decompressed — more realistic EP simulation.
- **`src/run_all_downstream.py`** — Standalone downstream evaluator. Loads model once,
  evaluates all methods sequentially. Supports `--backend hf/vllm` and
  `--router-mode compressed/uncompressed`.

### Known Issues / Gotchas

**Layer sorting:** Always use `sorted(keys, key=layer_index)` from `model_utils`. Lexicographic
sorting puts layer 10 before layer 2 (`model.layers.10` < `model.layers.2`).

**Dtype mismatch:** Dequantized tensors and neural compressor outputs must match the model's
activation dtype (bfloat16). Always cast: `.to(x.dtype).to(x.device)`.

**What went wrong (2026-02-11):** `absmax_dequantize` returned float32 but model expected
bfloat16, causing `RuntimeError` during perplexity eval. Fix: explicit `.to(scale.dtype)` cast.

**What went wrong (2026-02-11):** When asked to remove quantization for Tasks 1–4, the agent
implemented the change (default `load_in_4bit=False`, `device="auto"`) without the user having
specified this as a hyperparameter. The model loading precision (BF16 vs 4-bit NF4) is a key
experimental parameter — changing it retroactively means old results are no longer reproducible
with default settings. **Lesson:** Treat model loading precision as a hyperparameter. Do NOT
change defaults that affect reproducibility without explicit user instruction. When the user says
"remove quantization", ASK whether they want it as a new default or as a CLI override.

**Response-only hidden state collection:** `collect_hidden_states()` defaults to
`response_only=True` — only assistant-response tokens are captured (labels != -100).
This ensures offline compressor training (Tasks 2–4) trains on the same distribution
that PPL evaluation measures. Use `--no-response-only` in `run_distribution.py` for
legacy all-token collection. Metadata records `"response_only": true/false`.

**Legacy Megatron script deleted:** `src/run_megatron_e2e_compressor.py` was removed because
it used `PackedTokenDataset` + `labels=input_ids` (standard LM, not SFT response-only),
did not use `get_split_indices()`, and misreported effective batch size with DP > 1.
Always use `src/megatron_e2e/train.py` for Megatron-based training.

**Large data files:** Hidden states for 100K tokens are ~18.5 GB per file in bfloat16
(dispatch + gather = ~37 GB). These are gitignored. Never try to `git add` them.

**Model VRAM:** Model is loaded in full BF16 (~60 GB). Tasks 1–4 use single GPU
(`device="cuda:0"`) — the model fits on one H100 80 GB with headroom for inference.
Task 5 uses multi-GPU (`device_map="auto"`) because backprop needs extra VRAM.
4-bit NF4 loading (~15 GB) is available via `--load-in-4bit` but is NOT the default.

**device="auto" vs tensor ops:** When `device="auto"` is used for model loading (Task 5),
`"auto"` is NOT a valid torch device for tensor operations. Scripts that do `.to(device)` or
`train_compressor(device=...)` must use `compute_device` (resolved to `"cuda:0"` when
`device="auto"`). Only `load_model_and_tokenizer()` accepts `"auto"` directly.
Tasks 1–4 default to `device="cuda:0"` so this is only relevant for Task 5.

**Hook device safety (2026-02-17):** With `device_map="auto"`, model layers may reside on
different GPUs. PPL evaluation hooks in `model_utils.py` now explicitly call `.to(x.device)`
on compressor/decompressor outputs before returning them to the model. This is a no-op when
compressor and layer are on the same device but prevents cross-device errors when they differ.

### vLLM Environment (downstream evaluation)

**vLLM backend:** `src/downstream_eval.py` + `src/run_all_downstream.py` — vLLM 0.8.4+
for downstream task evaluation with compression hooks.

```bash
# Separate venv from HF-based experiments — CUDA 12.6
module load cuda/12.6 arrow/22.0.0
source .venv_vllm/bin/activate
export HF_HOME=/home/lfy/projects/rrg-bengioy-ad/lfy/ECMoE/.cache/huggingface

# Setup (first time only):
bash scripts/vllm_setup_env.sh
```

**Known issues / gotchas (vLLM):**
- **vLLM V1 engine (>= 0.15):** The model runs in a **separate subprocess** (EngineCore).
  You CANNOT access the model directly from the main process. The old path
  `llm_engine.model_executor.driver_worker.model_runner.model` does NOT work.
  Instead, use `vllm.LLM.apply_model(func)` to send functions to the worker process.
  Functions are serialized via cloudpickle — they must be self-contained (include their
  own imports and class definitions). Requires `VLLM_ALLOW_INSECURE_SERIALIZATION=1`.
  `create_vllm_backend()` sets this automatically.
- **enforce_eager=True required:** vLLM's CUDA graph capture prevents PyTorch hooks
  from being called. Always use `enforce_eager=True` when registering compression hooks.
  `create_vllm_backend()` sets this automatically.
- **Hook registration pattern:** All vLLM hook functions use the apply_model pattern:
  `_vllm_register_perlayer()` returns a closure → `vllm_llm.apply_model(closure)`.
  The closure runs inside the worker, loads weights, creates compressor modules,
  and registers PyTorch pre-hooks. Cleanup via `_vllm_remove_hooks()` → `remove_hooks_vllm()`.
- **Layer name mapping:** vLLM may use different module paths than HF. `_map_layer_name()`
  maps by numeric layer index, which is robust to naming differences.
- **Two router modes (--router-mode):**
  - `compressed` (default): Pre-hook compress→decompress. Router AND experts see
    decompressed. Conservative lower bound — same as the original PPL evaluation hooks.
  - `uncompressed`: Split forward — router sees ORIGINAL input, experts see decompressed.
    More realistic EP simulation where router runs on source GPU with original data.
    Both modes work for HF and vLLM backends.
- **No multi-device placement:** The plan called for `compressor_device` (attention GPU)
  vs `decompressor_devices` (expert GPUs) to simulate the actual communication topology.
  Current implementation puts both compressor and decompressor on the same device. This
  doesn't affect quality measurement (the math is device-independent) but doesn't
  demonstrate the real communication pattern or measure cross-device overhead.
- **No shared expert handling:** Split mode omits `shared_expert` /
  `shared_expert_gate` logic. Qwen3-30B-A3B doesn't use shared experts so this is
  correct for the current model, but reduces generality.
- **No separate E2E hooks for vLLM:** E2E and offline weights have identical format.
  `register_perlayer_hooks_vllm()` works for 3b + 5a + 6a weights.
  `register_stale_hooks_vllm()` works for 4a/4b + 5b + 6b weights.
- **TP > 1 with vLLM:** When using tensor parallelism, each rank has a partial model.
  Hook registration should still work (hooks are on the full module), but compressor
  modules stay on one device. Tested with TP=1 by default.

**vLLM-specific directories:**
```
.venv_vllm/            # Separate virtual environment (gitignored)
```

### vLLM EP Compression Environment (Task 8)

**EP compression:** `src/vllm_ep_compression.py` — Sets compress/decompress functions
on FusedMoE instances.  Patched `forward_impl()` calls compress BEFORE dispatch and
decompress AFTER, achieving real communication reduction.

```bash
# Separate venv with patched vLLM 0.15.1 — CUDA 12.6
module load cuda/12.6 arrow/22.0.0
source .venv_vllm_exp/bin/activate
export HF_HOME=/home/lfy/projects/rrg-bengioy-ad/lfy/ECMoE/.cache/huggingface

# Setup (first time only):
bash scripts/vllm_exp_setup_env.sh
```

**Key differences from .venv_vllm:**
- vLLM 0.15.1 pinned (for patch compatibility)
- `FusedMoE.forward_impl()` patched with 3 insertion points (~12 lines)
- Uses `_ecmoe_compress_fn` / `_ecmoe_decompress_fn` attributes (not PyTorch hooks)
- Supports `enable_expert_parallel=True` for actual EP dispatch

**Known issues / gotchas (EP compression):**
- **allgather_reducescatter backend:** vLLM's default `all2all_backend`. After dispatch,
  every rank has ALL tokens.  Stale cache approach works because token ordering is
  consistent across layers.
- **Router unaffected:** `router_logits` are computed at `Qwen3MoeSparseMoeBlock.forward()`
  BEFORE `FusedMoE.forward_impl()`, so compression never affects routing decisions.
- **Stale piggybacking:** Reference layers concatenate `cat(compressed, stale)` before
  dispatch. After dispatch, decompress_fn splits and caches stale globally. Non-reference
  layers dispatch only compressed (max compression), retrieve cached stale for decompression.

**vLLM EP compression directories:**
```
.venv_vllm_exp/        # Patched vLLM environment (gitignored)
results/08_ep_compression/ # EP eval results
```

### Megatron-LM Environment (Task 5 Megatron variant)

**Megatron implementation:** `src/megatron_e2e/` package — EP-first, CUDA 12.9, Megatron Bridge.
(Legacy `src/run_megatron_e2e_compressor.py` was deleted due to SFT/split/batch bugs.)

```bash
# Separate venv from HF-based experiments — CUDA 12.9 required
module load cuda/12.9 nccl arrow/22.0.0
source .venv_megatron/bin/activate
export HF_HOME=/home/lfy/projects/rrg-bengioy-ad/lfy/ECMoE/.cache/huggingface

# Setup (first time only):
bash scripts/megatron_setup_env.sh
```

**Key differences from HF environment:**
- Uses `megatron-core` >=0.15.0 for model parallelism (EP, TP, DP, PP)
- Requires Transformer Engine (for Megatron Bridge and fused kernels)
- Uses `megatron-bridge` >=0.2.0 for HF→Megatron weight conversion
- Default parallelism: EP=4, TP=1, PP=1 (expert parallelism, not tensor)
- Launch via `torchrun`, not `python`

**Megatron-specific directories:**
```
src/megatron_e2e/      # Package-based implementation (recommended)
.venv_megatron/        # Separate virtual environment (gitignored)
.uv_cache/             # uv cache on project disk (gitignored)
.uv_pythons/           # uv Python installs (gitignored)
third_party/           # Apex, etc. (gitignored, legacy only)
data/megatron_dolci/   # Preprocessed binary dataset (gitignored)
```

**Known issues / gotchas (Megatron):**
- **CUDA version:** Megatron Bridge requires CUDA >= 12.8. Use `cuda/12.9` module
  on Compute Canada, NOT `cuda/12.6`.
- **EP vs TP:** Default is EP=4 (expert parallelism). With EP, each GPU holds 32/128
  experts per layer. TP=4 is the legacy approach and splits attention heads across GPUs.
- **Megatron layer names** differ from HF: `decoder.layers.N.mlp` vs `model.layers.N.mlp`.
  `_megatron_to_hf_layer_name()` in `compressor_manager.py` handles conversion.
- Compressor weights are replicated across all ranks (not sharded), since they
  are tiny (~200M total). Saved from rank 0 only.
- With EP>1, compressor is on source GPU (attention side), decompressor on
  destination GPU (expert side) — different devices.
- `MegatronModelWrapper` bridges Megatron's forward interface to HF-style
  `SimpleNamespace(loss=..., logits=...)`. Uses `vocab_parallel_cross_entropy`
  for correct loss with TP > 1. SFT labels (-100) are clamped to 0 before
  calling `vocab_parallel_cross_entropy`, and loss is masked via
  `(per_token_loss * loss_mask).sum() / num_valid`.
- DistributedSampler must use DP rank/size (via `get_dp_info()`), NOT global
  world size. All ranks in a TP group must see the SAME data.
- Saved weights use HF layer names (`model.layers.N.mlp`) for compatibility
  with HF `E2ECompressorManager.load_weights()`.
- **Model loading:** `train.py` tries AutoBridge → MegatronBridge → manual fallback
  for HF→Megatron conversion. If Bridge is not installed, falls back to manual
  weight conversion using `load_megatron_qwen3()` from legacy code.
- **Train loss DP reduction (2026-02-17):** `train.py` now all-reduces step-level and
  epoch-level train loss across DP ranks before logging. Previously, only rank 0's local
  shard loss was logged, which was inaccurate with DP > 1. Wandb `train/loss` and
  `train/epoch_loss` now reflect the true DP-averaged loss.

### Running Experiments

Task 1 must run first (caches hidden states for Tasks 2–4). Task 5 is independent.
Tasks 1–4 use 1 GPU each; Task 5a/5b use 4 GPUs each.

**Data selection:** All tasks use seed=42 for reproducible 80/10/10 train/val/test
split of dataset rows. Tasks 1–4 draw from TRAIN split, PPL evaluation from TEST
split. No data leakage between splits.

**Task 5 config (HF):** batch_size=2, grad_accum=8 (effective=16), max_sequences=500K,
max_length=2048, val_interval=2500 steps, val_batch_size=8, SFT mode
(response-only training), wandb enabled by default.

**Task 5/6 config (Megatron):** Same as HF except max_sequences=100K,
val_interval=1000 steps. Task 6 uses same Megatron config with `--init-weights-dir`.

Tail micro-batches (when `len(dataloader) % grad_accum != 0`) are handled by rescaling
accumulated gradients and performing the optimizer step.

**Two evaluation stages:** Training-time val loss uses the VAL split (50K seqs,
batch_size=8, every 2500 steps) for checkpoint selection and wandb monitoring.
Final PPL evaluation uses the TEST split (50K seqs, batch_size=1, in
`model_utils.py`) for reported results. Different code paths — `--val-batch-size`
only affects training-time eval.

**SFT data loading:** All E2E training (Task 5) and perplexity evaluation now use
SFT mode: each sample is one conversation, tokenized independently. Labels are
-100 for non-assistant tokens (system, user, template markup) and actual token
IDs for assistant responses. Loss and perplexity are computed on response tokens
only. Data is loaded by sampling N sequences from the dataset (not packing tokens).
`_tokenize_sft_sample()` in `model_utils.py` handles the tokenization.

```bash
# Phase 1: Megatron 5a + 5b in parallel (8 GPUs)
CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/05_megatron_e2e.sh none &
CUDA_VISIBLE_DEVICES=4,5,6,7 bash scripts/05_megatron_e2e.sh uncompressed &
wait

# Phase 2: Task 1 (re-cache with seed=42)
CUDA_VISIBLE_DEVICES=0 bash scripts/01_analyze_distribution.sh

# Phase 3: Tasks 2-4 + HF 5a (parallel)
CUDA_VISIBLE_DEVICES=0 bash scripts/02_run_quantization.sh &
CUDA_VISIBLE_DEVICES=1 bash scripts/03_run_neural_compressor.sh &
CUDA_VISIBLE_DEVICES=2 bash scripts/03b_run_perlayer_compressor.sh &
CUDA_VISIBLE_DEVICES=3 bash scripts/04_run_stale_compressor.sh compressed &
CUDA_VISIBLE_DEVICES=4,5,6,7 bash scripts/05_run_e2e_compressor.sh none &
wait

# Phase 4: Task 4b + HF 5b (parallel)
CUDA_VISIBLE_DEVICES=0 bash scripts/04_run_stale_compressor.sh uncompressed &
CUDA_VISIBLE_DEVICES=4,5,6,7 bash scripts/05_run_e2e_compressor.sh uncompressed &
wait

# Megatron-based E2E training (alternative to HF Task 5):
CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/05_megatron_e2e.sh none          # 5a
CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/05_megatron_e2e.sh uncompressed   # 5b

# Task 5c: Baseline evaluation (no compression, same pipeline):
CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/05_run_e2e_compressor.sh baseline        # HF
CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/05_megatron_e2e.sh baseline              # Megatron

# Task 6a/6b: E2E with pretrained init (requires Task 3b/4b weights):
CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/06_megatron_e2e_pretrained.sh none &          # 6a (init from 3b)
CUDA_VISIBLE_DEVICES=4,5,6,7 bash scripts/06_megatron_e2e_pretrained.sh uncompressed &  # 6b (init from 4b)
wait

# Task 7a/7b: Split-mode E2E (router sees original, experts see decompressed):
CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/07_megatron_e2e_split.sh none &          # 7a (init from 3b)
CUDA_VISIBLE_DEVICES=4,5,6,7 bash scripts/07_megatron_e2e_split.sh uncompressed &  # 7b (init from 4b)
wait
```

### Downstream Task Evaluation (lm-eval-harness)

Downstream eval is triggered by setting `DOWNSTREAM_TASKS` before running any script.
It runs **after** the existing PPL evaluation step, using `lm-eval-harness` with the
same compression hooks active. Results saved to `downstream_results.json` in each
task's output directory.

```bash
# Run Task 2 + PPL eval + downstream eval:
DOWNSTREAM_TASKS="gsm8k_cot" bash scripts/02_run_quantization.sh

# Run Task 5a + PPL eval + downstream eval:
DOWNSTREAM_TASKS="gsm8k_cot" bash scripts/05_run_e2e_compressor.sh none

# Eval-only mode + downstream:
DOWNSTREAM_TASKS="gsm8k_cot" python src/run_e2e_compressor.py \
    --skip-training --output-dir results/05a_e2e_perlayer --stale-mode none

# Smoke test with 10 examples:
DOWNSTREAM_TASKS="gsm8k_cot" DOWNSTREAM_LIMIT=10 bash scripts/05_run_e2e_compressor.sh none
```

**Key code:** `src/downstream_eval.py` provides `register_*_hooks()` for each method,
`run_lm_eval()` wrapper, and `save_downstream_results()`. Each task script imports from
it when `--downstream-tasks` is specified. GSM8K variant: `gsm8k_cot` (8-shot CoT).

**vLLM backend:** Use `--backend vllm` (or `DOWNSTREAM_BACKEND=vllm`) for vLLM-based
downstream evaluation. Two router modes (`--router-mode compressed/uncompressed`):

```bash
# Standalone vLLM eval (all methods, default router=compressed):
source .venv_vllm/bin/activate
python src/run_all_downstream.py --backend vllm --tasks gsm8k_cot

# Router-uncompressed mode (split: router sees original, experts see decompressed):
python src/run_all_downstream.py --backend vllm --router-mode uncompressed --method e2e_perlayer --tasks gsm8k_cot

# With tensor parallelism:
python src/run_all_downstream.py --backend vllm --tensor-parallel-size 4 --tasks gsm8k_cot

# Via task scripts (HF model, vLLM downstream):
DOWNSTREAM_TASKS="gsm8k_cot" DOWNSTREAM_BACKEND=vllm bash scripts/05_run_e2e_compressor.sh none
```

### Visualization

Regenerate all summary plots and tables:
```bash
source .venv/bin/activate
python src/visualize_all_results.py
```

Outputs to `results/summary/`:
- `ppl_vs_ratio_all.png` — PPL vs compression ratio (log-log)
- `reconstruction_vs_ratio_all.png` — MSE and CosSim vs ratio
- `ppl_bar_practical.png` — Bar chart at 2x and 4x
- `all_results_summary.json` — Machine-readable summary
- `param_count_table.{csv,md,json}` — Parameter counts for all methods

---

## Code Changes

**Before changing any code:**
1. FIND the exact file that produces the current output
2. READ and understand it
3. EDIT only the specific lines needed (use Edit tool)
4. TEST that output matches except for your intended change

**Adding new compression methods:**
- Reuse `Compressor`, `Decompressor` from `run_neural_compressor.py`
- Reuse `train_compressor()` for standard autoencoder training
- Add new perplexity evaluation functions to `model_utils.py`
- Follow the same JSON output format as existing experiments
- Update `visualize_all_results.py` to include the new method

---

## NEVER GUESS SILENTLY

**When you encounter ambiguity:**
1. **STOP** — Do not make an arbitrary choice
2. **ASK** — Present the options to the user
3. **FLAG** — Note the documentation gap
4. **FIX** — Update README.md or CLAUDE.md

---

## Version Control

- Commit after EVERY fix (don't wait)
- Check `git status` and file sizes before committing (no files >100MB)
- Update JOURNAL.md immediately after committing
- No git remote is currently configured — commits are local only

---

## Investigation

**When something seems wrong:**
1. STOP — don't patch the visible symptom
2. ASK WHY — trace back to data generation
3. VERIFY — test hypotheses with minimal examples
4. FIX ROOT — fix the source, not downstream

---

## Meta-Rule: Continuous Improvement

**When a preventable issue occurs:**
1. Identify the root cause
2. Add a "What went wrong" example to this file
3. Commit the improvement

This file should evolve based on lessons learned.
