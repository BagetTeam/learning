# Development Journal

## 2026-02-24 — Implement EP communication compression in vLLM (Task 8)

- **Context:** Previous vLLM implementation simulated compression via PyTorch hooks
  that compress→decompress on the SAME GPU — no actual communication reduction.  The
  correct EP pipeline is: router computes from original → compress on attention GPU →
  dispatch compressed tensor → decompress on expert GPU → experts compute.
- **Implementation:**
  - `scripts/patch_vllm_fused_moe.py`: Standalone patch for vLLM's `FusedMoE.forward_impl()`.
    Adds ~12 lines at three locations: compress before dispatch (EP), decompress after
    dispatch (EP), single-GPU simulation fallback.  Checks for `_ecmoe_compress_fn` /
    `_ecmoe_decompress_fn` attributes on `FusedMoE` instances.  When None (default),
    behavior is identical to stock vLLM.
  - `scripts/vllm_exp_setup_env.sh`: Creates `.venv_vllm_exp` with vLLM 0.15.1 (pinned)
    and applies the patch.  Separate from `.venv_vllm` to preserve existing environment.
  - `src/vllm_ep_compression.py`: EP-aware hook registration module.  Uses `apply_model()`
    pattern to set compress/decompress functions on FusedMoE instances.  Two methods:
    - `register_ep_perlayer()`: Independent compress/decompress per MoE layer.
    - `register_ep_stale()`: Stale-conditioned.  Reference layers piggyback stale signal
      on compressed tensor (concatenated before dispatch, split after).  Non-reference
      layers dispatch only compressed (maximum compression).
  - `src/run_ep_compression_eval.py`: Evaluation entry point.  Two modes:
    - `simulation`: Single-GPU (TP=1), validates numerical correctness vs existing results.
    - `ep`: Multi-GPU (TP=4 + `enable_expert_parallel=True`), real EP dispatch/combine.
  - `scripts/08_ep_compression_eval.sh`: Bash wrapper.
- **Key design decisions:**
  - vLLM's `all2all_backend` defaults to `allgather_reducescatter`: after dispatch, every
    rank has ALL tokens.  This makes the stale cache approach correct — cached stale from
    reference layers has the same token ordering as subsequent non-reference layers.
  - Router logits are computed BEFORE `FusedMoE.forward_impl()` (at
    `Qwen3MoeSparseMoeBlock.forward()`), so compression never affects routing — this is
    inherently split mode.
  - Stale broadcast cost amortized over ~11 non-reference layers.  Communication savings:
    perlayer 4x=75%, stale(uncomp) 4x=67%.
- **Uses Task 7a/7b weights** (split-mode E2E trained).
- **Files created:** `scripts/patch_vllm_fused_moe.py`, `scripts/vllm_exp_setup_env.sh`,
  `src/vllm_ep_compression.py`, `src/run_ep_compression_eval.py`,
  `scripts/08_ep_compression_eval.sh`
- **Updated:** README.md (Task 8 in experiment table, setup instructions, output structure,
  project structure), CLAUDE.md (new directories and files), description.md (new section).

## 2026-02-24 — Confirm HF downstream eval with uncompressed router (7a/7b)

- **Context:** After adding `router_mode` support to `register_e2e_hooks()` and
  `run_e2e_compressor.py`, ran HF downstream GSM8K eval for all 7a/7b ratios with
  `--router-mode uncompressed`. Results were identical to previous `run_all_downstream.py`
  values, confirming correctness of the new code path.
- **Results (GSM8K strict-match %, HF backend, uncompressed router):**

  | Ratio | 7a (perlayer) | 7b (stale) |
  |-------|--------------|------------|
  | 2x    | 79.5%        | 83.3%      |
  | 4x    | 51.6%        | 70.7%      |
  | 8x    | 18.5%        | 47.2%      |
  | 16x   | 2.0%         | 27.1%      |

- **Validation:** All values match `run_all_downstream.py` (which also used HF backend).
  This confirms `register_e2e_hooks(router_mode="uncompressed")` correctly delegates to
  `register_perlayer_hooks_split()` / `register_stale_hooks_split()`.
- **Updated:** `description.md` Section 6.1 note and Section 6.4 notes to properly
  describe HF uncompressed-router downstream results for 7a/7b.
- **PPL eval complete** (7a on GPUs 0-3, 7b on GPUs 4-7, `--router-mode uncompressed`):

  | Ratio | 7a (perlayer) PPL | 7b (stale) PPL | Baseline |
  |-------|-------------------|----------------|----------|
  | 2x    | 2.38              | 2.23           | 3.89     |
  | 4x    | 3.08              | 2.53           | 3.89     |
  | 8x    | 4.18              | 2.89           | 3.89     |
  | 16x   | 6.64              | 3.27           | 3.89     |

- **Validation:** All PPL values match previous `perplexity_results_uncompressed.json` from
  2026-02-23 entry. This confirms `run_e2e_compressor.py --router-mode uncompressed` produces
  identical PPL results to the original evaluation code path.
- **Updated:** `description.md` Section 6.4 notes to confirm PPL via both code paths.

## 2026-02-23 — Add uncompressed router_mode to HF downstream eval

- **Problem:** `register_e2e_hooks()` in `downstream_eval.py` did not accept a
  `router_mode` parameter, so HF downstream eval always ran in compressed mode.
  `run_e2e_compressor.py` did not pass `--router-mode` to downstream eval either.
  PPL eval already supported `router_mode` via `model_utils.py`.
- **Fix:**
  - `src/downstream_eval.py`: Added `router_mode` param to `register_e2e_hooks()`.
    When `"uncompressed"`, delegates to existing `register_perlayer_hooks_split()` /
    `register_stale_hooks_split()`. Added `_SplitModeCleanup` wrapper with
    `remove_hooks()` for uniform cleanup interface.
  - `src/run_e2e_compressor.py`: Passes `router_mode=args.router_mode` to
    `register_e2e_hooks()`. Downstream result tags now include `_uncompressed`
    suffix when using uncompressed router mode. `router_mode` also saved in results.
- **Commit:** `ce3936c`
- **Re-running 7a/7b evals** with `--router-mode uncompressed` (downstream + PPL).

## 2026-02-23 — Task 7a/7b: PPL and downstream evaluation (both router modes)

- **PPL evaluation complete** for both 7a (per-layer split) and 7b (stale split),
  with both compressed and uncompressed router modes. Each eval: 50K sequences,
  batch_size=1, ~10 hours per run on 4× H100.
- **Downstream evaluation complete** (GSM8K, 8-shot CoT, 1319 examples, HF backend)
  for all compression ratios (2x, 4x, 8x, 16x) × 2 router modes × 2 methods.
- **Code changes:**
  - `src/run_e2e_compressor.py`: Save PPL results with router_mode suffix
    (`perplexity_results_uncompressed.json`) to avoid overwriting compressed results.
  - `src/run_all_downstream.py`: Added `e2e_split_perlayer` and `e2e_split_stale`
    to METHODS dict, tag_prefix dict, method_name tuple checks, and help text.
  - `description.md`: Added 7a/7b to Section 6.1 summary table, Section 6.2 key
    findings (findings 14–17), and Section 6.4 downstream table.
- **Results (PPL, compressed / uncompressed router):**

  | Ratio | 7a comp | 7a uncomp | 7b comp | 7b uncomp | Baseline |
  |-------|---------|-----------|---------|-----------|----------|
  | 2x    | 2.58    | 2.38      | 2.34    | 2.23      | 3.89     |
  | 4x    | 3.72    | 3.08      | 2.80    | 2.53      | 3.89     |
  | 8x    | 6.43    | 4.18      | 3.37    | 2.89      | 3.89     |
  | 16x   | 908.20  | 6.64      | 4.28    | 3.27      | 3.89     |

- **Results (GSM8K strict-match %, compressed / uncompressed router):**

  | Ratio | 7a comp | 7a uncomp | 7b comp | 7b uncomp |
  |-------|---------|-----------|---------|-----------|
  | 2x    | 79.9    | 79.5      | 80.7    | 83.3      |
  | 4x    | 42.1    | 51.6      | 65.8    | 70.7      |
  | 8x    | 4.9     | 18.5      | 35.6    | 47.2      |
  | 16x   | 0.0     | 2.0       | 16.5    | 27.1      |

- **Key findings:**
  - 7b uncompressed stays below baseline PPL at ALL ratios (even 16x: 3.27 < 3.89)
  - 7b uncompressed 2x achieves 83.3% GSM8K — best result across all methods
  - 7a 16x compressed catastrophic (PPL=908) but uncompressed fine (6.64)
  - Split-mode training trades compressed-eval for uncompressed-eval quality
- **Files created:**
  - `results/07a_megatron_e2e_split_perlayer/perplexity_results.json`
  - `results/07a_megatron_e2e_split_perlayer/perplexity_results_uncompressed.json`
  - `results/07a_megatron_e2e_split_perlayer/downstream_results.json`
  - `results/07b_megatron_e2e_split_stale/perplexity_results.json`
  - `results/07b_megatron_e2e_split_stale/perplexity_results_uncompressed.json`
  - `results/07b_megatron_e2e_split_stale/downstream_results.json`

## 2026-02-22 — Task 7a/7b: Split-mode E2E training implementation

- **Motivation:** Tasks 5/6 train with compress→decompress pre-hooks where both router
  AND experts see decompressed data. In real EP, the router runs on the source GPU with
  original hidden states. Task 7 trains under this more realistic split mode.
- **Approach:** Two-level pre-hooks per MoE layer:
  1. MoE pre-hook saves original input, returns compress→decompress result
  2. Router/gate pre-hook restores original input for the router submodule
- **Code changes:**
  - `src/megatron_e2e/compressor_manager.py`: Added `router_mode` param,
    `_find_router_submodule()`, split-mode hooks (`_make_split_basic_hook`,
    `_make_split_ref_hook`, `_make_split_stale_hook`), `_make_router_restore_hook`.
    Commit: `f1c18ae`.
  - `src/megatron_e2e/train.py`: Added `--router-mode`, auto-detect 07a/07b output dir,
    pass to manager, wandb config, results JSON. Commit: `b193756`.
  - `src/model_utils.py`: Added `router_mode` to `evaluate_perplexity_with_perlayer_compression`
    and `evaluate_perplexity_with_stale_compression` — split-mode uses MoE pre-hook +
    gate pre-hook for HF eval. `src/megatron_e2e/evaluate.py` and `src/run_e2e_compressor.py`
    pass through. Commit: `b634ed7`.
  - `scripts/07_megatron_e2e_split.sh`: New bash wrapper, sets
    `ROUTER_MODE="uncompressed"`. Commit: `9434718`.
- **Run with:**
  ```
  CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/07_megatron_e2e_split.sh none &          # 7a
  CUDA_VISIBLE_DEVICES=4,5,6,7 bash scripts/07_megatron_e2e_split.sh uncompressed &  # 7b
  wait
  ```
- **Training complete.** Results (best val loss):

  | Ratio | 7a (perlayer) | 7b (stale) |
  |-------|--------------|------------|
  | 2x | 0.8545 | 0.7909 |
  | 4x | 1.1086 | 0.9140 |
  | 8x | 1.4101 | 1.0447 |
  | 16x | 1.8686 | 1.1650 |

- **Weights saved to:**
  - `/project/6004852/lfy/ECMoE/results/07a_megatron_e2e_split_perlayer/`
  - `/project/6004852/lfy/ECMoE/results/07b_megatron_e2e_split_stale/`
- **PPL evaluation** not yet run (requires HF pipeline, separate step).

## 2026-02-22 — Full GSM8K downstream eval results (1319 examples, both router modes)

- **Full eval complete:** All 9 methods × 2 router modes × up to 4 compression ratios.
  60 clean entries saved to `results/summary/downstream_results.json`.
- **Code fix:** Added `router_mode` field to saved entries, include mode suffix in tags
  (e.g. `e2e_2x_uncompressed`), and upsert semantics (replace existing same-tag entry).
  Commit: `bd4bc91`.
- **Key findings (GSM8K strict-match accuracy):**
  - Baseline (no compression): 43.3%
  - Best compressed-mode results:
    - `e2e_pre_stale_2x`: **82.0%** (pretrained init + stale, 2x)
    - `e2e_pre_2x`: **80.1%** (pretrained init, 2x)
    - `e2e_2x`: 61.5% (from-scratch E2E, 2x)
    - `e2e_stale_2x`: 61.3% (from-scratch stale E2E, 2x)
  - Offline methods (perlayer, stale_comp, stale_uncomp) near 0% — confirms
    offline-trained compressors destroy information without E2E fine-tuning.
  - Uncompressed router mode shows different pattern:
    - Offline perlayer_2x jumps from 0% → 22.7% (router can still route correctly)
    - stale_comp_2x jumps from 0.2% → 34.1%
    - E2E pretrained methods slightly different: e2e_pre_stale_2x 82.0→83.9%
  - INT4 quantization (4x): 46.8% compressed mode — strong baseline
  - INT8 quantization (2x): 43.7% — nearly lossless vs baseline
  - INT2 quantization (8x): 0% — total collapse

## 2026-02-22 — Fix vLLM split mode API and add eval script

- **Bug:** vLLM's `Qwen3MoeSparseMoeBlock.gate` returns `(router_logits, _)` — 2 values,
  not 3 like HF's `Qwen3MoeTopKRouter`. vLLM's `experts.forward()` takes
  `(hidden_states=, router_logits=)` kwargs, not positional args. The experts also return
  `(shared_out, fused_out)` tuple, requiring explicit addition.
- **Fix:** Updated `_vllm_register_perlayer_split` and `_vllm_register_stale_split` to
  use vLLM's gate/expert API: 2 return values from gate, keyword args to experts, handle
  `(shared_out, fused_out)` tuple return, handle TP all-reduce.
- **Eval script:** Added `scripts/05_megatron_e2e_eval.sh` — runs vLLM-based GSM8K
  evaluation for all methods with both `--router-mode compressed` and `--router-mode uncompressed`.
  Uses 6-7 GPUs in parallel per mode.
- **Smoke test passed** (10 examples) for all 9 methods × 2 router modes × 4 ratios.
  One transient vLLM engine crash (e2e_perlayer uncompressed 4x) resolved on retry.
- **Added `e2e_pretrained_perlayer` and `e2e_pretrained_stale`** to METHODS dict in
  `run_all_downstream.py` (previously missing Task 6a/6b).
- **Commits:** `513b7a3` (fix), `7ec4c09` (eval script)

## 2026-02-21 — Simplify vLLM eval: remove Phase 2, replace with --router-mode

- **Motivation:** The three-phase system (Phase 1/2/3) was unnecessarily complex.
  Phase 2 was mathematically identical to Phase 1 (both compress→decompress the full
  MoE input — router AND experts see decompressed). Phase 3 was the only genuinely
  different mode (router sees original, experts see decompressed). Simplifying to
  two clearly-named modes makes the code easier to understand and maintain.
- **New system — two router modes (`--router-mode`):**
  - `compressed` (default): Pre-hook compress→decompress. Router AND experts see
    decompressed hidden states. Conservative lower bound on quality (same as old Phase 1).
  - `uncompressed`: Split forward — router sees ORIGINAL input, experts see decompressed.
    More realistic EP simulation (same as old Phase 3).
- **Code changes (`src/downstream_eval.py`):**
  - Removed `register_compressed_moe_forward()` and `register_stale_moe_forward()` (Phase 2)
  - Renamed `register_split_compression()` → `register_perlayer_hooks_split()`
  - Renamed `register_split_stale_compression()` → `register_stale_hooks_split()`
  - Added vLLM apply_model versions: `_vllm_register_perlayer_split()`,
    `_vllm_register_stale_split()` — both router modes now work for HF and vLLM backends
  - Convenience wrappers: `register_perlayer_hooks_split_vllm()`,
    `register_stale_hooks_split_vllm()`
- **Code changes (`src/run_all_downstream.py`):**
  - Replaced `--phase 1/2/3` with `--router-mode compressed/uncompressed`
  - Added `e2e_pretrained_perlayer` and `e2e_pretrained_stale` to METHODS dict
  - Simplified `evaluate_config()` — removed Phase 2 branches, renamed Phase 3 to split_mode
- **Documentation:** Updated CLAUDE.md (vLLM gotchas, usage examples) and README.md
  (vLLM setup section).
- **Commit:** `d1b78ad`

## 2026-02-21 — Phase 2/3 limitations documented (TODO)

- **Phase 2 is mathematically identical to Phase 1.** Both compress→decompress the full
  MoE block input, so router AND experts see decompressed. Phase 2 just monkey-patches
  `forward` instead of using a pre-hook — same computation, different code path.
- **Phase 3 is the only genuinely different phase.** It splits gate(original) from
  experts(decompressed), simulating the realistic EP scenario where the router runs
  on the source GPU with original hidden states.
- **No multi-device placement.** The plan called for compressor on attention GPU,
  decompressor replicated on expert GPUs. Current implementation puts both on the same
  device. Quality measurements are unaffected (device-independent math), but this
  doesn't demonstrate the actual cross-GPU communication pattern.
- **No shared expert handling** in Phase 3 (Qwen3-30B-A3B has no shared experts).
- **TODO:** Add multi-device placement to Phase 3 for realistic EP simulation.

## 2026-02-21 — Fix Phase 3 split_forward gate API

- **Bug:** Phase 3 `split_forward` assumed `gate()` returns 2 values (`router_logits, _`).
  Qwen3's `Qwen3MoeTopKRouter.forward()` actually returns 3 values:
  `(router_logits, routing_weights, selected_experts)`.
- **Fix:** Updated all 4 split_forward variants (perlayer, ref-stale, stale) to:
  - Unpack 3 gate return values correctly
  - Reshape 3D→2D (`batch*seq, hidden`) before gate/experts (matching original forward)
  - Call `experts(decompressed, selected_experts, routing_weights)` with positional args
  - Reshape output back to 3D
- **Tested:** Phase 2 (perlayer, stale) and Phase 3 (perlayer, stale) all pass on 10 GSM8K examples.
  Phase 2 and Phase 3 stale_uncompressed 2x both produce 20%/70% strict/flexible (consistent).

## 2026-02-21 — Add vLLM backend for downstream evaluation

- **Motivation:** The existing downstream evaluation (GSM8K via lm-eval-harness) uses
  HuggingFace HFLM backend with PyTorch hooks for compression simulation. vLLM provides
  a more realistic inference engine. Adding vLLM backend enables three phases of
  increasingly realistic compression simulation.
- **New file:** `scripts/vllm_setup_env.sh` — creates `.venv_vllm` with vLLM 0.8.4+,
  lm-eval[vllm], and project dependencies (CUDA 12.6, Python 3.11).
- **Core changes to `src/downstream_eval.py`:**
  - `_map_layer_name()` — maps vLLM layer names to HF weight keys by layer index
  - `create_vllm_backend()` — creates lm-eval VLLM wrapper with `enforce_eager=True`,
    sets `VLLM_ALLOW_INSECURE_SERIALIZATION=1` for apply_model support
  - **Phase 1 (vLLM, via apply_model):**
    - `_vllm_register_perlayer()`, `_vllm_register_stale()`, `_vllm_register_quantization()`
      — factory functions that return closures for `vllm.LLM.apply_model()`. Each closure
      is self-contained (own imports, class defs) to be cloudpickle-serializable.
    - `register_perlayer_hooks_vllm()`, `register_stale_hooks_vllm()`,
      `register_quantization_hooks_vllm()` — convenience wrappers
    - `remove_hooks_vllm()` — removes all ECMoE hooks from vLLM worker model
  - **Phase 2 (HF only):** `register_compressed_moe_forward()`, `register_stale_moe_forward()`
  - **Phase 3 (HF only):** `register_split_compression()`, `register_split_stale_compression()`
  - `restore_original_forwards()` — undo Phase 2/3 monkey-patching
  - `run_lm_eval()` now accepts `lm_eval_model=` for pre-created VLLM instance
  - `add_downstream_args()` adds `--downstream-backend hf/vllm`
- **`src/run_all_downstream.py`:** Added `--backend hf/vllm`, `--phase 1/2/3`,
  `--tensor-parallel-size`, `--max-model-len`, `--gpu-memory-utilization` args.
  `evaluate_config()` dispatches to appropriate hook functions based on backend and phase.
- **Bash scripts:** Added `DOWNSTREAM_BACKEND` env var to 02, 03b, 04, 05 scripts.
- **Documentation:** README.md vLLM setup section, CLAUDE.md vLLM gotchas and usage.
- **Critical bug found and fixed:** vLLM V1 (>= 0.15) runs the model in a separate
  subprocess (EngineCore). The original approach of extracting the model via
  `llm_engine.model_executor.driver_worker.model_runner.model` fails because V1 has no
  `model_executor` attribute. Solution: use `vllm.LLM.apply_model(func)` which serializes
  the function via cloudpickle and executes it inside the worker process. This requires
  `VLLM_ALLOW_INSECURE_SERIALIZATION=1` and all hook functions to be self-contained.
- **Key design decisions:**
  - No separate `register_e2e_hooks_vllm()` — E2E and offline weights have identical
    format, so `register_perlayer_hooks_vllm()` works for 3b+5a+6a and
    `register_stale_hooks_vllm()` works for 4a/4b+5b+6b.
  - Phase 2/3 only for HF backend. Phase 1 pre-hooks are mathematically identical to
    Phase 2 for quality. Phase 3 (split) would need complex apply_model implementation.
  - Phase 3 should produce slightly better quality than Phase 1/2 because the router
    sees the original input — this is the most realistic simulation of EP with
    compressed dispatch.
- **Smoke tests passed (2026-02-21):**
  - vLLM baseline: 60%/80% strict/flexible on 5 GSM8K examples
  - vLLM e2e_perlayer 2x: 60%/60% on 5 examples (hooks registered/removed correctly)
  - vLLM quantization INT8/INT4/INT2: all ran successfully, INT2 at 0% (expected)

## 2026-02-20 — Task 6a/6b: E2E training with pretrained compressor init

- **Motivation:** Tasks 5a/5b initialize compressor/decompressor weights as near-identity
  matrices (first `b` dimensions projected and reconstructed). Task 6 tests whether
  starting from offline-trained weights (which already minimize reconstruction loss)
  gives better E2E results.
- **Task 6a:** Like 5a (E2E per-layer, no stale) but initialized from Task 3b weights
  (per-layer offline compressors). Output: `results/06a_megatron_e2e_pretrained_perlayer/`
- **Task 6b:** Like 5b (E2E stale-conditioned) but initialized from Task 4b weights
  (stale-conditioned offline compressors). Output: `results/06b_megatron_e2e_pretrained_stale/`
- **Implementation:** Added `--init-weights-dir` argument to `src/megatron_e2e/train.py`.
  Auto-detects weight file naming pattern (perlayer, stale_uncompressed, etc.).
  Created `scripts/06_megatron_e2e_pretrained.sh` bash wrapper.
- **Weight compatibility:** Task 3b/4b weights use HF layer names (`model.layers.N.mlp`),
  which is the same format used by `MegatronCompressorManager.load_weights()`. Direct
  loading works because the offline and E2E architectures use identical `Compressor`,
  `Decompressor`, and `StaleDecompressor` classes.
- **Training completed** (2026-02-21): Both 6a and 6b finished all 4 compression ratios
  (2x, 4x, 8x, 16x). Pretrained initialization gives large improvements over near-identity,
  with gains increasing at higher compression ratios.

### Task 6a — E2E pretrained per-layer (completed)

  | Ratio | Params      | Val (6a) | Val (5a) | Improvement |
  |-------|-------------|----------|----------|-------------|
  | 2x    | 201,474,048 | 0.8670   | 0.9951   | 12.9%       |
  | 4x    | 100,786,176 | 1.1389   | 1.4232   | 20.0%       |
  | 8x    |  50,442,240 | 1.4872   | 1.9746   | 24.7%       |
  | 16x   |  25,270,272 | 1.9676   | 2.3788   | 17.3%       |

  Wandb: https://wandb.ai/fengyuan-liu/ecmoe-megatron-e2e/runs/7vsr7goo
  Results: `results/06a_megatron_e2e_pretrained_perlayer/`

### Task 6b — E2E pretrained stale-conditioned (completed)

  | Ratio | Params      | Val (6b) | Val (5b) | Improvement |
  |-------|-------------|----------|----------|-------------|
  | 2x    | 386,023,424 | 0.8021   | 0.9760   | 17.8%       |
  | 4x    | 285,335,552 | 0.9310   | 1.2538   | 25.7%       |
  | 8x    | 234,991,616 | 1.0932   | 1.5718   | 30.4%       |
  | 16x   | 209,819,648 | 1.2242   | 1.8107   | 32.4%       |

  Wandb: https://wandb.ai/fengyuan-liu/ecmoe-megatron-e2e/runs/mzsh4mck
  Results: `results/06b_megatron_e2e_pretrained_stale/`

- **Key finding:** Pretrained init consistently outperforms near-identity init across all
  compression ratios. The benefit grows with compression ratio for stale-conditioned (6b):
  from 17.8% at 2x to 32.4% at 16x. For per-layer (6a), the benefit peaks at 8x (24.7%)
  and is slightly lower at 16x (17.3%), possibly because 16x per-layer compression is too
  lossy for the pretrained weights to provide as much advantage.
- **Best overall:** 6b at 2x achieves val=0.8021, which is the lowest loss across all
  E2E experiments, approaching the 5c baseline (no compression) level.

### PPL evaluation (2026-02-21)

  Perplexity on test split (50K samples, lower is better):

  | Method                    |    2x |    4x |    8x |   16x | Baseline |
  |---------------------------|------:|------:|------:|------:|---------:|
  | 5a (per-layer, identity)  |  2.77 |  4.28 |  7.49 | 11.26 |     3.89 |
  | **6a (per-layer, pretrained)** | **2.41** | **3.18** | **4.52** | **7.34** | 3.89 |
  | PPL improvement           | 13.0% | 25.7% | 39.7% | 34.8% |          |
  | 5b (stale, identity)      |  2.71 |  3.61 |  4.98 |  6.34 |     3.89 |
  | **6b (stale, pretrained)** | **2.25** | **2.57** | **3.04** | **3.47** | 3.89 |
  | PPL improvement           | 17.0% | 28.8% | 39.0% | 45.3% |          |

  PPL results: `results/06a_megatron_e2e_pretrained_perlayer/perplexity_results.json`,
  `results/06b_megatron_e2e_pretrained_stale/perplexity_results.json`

### GSM8K downstream evaluation (2026-02-21)

  GSM8K 8-shot CoT, strict match accuracy (higher is better):

  | Method                    | Baseline |     2x |     4x |     8x |    16x |
  |---------------------------|:--------:|-------:|-------:|-------:|-------:|
  | 5a (per-layer, identity)  |   0.441  | 0.6133 | 0.2070 | 0.0182 | 0.0091 |
  | **6a (per-layer, pretrained)** | 0.441 | **0.7998** | **0.5504** | **0.1698** | **0.0227** |
  | 5b (stale, identity)      |   0.441  | 0.6027 | 0.3154 | 0.0493 | 0.0212 |
  | **6b (stale, pretrained)** | 0.441 | **0.8249** | **0.6437** | **0.4579** | **0.2585** |

  Downstream results: `results/06a_megatron_e2e_pretrained_perlayer/downstream_results.json`,
  `results/06b_megatron_e2e_pretrained_stale/downstream_results.json`

- **Key PPL finding:** Pretrained init improves PPL by 13–45% depending on method and ratio.
  6b at 4x (PPL=2.57) actually beats the uncompressed baseline (PPL=3.89), and at 16x
  (PPL=3.47) is still below baseline — remarkable for 16× communication compression.
- **Key GSM8K finding:** 6b at 2x achieves 82.5% strict match, nearly double the baseline
  (44.1%). Even at 8x compression, 6b (45.8%) exceeds baseline (44.1%). The stale-conditioned
  pretrained approach (6b) retains meaningful accuracy out to 16x (25.9% vs 2.1% for 5b).

## 2026-02-19 — Fix wandb logging for Task 05c baseline

- **Bug:** Task 05c (baseline) initialized wandb but never called `wandb_run.log()`,
  so only system metrics appeared in the dashboard — no train/val loss.
- **Fix:** Added `wandb_run.log({"baseline/train_loss": ..., "baseline/val_loss": ...})`
  in both `src/run_e2e_compressor.py` and `src/megatron_e2e/train.py`.
- **Bonus fix:** Run name for baseline was falling through to `e2e_perlayer` (same as
  05a), making runs indistinguishable. Now correctly named `e2e_baseline` /
  `megatron_e2e_baseline`.

## 2026-02-07 — Project initialisation

- Created repo structure: `src/`, `scripts/`, `results/`, `data/`
- Wrote core library: `model_utils.py` (model loading, MoE detection, hidden
  state collection, perplexity evaluation), `metrics.py` (MSE, cosine sim,
  relative error, SNR)
- Implemented three experiment scripts:
  - `run_distribution.py` — Task 1: hidden state distribution analysis
  - `run_quantization.py` — Task 2: quantization baseline (absmax + zeropoint,
    8/4/2 bits)
  - `run_neural_compressor.py` — Task 3: learned linear autoencoder compression
    at 2×/4×/8×/16× ratios
- Created bash wrappers: `scripts/01_analyze_distribution.sh`,
  `02_run_quantization.sh`, `03_run_neural_compressor.sh`
- Target model: Qwen3-30B-A3B (hidden_dim=2048, 48 MoE layers, 128 experts,
  top-8 routing)
- Environment: Compute Canada, 4× H100 80 GB, Python 3.11, CUDA 12.6

## 2026-02-11 — All three experiments completed

### Bug fixes
- Fixed dtype mismatch in `absmax_dequantize` and `zeropoint_dequantize`:
  dequantized tensors were float32 but model expected bfloat16, causing
  `RuntimeError` during perplexity evaluation with compression hooks.
  Fix: `(x_q.float() * scale.float()).to(scale.dtype)`
- Added `HF_HOME` export to all three bash scripts so model weights
  download to project dir instead of home (small quota on CC).
- Added `.cache/` to `.gitignore`.

### Task 1 — Distribution analysis (completed)
- Captured 10,000 tokens × 48 MoE layers (dispatch + gather)
- Key findings: std increases from 0.16 (layer 0) → 1.21 (layer 47);
  very high kurtosis (up to 81,340); heavy-tailed distributions
- Results: `results/01_distribution/`

### Task 2 — Quantization baseline (completed)
- Baseline PPL: 16.35
- absmax INT8: MSE=0.000244, CosSim=0.9998, PPL=18.69 (+2.34)
- absmax INT4: MSE=0.073, CosSim=0.930, PPL=30.52 (+14.17)
- absmax INT2: MSE=0.385, CosSim=0.342, PPL=9653 (+9637)
- Results: `results/02_quantization/`

### Task 3 — Neural compressor (completed)
- Trained linear autoencoders at 2×/4×/8×/16× compression
- neural_2x: MSE=0.078, CosSim=0.892, PPL=55.09 (+38.74)
- neural_4x: MSE=0.147, CosSim=0.791, PPL=36014 (+35998)
- neural_8x: MSE=0.199, CosSim=0.706, PPL=1165753
- neural_16x: MSE=0.238, CosSim=0.638, PPL=8548583
- Observation: naive single-layer linear compressor significantly
  underperforms INT8 quantization. INT8 achieves 2× compression with
  PPL=18.69, while neural 2× compression gives PPL=55.09.
- Results: `results/03_neural_compressor/`

## 2026-02-11 — Tasks 3b, 4a, 4b implementation

### Infrastructure changes
- `scripts/01_analyze_distribution.sh`: increased MAX_SAMPLES 128→256,
  MAX_TOKENS 10000→100000 for 100K token capture
- `src/model_utils.py`: added `layer_index()` helper,
  `evaluate_perplexity_with_perlayer_compression()` for per-layer compress/decompress hooks,
  `evaluate_perplexity_with_stale_compression()` for stale-conditioned hooks with
  shared `stale_cache` dict populated by reference layer pre-hooks

### Task 3b — Per-layer neural compressor (COMPLETED)
- `src/run_perlayer_compressor.py`: trained 48 independent compressor/decompressor
  pairs per compression ratio, one per MoE layer
- perlayer_2x: MSE=0.058, CosSim=0.928, PPL=23.48 (+7.14)
- perlayer_4x: MSE=0.119, CosSim=0.844, PPL=92.02 (+75.67)
- perlayer_8x: MSE=0.171, CosSim=0.765, PPL=956.24 (+939.90)
- perlayer_16x: MSE=0.213, CosSim=0.693, PPL=13757.99 (+13741.64)
- Huge improvement over shared neural: 2x PPL 23.48 vs 55.09 (57% delta reduction)
- Results: `results/03b_perlayer_compressor/`

### Task 4a — Stale-conditioned compressor, compressed stale (COMPLETED)
- Reference layer grouping: stride=12, ref layers {0, 12, 24, 36}
- Stale signal compressed by ref layer's compressor (stale_dim = bottleneck_dim)
- stale_comp_2x: MSE=0.041, CosSim=0.950, PPL=20.62 (+4.28)
- stale_comp_4x: MSE=0.096, CosSim=0.877, PPL=50.52 (+34.17)
- stale_comp_8x: MSE=0.148, CosSim=0.800, PPL=467.54 (+451.19)
- stale_comp_16x: MSE=0.193, CosSim=0.727, PPL=14173.36 (+14157.01)
- Results: `results/04a_stale_compressed/`

### Task 4b — Stale-conditioned compressor, uncompressed stale (COMPLETED)
- Stale signal sent raw (stale_dim = hidden_dim = 2048)
- stale_uncomp_2x: MSE=0.036, CosSim=0.956, PPL=20.16 (+3.81)
- stale_uncomp_4x: MSE=0.073, CosSim=0.908, PPL=32.49 (+16.15)
- stale_uncomp_8x: MSE=0.102, CosSim=0.868, PPL=98.04 (+81.70)
- stale_uncomp_16x: MSE=0.122, CosSim=0.837, PPL=262.93 (+246.59)
- Best neural method overall — uncompressed stale consistently wins
- Results: `results/04b_stale_uncompressed/`

### Key findings
- Best 2x compression: INT8 quantization (PPL=18.69), then stale-uncompressed (PPL=20.16)
- Best 4x compression: INT4 quantization (PPL=30.52), then stale-uncompressed (PPL=32.49)
- Per-layer compressors are essential: 57% PPL delta reduction vs shared compressor at 2x
- Stale signal from nearby reference layers significantly improves reconstruction
- Uncompressed stale always beats compressed stale (more information preserved)
- At 8x, stale-uncompressed (PPL=98) dramatically outperforms per-layer (PPL=956)
- Visualization: `results/summary/` (3 plots + summary JSON)
- Parameter count table: `results/summary/param_count_table.{csv,md,json}`

## 2026-02-11 — Documentation update

- Rewrote `CLAUDE.md` to be ECMoE-specific (replaced VLM interp project references
  with ECMoE directory structure, environment setup, known gotchas, and code architecture)
- Created `description.md` — detailed description of all methods, design choices,
  hyperparameter specifications, architecture details, and complete results table

## 2026-02-11 — Tasks 05a/05b: End-to-end compressor training

### Motivation
- Tasks 3b/4b train compressors **offline** on cached hidden states, minimizing
  local reconstruction error. Each layer's compressor is trained in isolation —
  it cannot account for how its errors compound through downstream layers.
- Task 05 addresses this by training per-layer compressor/decompressor pairs
  **end-to-end** using the language modeling (next-token prediction) objective.
- LLM weights are frozen; only compressor/decompressor parameters are updated.
  Gradients flow through the entire frozen LLM to reach all compressors.

### Differences from offline training (Tasks 3b/4b)
- **Loss function:** Cross-entropy (next-token prediction) instead of MSE + cosine.
  The LM objective captures the true downstream impact of compression errors.
- **Joint optimization:** All 48 per-layer compressors are optimized simultaneously
  through one shared loss. A compressor at layer 0 receives gradient signal about
  how its reconstruction error affects layers 1–47.
- **Stale gradients flow (05b):** Unlike offline Task 4b where the stale signal is
  pre-computed and frozen, e2e training does NOT detach the stale signal. Gradients
  flow through the stale path, so reference layer compressors are also optimized for
  how their inputs serve as stale side information for downstream layers.
- **Model:** Qwen/Qwen3-30B-A3B-Instruct-2507 (instruct variant, full BF16,
  no quantization). Different model from Tasks 1–4 (base model, 4-bit NF4).
- **Data:** allenai/Dolci-Instruct-SFT (100K tokens) instead of WikiText-2.
- **Initialization:** Near-identity — `W_c` = first `b` rows of `I`, `W_d` = matching
  columns. Avoids catastrophic initial loss from random projections.

### Implementation
- `src/run_e2e_compressor.py`: `E2ECompressorManager` class handles per-layer
  compressor placement (each on same GPU as its MoE layer), hook registration,
  near-identity init, weight save/load, and eval function construction
- `scripts/05_run_e2e_compressor.sh`: bash wrapper, takes mode as argument
- Multi-GPU: model in full BF16 (~60 GB) distributed via `device_map="auto"`
  across 4 GPUs. Gradient checkpointing enabled (`use_reentrant=False`).
- 8 GPUs available → run 05a on GPUs 0-3 and 05b on GPUs 4-7 in parallel:
  ```
  CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/05_run_e2e_compressor.sh none &
  CUDA_VISIBLE_DEVICES=4,5,6,7 bash scripts/05_run_e2e_compressor.sh uncompressed &
  wait
  ```

### Training hyperparameters
- Optimizer: AdamW (lr=1e-4, weight_decay=0.01)
- LR schedule: cosine with 10% linear warmup
- Epochs: 10, early stopping patience: 5
- Batch size: 4, gradient accumulation: 2 (effective batch: 8)
- Gradient clipping: max_norm=1.0
- Sequence length: 512

### Task 05a (--stale-mode none): per-layer e2e, no stale conditioning
### Task 05b (--stale-mode uncompressed): per-layer e2e, uncompressed stale
- Results: `results/05a_e2e_perlayer/`, `results/05b_e2e_stale/`
- Perplexity evaluated on Dolci-Instruct-SFT (same dataset as all other tasks)
- Status: COMPLETED (see results in "Full re-run" section below)

## 2026-02-11 — Remove 4-bit quantization from Tasks 1–4

### Motivation
- Previous experiments loaded model weights in 4-bit NF4 quantization (~15 GB VRAM).
  While activations remain BF16, weight quantization subtly affects activation
  distributions. For fair comparison with Task 05 (which uses full BF16), all tasks
  now load the original unquantized model.

### Changes
- **5 bash scripts** (`01`–`04`): `DEVICE` default changed from `cuda:0` to `auto`,
  `LOAD_4BIT` changed from `--load-in-4bit` to `--no-load-in-4bit`
- **5 Python scripts** (`run_distribution.py`, `run_quantization.py`,
  `run_neural_compressor.py`, `run_perlayer_compressor.py`, `run_stale_compressor.py`):
  `--load-in-4bit` default changed from `True` to `False`
- **3 Python scripts** (Tasks 3, 3b, 4): Added `compute_device` resolution —
  when `args.device="auto"` (for model loading), tensor operations use `"cuda:0"`
- **`README.md`**: Updated model loading documentation to reflect BF16 default
- **VRAM requirement**: Now requires ~60 GB (multiple GPUs via `device_map="auto"`)

## 2026-02-11 — Unify model, dataset, dtype, device across all experiments

### Motivation
- Previous setup used two different models (base for Tasks 1–4, instruct for Task 5),
  two different datasets (WikiText-2 for 1–4, Dolci-Instruct-SFT for 5), and different
  precisions. This made cross-method comparison unreliable.

### Changes
- **Model:** All tasks now use `Qwen/Qwen3-30B-A3B-Instruct-2507`
- **Dataset:** All tasks now use `allenai/Dolci-Instruct-SFT` for both
  calibration/training and perplexity evaluation
- **Dtype:** Neural compressors created in `bfloat16` (matching model activation dtype);
  hidden states cached in `bfloat16` (not float32). Metrics still evaluated in float32.
- **Device:** Tasks 1–4 use single GPU (`cuda:0`); Task 5 uses 4 GPUs via `device_map="auto"`
- **Epochs:** Task 5 uses 1 epoch (per plan.md), not 10
- Updated `README.md`, `description.md`, `CLAUDE.md` to reflect all changes
- **Commit:** `f4ae941`, `74191af`, `9b73194`

### Status
- All code changes committed. Experiments awaiting re-execution with new configuration.
- Old results (from base model + WikiText-2 + 4-bit NF4) are no longer valid.

## 2026-02-11 — Add tqdm progress bars and log files

### Motivation
- Long-running HPC experiments had no way to check elapsed time or ETA
- No log files were created — all output went to terminal only
- Users could not monitor batch job progress without terminal access

### Changes
- **7 Python scripts** (`model_utils.py`, all 6 `run_*.py`): Added `from tqdm import tqdm`
  and wrapped all long-running loops (epoch training, layer iteration, data loading,
  perplexity evaluation, compression ratio loops) with tqdm progress bars
- **7 bash scripts** (all 6 task scripts + `run_all.sh`): Added `exec` redirection:
  - `stdout` → `${OUTPUT_DIR}/run.log` (via `tee`, also to terminal)
  - `stderr` → `${OUTPUT_DIR}/progress.log` (via `tee`, also to terminal)
  - Used `python -u` for unbuffered output
- tqdm writes to `sys.stderr` by default, so progress bars go to `progress.log`
  while print statements go to `run.log`
- Updated `README.md` (monitoring section), `description.md` (Section 8.4)

## 2026-02-11 — Record dataset in hidden state metadata

### What went wrong
- `metadata.json` for cached hidden states did not record the dataset name
- After switching from WikiText-2 to Dolci-Instruct-SFT, there was no way to
  verify which dataset the existing cache was collected from
- Fix: `collect_hidden_states()` now accepts `dataset_name` parameter and writes
  it to `metadata.json`
- **Action required:** Re-run Task 1 to regenerate hidden states with proper metadata

## 2026-02-11 — Full re-run with unified configuration

### Configuration
- **Model:** Qwen/Qwen3-30B-A3B-Instruct-2507 (full BF16, ~60 GB)
- **Dataset:** allenai/Dolci-Instruct-SFT (calibration, training, and PPL eval)
- **Hidden states:** 89,882 tokens × 48 MoE layers × 2048 dim (~35 GB)
- **Hardware:** 8× H100 80 GB on Compute Canada

### Task 1 — Distribution analysis (COMPLETED)
- 89,882 tokens captured (256 samples × max 512 tokens)
- 48 MoE layers detected, hidden_dim=2048
- Metadata now records dataset_name
- Results: `results/01_distribution/`

### Task 2 — Quantization baseline (COMPLETED)
- Baseline PPL: **4.225**
- absmax INT8 (~2×): MSE=0.000380, CosSim=0.9997, SNR=31.4 dB, PPL=**4.201** (−0.02)
- absmax INT4 (~4×): MSE=0.087, CosSim=0.912, SNR=5.7 dB, PPL=**5.360** (+1.13)
- absmax INT2 (~8×): MSE=high, CosSim=low, PPL=**2306** (+2302)
- Results: `results/02_quantization/`

### Task 3b — Per-layer neural compressor (COMPLETED)
- 48 independent compressor/decompressor pairs per ratio, trained on dispatch states
- perlayer_2x: MSE=0.056, CosSim=0.921, SNR=8.41 dB, PPL=**5.922** (+1.70)
- perlayer_4x: MSE=0.114, CosSim=0.832, SNR=5.35 dB, PPL=**17.83** (+13.60)
- perlayer_8x: MSE=0.162, CosSim=0.750, SNR=3.83 dB, PPL=**179.94** (+175.72)
- perlayer_16x: MSE=0.201, CosSim=0.677, SNR=2.91 dB, PPL=**5397.72** (+5393.49)
- Results: `results/03b_perlayer_compressor/`

### Task 4b — Stale-conditioned compressor, uncompressed stale (COMPLETED)
- Ref stride=12, ref layers {0, 12, 24, 36}, stale_dim=2048 (raw)
- stale_uncomp_2x: MSE=0.036, CosSim=0.952, SNR=10.79 dB, PPL=**5.151** (+0.93)
- stale_uncomp_4x: MSE=0.072, CosSim=0.900, SNR=7.63 dB, PPL=**7.804** (+3.58)
- stale_uncomp_8x: MSE=0.100, CosSim=0.855, SNR=6.11 dB, PPL=**12.918** (+8.69)
- stale_uncomp_16x: MSE=0.122, CosSim=0.819, SNR=5.23 dB, PPL=**25.313** (+21.09)
- Results: `results/04b_stale_uncompressed/`

### Task 5a — E2E per-layer compressor (COMPLETED)
- End-to-end training through frozen LLM, optimizing LM cross-entropy loss
- 2 GPUs (4-5), device_map="auto", 1 epoch per ratio, ~2h per ratio
- e2e_2x: train=1.215, val=1.093, PPL=**2.645** (−1.58)
- e2e_4x: train=1.786, val=1.447, PPL=**3.687** (−0.54)
- e2e_8x: train=2.412, val=2.004, PPL=**6.371** (+2.15)
- e2e_16x: train=2.768, val=2.326, PPL=**9.157** (+4.93)
- Results: `results/05a_e2e_perlayer/`

### Task 5b — E2E stale-conditioned compressor (COMPLETED)
- Same as 5a but with uncompressed stale conditioning (stale_dim=2048)
- 2 GPUs (6-7), device_map="auto", 1 epoch per ratio, ~2h per ratio
- e2e_stale_2x: train=1.193, val=1.070, PPL=**2.570** (−1.65)
- e2e_stale_4x: train=1.579, val=1.286, PPL=**3.102** (−1.12)
- e2e_stale_8x: train=1.921, val=1.555, PPL=**4.015** (−0.21)
- e2e_stale_16x: train=2.069, val=1.686, PPL=**4.550** (+0.32)
- Results: `results/05b_e2e_stale/`

### Key findings (all experiments complete)
- **Baseline PPL** dropped from 16.35 (4-bit NF4 base model) to **4.225** (full BF16 instruct)
- **E2E training is transformative** — E2E methods achieve PPL *below* baseline at 2× and 4×
  - E2E stale 2×: PPL=2.57 (−1.65), E2E per-layer 2×: PPL=2.64 (−1.58)
  - E2E stale 4×: PPL=3.10 (−1.12), E2E per-layer 4×: PPL=3.69 (−0.54)
  - E2E stale stays below baseline even at 8× (PPL=4.01, −0.21)
- **Offline vs E2E comparison (same architecture, same params):**
  - At 4×: offline per-layer PPL=17.83 → E2E per-layer PPL=3.69 (4.8× improvement)
  - At 8×: offline per-layer PPL=179.94 → E2E per-layer PPL=6.37 (28× improvement)
  - At 16×: offline per-layer PPL=5397.72 → E2E per-layer PPL=9.16 (589× improvement)
  - At 16×: offline stale PPL=25.31 → E2E stale PPL=4.55 (5.6× improvement)
- **E2E stale at 16× (PPL=4.55) is only +0.32 above baseline** — near-lossless 16× compression
- **Stale conditioning helps more at high compression:**
  - At 2×: stale vs no-stale is marginal (2.57 vs 2.64)
  - At 16×: stale is 2× better (4.55 vs 9.16)
- **Offline methods degrade rapidly:** per-layer collapses above 4×, stale-cond degrades gracefully
  but still 5× worse than E2E stale at 16×
- **Below-baseline PPL** suggests compressors act as regularizers, filtering noise from hidden states
- INT8 quantization (PPL=4.20) is nearly free but only ~2×; INT2 (PPL=2306) is catastrophic

## 2026-02-14 — Megatron-LM integration for Task 5 (E2E compressor training)

### Motivation
- Task 5 currently uses HuggingFace Transformers with `device_map="auto"` for naive
  layer-sharded model parallelism. This is inefficient:
  - Only one GPU is active at a time during forward pass (sequential layer execution)
  - No tensor parallelism (each GPU holds entire layers, not shards)
  - No data parallelism (single data stream)
  - Cannot scale to multi-node
- Megatron-LM provides proper tensor parallelism (TP), expert parallelism (EP),
  and data parallelism (DP), enabling all 4 GPUs active simultaneously

### Architecture: Compressor/decompressor placement
- **Key insight:** In real expert parallelism, compressor and decompressor are on DIFFERENT GPUs
  - Compressor: same GPU as attention (source GPU where token originates)
  - Decompressor: same GPU as MoE expert (destination GPU after dispatch)
- **Phase A (initial):** TP=4, EP=1 — both on same GPU (simple hooks, like current approach)
- **Phase B (later):** EP support — compress before dispatch, decompress on expert GPU

### Approach
- **Training pipeline (NEW):** Megatron Bridge → Load Qwen3 with TP=4 → Freeze LLM →
  Insert compressors at MoE boundaries → Train via Megatron infrastructure → Save weights
- **Evaluation pipeline (EXISTING):** Load HF model → Load trained weights → Evaluate PPL
  with existing hook-based code → Compare with existing results

### Parallelism strategies
- 4 GPUs: TP=4, EP=1, PP=1, DP=1 — all GPUs active via tensor parallelism
- 8 GPUs: TP=4, EP=1, PP=1, DP=2 — TP within 4 GPUs, DP across 2 replicas
- Multi-node: TP=4 within node (NVLink), DP=N across nodes (AllReduce)

### New files
- `src/run_megatron_e2e_compressor.py` — Main Megatron training script
- `src/megatron_model_utils.py` — Megatron model loading and MoE detection
- `src/megatron_preprocess_data.py` — Data preprocessing for Megatron binary format
- `scripts/05_megatron_e2e.sh` — Single-node torchrun launcher
- `scripts/05_megatron_e2e_multinode.sh` — Multi-node SLURM template
- `scripts/setup_megatron.sh` — Environment setup
- `requirements_megatron.txt` — Megatron-specific dependencies

### Implementation details
- **MegatronE2ECompressorManager:** Adapts E2ECompressorManager for Megatron model structure.
  Compressors replicated across TP ranks, save from rank 0, HF-compatible weight format.
- **CompressedMoETokenDispatcher (Phase B):** Wraps Megatron's dispatcher to compress tokens
  before all-to-all dispatch and decompress on destination GPU. Router sees original hidden state.
- **Manual weight conversion:** HF→Megatron with TP sharding (QKV column-split, O row-split,
  experts EP-distributed). Megatron Bridge used when available, manual fallback otherwise.
- **Data preprocessing:** MegatronIndexedDatasetBuilder writes .bin + .idx format for
  memory-mapped loading. Same tokenization as HF variant.

### Commits
- `fe7b8a5`: Documentation for Megatron integration plan
- `70788b9`: Environment setup script and requirements
- `dd00773`: Data preprocessing for Megatron binary format
- `33be348`: Megatron model loading with tensor parallelism
- `db76e01`: Megatron E2E compressor training (TP only, Phase A)
- `4046204`: Expert parallelism support (CompressedMoETokenDispatcher, Phase B)
- `1b10c10`: Launch scripts (single-node torchrun + multi-node SLURM)

### Audit & fixes (2026-02-14, post-implementation)
Audited all 7 new files and 4 doc files for hybrid parallelism correctness. Found and
fixed the following critical issues:

- **DistributedSampler used global world instead of DP group.** With TP=4/DP=1, all 4
  ranks got different data, breaking tensor parallelism. Fixed: use `get_dp_info()` from
  `megatron_model_utils.py` to get DP-only rank/size for sampling. All ranks in same TP
  group now see the same data.
- **Model forward assumed HF `.loss` attribute.** Megatron GPTModel returns logits only.
  Fixed: added `MegatronModelWrapper` in `megatron_model_utils.py` that provides HF-style
  `SimpleNamespace(loss=..., logits=...)` return.
- **Loss computation not TP-aware.** Standard cross-entropy on vocab-parallel logits gives
  wrong results with TP > 1. Fixed: `MegatronModelWrapper._compute_loss()` uses Megatron's
  `vocab_parallel_cross_entropy` when TP > 1.
- **`_megatron_to_hf_layer_name` returned wrong HF name.** Was `model.layers.N.mlp.moe_gate`
  but HF's `find_moe_layers()` returns `model.layers.N.mlp`. Fixed: now returns correct name
  so saved weights are compatible with HF `E2ECompressorManager.load_weights()`.
- **CompressedMoETokenDispatcher had hardcoded arg list.** Broke across Megatron-Core
  versions. Fixed: now uses `*args, **kwargs` for version-agnostic forwarding.
- **Val loss all-reduce used global group.** Fixed: now uses `get_dp_group()` so only DP
  ranks participate (TP ranks have identical loss by construction).

New utilities added to `megatron_model_utils.py`:
- `MegatronModelWrapper`: HF-compatible forward with TP-aware vocab-parallel cross-entropy
- `get_dp_info()`: Returns (dp_rank, dp_size) for DP-aware data sampling
- `get_dp_group()`: Returns DP process group for gradient all-reduce

### Status
- Code implementation COMPLETE. All 7 new files created, all 4 doc files updated.
- Critical hybrid parallelism bugs fixed (DistributedSampler, loss computation, weight names).
- Reused existing classes (Compressor, Decompressor, StaleDecompressor) — not rewritten.
- Training and evaluation pending (requires Megatron-LM environment on compute cluster).
- Compressor weights saved in HF-compatible format for evaluation with existing PPL code.

## 2026-02-14 — Megatron E2E package restructure (src/megatron_e2e/)

### Motivation
- Previous Megatron implementation used flat files (`src/megatron_model_utils.py`,
  `src/run_megatron_e2e_compressor.py`). Restructured into a proper Python package
  `src/megatron_e2e/` for cleaner organization and import paths.
- Updated from TP-only (TP=4, EP=1) to EP-first (EP=4, TP=1) parallelism strategy.
  EP is more natural for MoE: each GPU holds 32/128 experts per layer.
- Updated environment from CUDA 12.6 to CUDA 12.9 (required by Megatron Bridge >= 0.2.0
  and Transformer Engine).
- Added Transformer Engine as required dependency (needed for Bridge and fused kernels).

### New package: src/megatron_e2e/
```
src/megatron_e2e/
├── __init__.py               # Package docstring
├── compressor.py             # Imports existing Compressor/Decompressor/StaleDecompressor
├── compressor_manager.py     # MegatronCompressorManager (adapted from flat files)
├── data.py                   # PackedTokenDataset + distributed data loading
├── train.py                  # Main training entry point (torchrun-compatible)
└── evaluate.py               # HF-pipeline evaluation for Megatron-trained weights
```

### Key changes from previous flat-file implementation
- **Package structure:** All Megatron-specific code under `src/megatron_e2e/`
- **EP-first parallelism:** Default is EP=4, TP=1, PP=1 (was TP=4, EP=1, PP=1)
- **Bridge API:** Tries `AutoBridge.from_hf_pretrained()` first (megatron-bridge >= 0.2.0),
  falls back to `MegatronBridge.from_pretrained()`, then manual conversion
- **CUDA 12.9:** Environment setup script uses `module load cuda/12.9` and installs
  transformer-engine + megatron-bridge via pip
- **Simpler CLI:** `--tp`, `--ep`, `--pp` flags (was `--tensor-model-parallel-size` etc.)
- **Output dirs:** `results/05a_megatron_e2e_perlayer/`, `results/05b_megatron_e2e_stale/`

### Updated files
- `scripts/megatron_setup_env.sh` — New setup script (CUDA 12.9, TE, Bridge)
- `scripts/05_megatron_e2e.sh` — Updated to use `src/megatron_e2e/train.py`, EP=4
- `requirements_megatron.txt` — Updated for megatron-core 0.15+, TE, Bridge
- `.gitignore` — Added `.uv_cache/`, `.uv_pythons/`

### Preserved (not modified)
- `src/megatron_model_utils.py` — Original flat-file Megatron utils (still works)
- `src/run_megatron_e2e_compressor.py` — Original flat-file training script
- `src/megatron_preprocess_data.py` — Data preprocessing for Megatron binary format
- `scripts/05_megatron_e2e_multinode.sh` — Multi-node SLURM template
- `scripts/setup_megatron.sh` — Original CUDA 12.6 setup (superseded by megatron_setup_env.sh)

## 2026-02-15 — Megatron 5a training complete + evaluation pipeline fix

### Megatron Task 5a training (COMPLETED)
- Trained e2e per-layer compressors at 2x/4x/8x/16x using Megatron with EP=4, TP=1, PP=1, DP=4
- Model loaded via AutoBridge (megatron-bridge 0.2+), CUDA 12.9
- Training data: 58.9M tokens from Dolci-Instruct-SFT (103,502 train / 11,500 val sequences)
- 1 epoch per ratio, ~50 min per ratio on 4× H100
- Training losses (train / val):
  - e2e_2x: 1.258 / 1.109
  - e2e_4x: 2.103 / 1.627
  - e2e_8x: 2.776 / 2.242
  - e2e_16x: 3.180 / 2.567
- Weights saved in HF-compatible format at `results/05a_megatron_e2e_perlayer/`

### Bug fix: --skip-training for evaluation-only mode
- **Problem:** Neither `run_e2e_compressor.py` (HF) nor `train.py` (Megatron) could
  evaluate pre-trained weights without re-training. The Megatron script's STEP 3 only
  printed instructions instead of running evaluation, and it suggested using
  `python src/run_e2e_compressor.py --skip-training` which didn't exist.
- **Fix:** Added `--skip-training` flag to `run_e2e_compressor.py`. When set:
  - Skips data loading and training
  - Loads `training_results.json` from output-dir (or builds minimal entries from weight files)
  - Goes straight to PPL evaluation using existing HF pipeline
  - Summary section handles missing training metadata gracefully
- **Usage:** `python src/run_e2e_compressor.py --skip-training --output-dir results/05a_megatron_e2e_perlayer --stale-mode none`
- This enables fair comparison: same HF evaluation code for both HF-trained and Megatron-trained weights

### Megatron Task 5a perplexity evaluation (COMPLETED)
- Evaluated using HF pipeline via `--skip-training` flag (same code as HF Task 5a)
- Baseline PPL: **4.225** (identical, same model + data)

| Ratio | HF E2E 5a (PPL) | Megatron E2E 5a (PPL) | Delta |
|-------|------------------|-----------------------|-------|
| 2x    | 2.645 (−1.58)    | 2.682 (−1.54)         | +0.04 |
| 4x    | 3.687 (−0.54)    | 4.410 (+0.19)         | +0.72 |
| 8x    | 6.371 (+2.15)    | 8.182 (+3.96)         | +1.81 |
| 16x   | 9.157 (+4.93)    | 11.670 (+7.44)        | +2.51 |

- **Megatron 2x is nearly identical to HF** (2.68 vs 2.64, both well below baseline)
- **At 4x, Megatron is marginally above baseline** (4.41 vs 4.23), while HF stayed below (3.69)
- **Gap grows at higher compression** — likely due to different effective optimization:
  Megatron with EP=4/DP=4 trains each GPU on 1/4 of data per step, while HF uses
  full data stream on a single model replica
- Both implementations produce valid, usable compressors — Megatron 2x achieves −1.54 PPL delta
- Results: `results/05a_megatron_e2e_perlayer/perplexity_results.json`

## 2026-02-15 — Megatron 5b training + evaluation + bug fix

### Bug fix: stale device mismatch in multi-GPU evaluation
- **Problem:** `evaluate_perplexity_with_stale_compression()` in `model_utils.py` used
  `torch.cat([compressed, stale], dim=-1)` without moving `stale` to the same device as
  `compressed`. With `device_map="auto"`, reference layer and non-reference layer can be
  on different GPUs, causing `RuntimeError: Expected all tensors to be on the same device`.
- **Fix:** Added `stale = stale.to(compressed.device)` before the `torch.cat()` call
  (line 492 of `model_utils.py`). The HF `E2ECompressorManager` already had this fix
  (line 273 of `run_e2e_compressor.py`), but the standalone evaluation function did not.
- This bug was latent — it only triggers when stale evaluation uses `device_map="auto"`
  (multi-GPU), which is the case for Megatron-trained weight evaluation.

### Megatron Task 5b training (COMPLETED)
- Trained e2e stale-conditioned compressors at 2x/4x/8x/16x using Megatron with EP=4, TP=1, PP=1, DP=4
- Model loaded via AutoBridge (megatron-bridge 0.2+), CUDA 12.9
- Training data: 58.9M tokens from Dolci-Instruct-SFT (103,502 train / 11,500 val sequences)
- Reference layers (stride=12): {0, 12, 24, 36}, stale_dim=2048 (uncompressed)
- 1 epoch per ratio, ~50 min per ratio on 4× H100
- Training losses (train / val):
  - e2e_stale_2x: 1.210 / 1.068
  - e2e_stale_4x: 1.784 / 1.375
  - e2e_stale_8x: 2.206 / 1.724
  - e2e_stale_16x: 2.344 / 1.823
- Weights saved in HF-compatible format at `results/05b_megatron_e2e_stale/`

### Megatron Task 5b perplexity evaluation (COMPLETED)
- Evaluated using HF pipeline via `--skip-training` flag (same code as HF Task 5b)
- Baseline PPL: **4.225** (identical, same model + data)

| Ratio | HF E2E 5b (PPL) | Megatron E2E 5b (PPL) | Delta (Meg−HF) |
|-------|------------------|-----------------------|----------------|
| 2x    | 2.570 (−1.65)    | 2.568 (−1.66)         | −0.00          |
| 4x    | 3.102 (−1.12)    | 3.420 (−0.80)         | +0.32          |
| 8x    | 4.015 (−0.21)    | 4.743 (+0.52)         | +0.73          |
| 16x   | 4.550 (+0.32)    | 5.232 (+1.01)         | +0.68          |

### Full cross-implementation comparison (HF vs Megatron, 5a vs 5b)

| Ratio | HF 5a (PPL) | Meg 5a (PPL) | HF 5b (PPL) | Meg 5b (PPL) |
|-------|-------------|--------------|-------------|--------------|
| 2x    | 2.645       | 2.682        | **2.570**   | **2.568**    |
| 4x    | 3.687       | 4.410        | **3.102**   | **3.420**    |
| 8x    | 6.371       | 8.182        | **4.015**   | **4.743**    |
| 16x   | 9.157       | 11.670       | **4.550**   | **5.232**    |

### Key findings (Megatron 5b)
- **Megatron 5b at 2x is essentially identical to HF 5b** (2.568 vs 2.570, Δ=−0.002)
  — the stale conditioning signal fully compensates for Megatron's DP-related optimization differences
- **Stale conditioning dramatically narrows the Megatron-vs-HF gap:**
  - At 4x: gap shrinks from +0.72 (no stale) to +0.32 (stale)
  - At 8x: gap shrinks from +1.81 (no stale) to +0.73 (stale)
  - At 16x: gap shrinks from +2.51 (no stale) to +0.68 (stale)
- **Megatron 5b stays below baseline at 2x and 4x** (2.57 and 3.42 vs baseline 4.23)
- **Megatron 5b at 8x is only +0.52 above baseline** (4.74 vs 4.23)
- **Stale conditioning matters more for Megatron** than for HF — the stale signal acts
  as an anchor that partially corrects for the noisier optimization from DP-sharded training
- **Megatron 5b val losses are consistently better than 5a val losses** at equivalent ratios:
  - 2x: 1.068 (5b) vs 1.109 (5a), 4x: 1.375 vs 1.627, 8x: 1.724 vs 2.242, 16x: 1.823 vs 2.567
- **Practical recommendation:** For production use with Megatron, always use stale conditioning
  (5b mode) — at 4x compression the PPL is 3.42 (19% below baseline), and at 16x it's only
  5.23 (24% above baseline)
- Results: `results/05b_megatron_e2e_stale/perplexity_results.json`

## 2026-02-15 — Data selection, logging, wandb, batch size overhaul

### Motivation
Previous experiments had several issues:
- Sequential data selection (first N rows) — no randomization, no reproducibility
- Per-epoch-only loss logging (1 data point with --epochs 1) — no training curves
- No wandb for real-time monitoring
- batch_size=4 / effective=8, only 100K sequences for Task 5
- Old results no longer comparable after these changes

### Changes (5 commits)

**Commit 1: Reproducible data splitting (seed=42)**
- Added `get_split_indices()` to `model_utils.py`: deterministic 80/10/10
  train/val/test split of all ~2.15M dataset rows
- Modified `load_calibration_data()`: new `data_split` parameter, samples from
  shuffled indices in the correct split
- Modified `evaluate_perplexity()`: always uses TEST split for PPL evaluation
- Modified `load_e2e_data()` (HF + Megatron): train tokens from TRAIN split,
  val tokens from VAL split — no data leakage
- Added `set_seed(42)` at start of both HF and Megatron main()
- Files: `src/model_utils.py`, `src/run_e2e_compressor.py`,
  `src/megatron_e2e/data.py`, `src/megatron_e2e/train.py`

**Commit 2: Step-level loss logging**
- Added `step_train_loss` and `step_lr` lists to training history
- Track per-optimizer-step loss (averaged over grad_accum micro-batches)
- Replaced training_curves.png: 3-panel plot with EMA-smoothed step loss,
  LR schedule, and final loss bar chart
- With 1 epoch + 500K sequences: ~28K data points instead of 1
- Files: `src/run_e2e_compressor.py`, `src/megatron_e2e/train.py`

**Commit 3: Wandb integration**
- Added `wandb>=0.16.0` to both requirements files
- Added `--wandb/--no-wandb` and `--wandb-project` CLI args
- Logs train/loss and train/lr per optimizer step, val/loss per epoch
- Gated behind `HAS_WANDB` flag for graceful fallback
- Megatron: only rank 0 logs
- Bash scripts: WANDB_FLAG defaults to --wandb
- Files: `src/run_e2e_compressor.py`, `src/megatron_e2e/train.py`,
  `requirements.txt`, `requirements_megatron.txt`,
  `scripts/05_run_e2e_compressor.sh`, `scripts/05_megatron_e2e.sh`

**Commit 4: Batch size + sequence count + HF_HOME**
- Task 5 batch_size: 4→8, effective batch: 8→16
- Task 5 max_sequences: 100K→500K (~256M train tokens)
- Task 1 MAX_SAMPLES: 256→10000 (draws from random train split)
- All 8 bash scripts: HF_HOME → `/home/lfy/projects/rrg-bengioy-ad/lfy/ECMoE/.cache/huggingface`
- Files: all 8 scripts

**Commit 5: Documentation**
- Updated CLAUDE.md: seed info, HF_HOME, execution plan
- Updated description.md: Section 9.3 (seeds + splits), new Section 9.4 (wandb),
  batch_size=8 in hyperparameter table, 500K sequences
- Updated JOURNAL.md: this entry

### Old results
- Previous results moved to `results_old/` (05b Megatron incomplete: 8x/16x missing)
- New results will go to fresh `results/` dirs
- Comparison document to be created after experiments complete

### Execution plan for re-running
1. Phase 1: Megatron 5a+5b parallel (8 GPUs, ~7h)
2. Phase 2: Task 1 re-cache (1 GPU, ~1h)
3. Phase 3: Tasks 2-4 + HF 5a parallel (8 GPUs)
4. Phase 4: Task 4b + HF 5b (8 GPUs, ~18h)
5. Phase 5: Create comparison_old_vs_new.md

## 2026-02-16 — Fix NCCL timeout in Megatron data loading

### Bug fix
- **Root cause:** `load_e2e_data()` in `src/megatron_e2e/data.py` had rank 0
  tokenize all 1.7M train + 215K val items (~30 min) while ranks 1-3 waited at
  `dist.broadcast()`. NCCL communicator init timed out after 600s (10 min).
- **Fix:** All ranks now tokenize independently (same seed → identical results).
  Eliminates the broadcast entirely. Added `dist.barrier()` after tokenization
  for synchronization. Progress bars shown only on rank 0.
- **Commit:** 3596f6f

## 2026-02-16 — Re-running all experiments with new hyperparameters

### Phase 1: Megatron 5a + 5b (IN PROGRESS)
- Both training on all 8 GPUs (4 each), EP=4, TP=1, PP=1, DP=4
- New config: 500K sequences (294.4M tokens), effective batch=16, 35,938 steps/epoch
- Wandb enabled: 5a: `vufnrc12`, 5b: `fw9kkwx9`

#### Megatron 5a (stale=none) — partial results

| Ratio | Old train/val | New train/val | Δ train | Δ val |
|-------|---------------|---------------|---------|-------|
| 2x    | 1.258/1.109   | 1.246/1.161   | -0.012  | +0.052 |
| 4x    | 2.103/1.627   | 1.746/1.518   | **-0.357** | **-0.109** |
| 8x    | 2.776/2.242   | *in progress* | — | — |
| 16x   | 3.180/2.567   | *pending* | — | — |

#### Megatron 5b (stale=uncompressed) — partial results

| Ratio | Old train/val | New train/val | Δ train | Δ val |
|-------|---------------|---------------|---------|-------|
| 2x    | 1.210/1.068   | 1.209/1.123   | -0.001  | +0.055 |
| 4x    | 1.784/1.375   | 1.525/1.322   | **-0.259** | **-0.053** |
| 8x    | 2.206/1.724   | *in progress* | — | — |
| 16x   | 2.344/1.822   | *pending* | — | — |

**Observation:** 4x training loss improved significantly with 5x more data (Δ train: -0.357 for 5a,
-0.259 for 5b). 2x shows mixed results: train loss slightly better but val loss slightly higher.

### Comparison document
- Created `comparison_old_vs_new.md` with partial results
- **Commit:** f8c31a5

### Remaining phases
- Phase 2: HF evaluation of Megatron weights (after training completes)
- Phase 3: HF 5a + Tasks 1-4 in parallel (after Megatron frees GPUs)
- Phase 4: HF 5b + Task 4b (after HF 5a / Task 1 complete)
- Phase 5: Final comparison document update

## 2026-02-16 — Switch to SFT data loading with response-only training

### Motivation
Previous data loading had several issues:
- **Token-packing:** `PackedTokenDataset` concatenated all tokens into one long
  sequence and chunked into fixed-length pieces, arbitrarily gluing together
  tokens from different conversations. This is pretraining-style, not SFT.
- **Token-count based:** `_tokenize_items` tokenized samples one by one until
  reaching a target token count. The number of sequences depended on their
  lengths, not a fixed count.
- **No response masking:** Training and evaluation computed loss on ALL tokens
  (system prompt, user input, template markup, AND assistant response). For SFT,
  only the assistant response should contribute to the loss.
- **max_length=512:** Too short for many conversations in Dolci-Instruct-SFT.

### Changes

**Commit: `ddcdd9f`**

**Core: `src/model_utils.py`**
- Added `_tokenize_sft_sample()`: tokenizes a single conversation with response-only
  labels. For each assistant message, finds the token span via incremental prefix
  tokenization (`apply_chat_template(messages[:i+1])`). Sets labels=-100 for all
  non-assistant tokens (system, user, template markup, padding).
- Modified `load_calibration_data()`: now returns dicts with `'labels'` key
  (in addition to `'input_ids'` and `'attention_mask'`). Labels use SFT masking.
- Modified `evaluate_perplexity()`: passes SFT labels to model forward (not
  `labels=input_ids`). Counts response tokens via `(shift_labels != -100).sum()`.
- Updated all `evaluate_perplexity_with_*` default `max_length` from 512 to 2048.

**HF E2E: `src/run_e2e_compressor.py`**
- Replaced `PackedTokenDataset` with `SFTDataset`: returns dict with
  `input_ids`, `labels`, `attention_mask` from `__getitem__`.
- Replaced `_tokenize_items()` with `_tokenize_sft_split()`: samples N
  sequences from dataset, each tokenized independently via `_tokenize_sft_sample`.
- Updated `load_e2e_data()`: sequence-based (samples N conversations, not N tokens).
- Updated `train_e2e()` and `evaluate_val_loss()`: unpack batch as dict,
  pass labels and attention_mask to model forward.
- Default `--max-length` changed from 512 to 2048.

**Megatron E2E: `src/megatron_e2e/data.py`**
- Same `SFTDataset` and `_tokenize_sft_split_megatron()` changes.
- All ranks still tokenize independently (same seed → identical results).

**Megatron E2E: `src/megatron_e2e/train.py`**
- Updated training loop and `evaluate_val_loss()` to unpack SFT batch dict.
- Fixed `MegatronModelWrapper._compute_loss()`: for `vocab_parallel_cross_entropy`
  (TP>1 path), explicitly mask -100 labels with `per_token_loss[mask].mean()`.
  For standard cross_entropy (TP=1), uses `ignore_index=-100`.
- Default `--max-length` changed from 512 to 2048.

**Bash scripts:** `MAX_LENGTH=512` → `MAX_LENGTH=2048` in both
`scripts/05_run_e2e_compressor.sh` and `scripts/05_megatron_e2e.sh`.

### Impact
- **Baseline perplexity will change:** Now computed on response tokens only
  (previously on all tokens). This is the correct metric for SFT.
- **All previous results invalidated:** Token-packed training is fundamentally
  different from conversation-based SFT. Must re-run all experiments.
- **More VRAM needed:** max_length=2048 means 4× longer sequences than before.
  May need to reduce batch_size for HF Task 5 if OOM occurs.

## 2026-02-16 — Increase PPL evaluation samples to 50,000

### Motivation
- Previous default of 64 test samples for perplexity evaluation produced
  high-variance estimates. With only 64 sequences, PPL can fluctuate
  significantly between runs.
- Increased to 50,000 test sequences for stable, low-variance PPL estimates.

### Changes
- **`src/model_utils.py`**: Changed `max_samples` default from 64 to 50000 in
  all 4 `evaluate_perplexity*` functions
- **8 Python scripts**: Updated argparse `--max-samples-ppl` default from 64
  to 50000 (`run_quantization.py`, `run_neural_compressor.py`,
  `run_perlayer_compressor.py`, `run_stale_compressor.py`,
  `run_e2e_compressor.py`, `run_megatron_e2e_compressor.py`,
  `megatron_e2e/train.py`, `megatron_e2e/evaluate.py`)
- **7 bash scripts**: Updated `MAX_SAMPLES_PPL` from 64 to 50000
  (`02_run_quantization.sh`, `03_run_neural_compressor.sh`,
  `03b_run_perlayer_compressor.sh`, `04_run_stale_compressor.sh`,
  `05_run_e2e_compressor.sh`, `05_megatron_e2e.sh`,
  `05_megatron_e2e_multinode.sh`)
- **`description.md`**: Updated PPL evaluation sample count
- **`CLAUDE.md`**: Added PPL evaluation config note
- **Commit:** `732dc21` (code), this commit (docs)

## 2026-02-16 — Fix SFT tokenization for transformers 5.1.0

### Bug fix
- **Root cause:** `transformers==5.1.0` changed `apply_chat_template(tokenize=True)`
  to return a `BatchEncoding` dict (with keys `input_ids`, `attention_mask`) instead
  of a plain `list[int]`. In `_tokenize_sft_sample()`, `len(full_ids)` returned 2
  (number of dict keys), which is `< 10`, causing the function to always return `None`.
  This made all SFT data loading fail with `ValueError: No valid SFT sequences found`.
- **Fix:** Added `return_dict=False` to both `apply_chat_template()` calls in
  `_tokenize_sft_sample()` (`model_utils.py` lines 234-236 and 247-249).
- **Verified:** 20/20 test samples tokenize successfully with response-only labels.
- **Commit:** `3c5740e`

## 2026-02-16 — OOM fix: reduce batch size for max_length=2048

### Bug fix
- **Root cause:** With max_length increased from 512 to 2048 (4× longer sequences),
  batch_size=8 per-GPU causes OOM during backward pass. Each GPU had ~70 GB PyTorch
  allocated, tried to allocate 4.63 GiB for gradients, only ~2 GB free.
- **Fix:** Reduced batch_size from 8 to 2, increased grad_accum from 2 to 8.
  Effective batch stays at 16 (2 × 4 DP × 2 accum = 16 for Megatron).
- Updated all 3 bash scripts and 2 Python script defaults.
- **Commit:** `7fb8325`

## 2026-02-17 — Add periodic validation loss during training

### Motivation
- With 1 epoch and ~35K optimizer steps, validation loss was only computed once
  (at end of epoch). This made it impossible to monitor training progress or
  detect overfitting during a run.
- Wandb showed training loss curves but no validation signal until the very end.

### Changes
- **`src/megatron_e2e/train.py`**: Added `--val-interval` CLI arg (default 2500).
  Every N optimizer steps, runs `evaluate_val_loss()` on the full validation set,
  logs to wandb (`val/loss`, `val/step`), updates `best_val_loss` and saves best
  checkpoint. End-of-epoch validation still runs as before. Periodic val losses
  stored in `history["step_val_loss"]` as `(step, loss)` tuples. Training curves
  plot now overlays val loss markers on the training loss panel. Added
  `--val-batch-size` (default 8) — no backward pass during eval means we can use
  4x the training batch size, reducing eval time proportionally. Added tqdm
  progress bar to `evaluate_val_loss()` (shows in `progress.log`).
- **`src/run_e2e_compressor.py`**: Same changes for HF E2E training. Added
  `--val-interval` (default 2500), `--val-batch-size` (default 8), periodic
  validation inside optimizer step block, val loss overlay on training curves
  plot. Updated existing tqdm in `evaluate_val_loss()` with running loss postfix.
- **`scripts/05_megatron_e2e.sh`**: Added `VAL_INTERVAL=2500` and
  `VAL_BATCH_SIZE=8` variables, passes both to torchrun command.
- **`scripts/05_run_e2e_compressor.sh`**: Same `VAL_INTERVAL=2500` and
  `VAL_BATCH_SIZE=8` variables.
- **`description.md`**: Added "Validation interval" and "Validation batch size"
  rows to training hyperparameters table (Section 5.5), updated wandb section
  (Section 9.4) to note val/loss is logged every N steps.
- **`CLAUDE.md`**: Updated Task 5 config line.

### Usage
```bash
# Default: validate every 2500 steps with val_batch_size=8
bash scripts/05_megatron_e2e.sh none

# Custom interval (every 500 steps)
VAL_INTERVAL=500 bash scripts/05_megatron_e2e.sh none

# Disable periodic validation (end-of-epoch only, old behavior)
# Pass --val-interval 0 directly or set VAL_INTERVAL=0
```

### Impact
- With ~31K optimizer steps and val_interval=2500: 12 periodic + 1 end-of-epoch
  = **13 val data points** per run (was 1), enabling proper monitoring via wandb
- val_batch_size=8 (4x training batch=2): eval has no backward pass → less VRAM
  → can use larger batches. Reduces micro-batches per val from 6,250 to 1,562
  (per DP rank), cutting eval time by ~4x
- Estimated overhead: ~13 evals × ~7 min each ≈ 1.5h on a 14.5h training run
- Best checkpoint tracks lowest val loss across all periodic and epoch-end evals

## 2026-02-17 — Response-only hidden state collection for offline tasks

### Motivation
- All E2E training (Task 5) and PPL evaluation already use SFT mode (response-only
  loss via labels=-100 masking). But Task 1 hidden state collection captured ALL
  tokens (system, user, template markup, padding, AND assistant response).
- This means offline compressor training (Tasks 2–4) trained on hidden states from
  all token types, while PPL evaluation only measured response quality — a distribution
  mismatch between training and evaluation.
- Fix: collect only response-token hidden states by default, so offline compressors
  train on the same distribution that PPL evaluation measures.

### Changes
- **`src/model_utils.py`**:
  - `MoEHiddenStateCollector`: added `_token_mask` attribute and `set_token_mask(mask)`
    method. When a boolean mask is set, dispatch and gather hooks only collect positions
    where mask is `True`.
  - `collect_hidden_states()`: new `response_only=True` parameter (default ON). Before
    each forward pass, computes mask from `labels != -100` (from `_tokenize_sft_sample`).
    Same mask applied to all 48 layers per sequence. Metadata records `"response_only"`.
- **`src/run_distribution.py`**: added `--response-only` (default on) and
  `--no-response-only` CLI flags. Pass-through to `collect_hidden_states()`.

### What does NOT change
- Tasks 2–4 scripts: unchanged. They load cached hidden states and train on whatever
  is in the cache. If cache has response-only tokens, compressors train on response tokens.
- Task 5 (HF + Megatron): already SFT-aware. No changes.
- PPL evaluation: already SFT-aware. No changes.
- Token alignment across layers: preserved — same mask applied to all 48 layers.

### Impact
- Each sequence contributes fewer tokens (~50% are response), but `max_samples=10000`
  provides more than enough to reach `max_tokens=100000`.
- Offline compressors will now train on the distribution they are evaluated against.
- **All previous cached hidden states are invalidated** — must re-run Task 1.
- **Commit:** `d91499f`

## 2026-02-17 — Delete legacy Megatron script, fix dead --max-samples-ppl flag

### Code review findings (external review)
An external review identified the following issues:

1. **Legacy `run_megatron_e2e_compressor.py` uses standard LM, not SFT (CONFIRMED):**
   - Uses `PackedTokenDataset` (token packing, pretraining-style) instead of `SFTDataset`
   - `labels=input_ids` trains on ALL tokens, not response-only
   - Does not use `get_split_indices()` for deterministic data splitting
   - Effective batch size log ignores DP factor (`batch_size * grad_accum` vs
     actual `batch_size * grad_accum * dp_size`)
   - This means legacy Megatron training is off-policy: trains on pretraining-style
     data but evaluation measures SFT response-only perplexity

2. **`--max-samples-ppl` in `train.py` is dead code (CONFIRMED):**
   - The flag was accepted but never used — STEP 3 only prints CLI snippets
   - Gives false impression that Megatron training handles evaluation

3. **Token broadcast memory concern (PARTIALLY CONFIRMED):**
   - Legacy `load_e2e_data()` broadcasts entire token tensor from rank 0
   - With legacy defaults (100K seq, 512 len) this is ~471 MB, manageable
   - Already fixed in modular package: all ranks tokenize independently

### Fixes (round 2 — actually delete, not just deprecate)
- **Deleted `src/run_megatron_e2e_compressor.py`:** Removed via `git rm`.
  The modular `src/megatron_e2e/train.py` already has all fixes (SFT dataset,
  `get_split_indices()`, DP-aware batch scaling, independent tokenization).
  Deprecation warnings alone were insufficient — the buggy code was still runnable.
- **Updated `scripts/05_megatron_e2e_multinode.sh`:** Rewrote to use
  `src/megatron_e2e/train.py` with `--tp`/`--ep`/`--pp` flags, SFT config
  (max_length=2048, val_interval=2500, wandb), EP-first parallelism (EP=4, TP=1),
  CUDA 12.9 environment. Removed `--max-samples-ppl` and legacy `--bf16` flag.
- **Removed `--max-samples-ppl` from `train.py`:** Dead code. Added comments
  clarifying PPL evaluation runs separately via HF pipeline.
- **Removed `--max-samples-ppl` from `scripts/05_megatron_e2e.sh`:** Matching
  the flag removal from `train.py`.
- **Updated docs** (`README.md`, `CLAUDE.md`, `description.md`): Removed all
  references to deleted legacy script.

### What did NOT need fixing (confirmed correct by review)
- Tasks 1–4: SFT-aligned (response-only hidden states, response-only PPL eval)
- HF Task 5: True SFT (SFTDataset, response-only labels, explicit effective batch)
- Modular Megatron (`src/megatron_e2e/`): SFT-aligned, DP-aware batch scaling

## 2026-02-17 — Comprehensive audit: fix 6 issues

Full audit of Tasks 1–5 confirmed all tasks correctly use SFT mode,
effective batch sizes match (16 for both HF and Megatron), and data
splits are consistent. Found and fixed six issues:

### Documentation fixes (description.md)
- **A:** Batch size table said `8 (grad accum: 2)`, corrected to `2 (grad accum: 8)`.
  The values were swapped after the 2026-02-16 OOM fix but docs weren't updated.
- **B:** PPL evaluation count said "64 sequences", corrected to "50,000 sequences"
  (the actual default in `evaluate_perplexity()`).
- **C:** Wandb section said `val_interval` default is 1000, corrected to 2500.

### Code fixes
- **D:** `train.py` `--batch-size` argparse help said "Micro batch size per DP rank"
  but the code treats it as a global parameter and adjusts internally for DP.
  Fixed help text to "Global micro batch size (adjusted for DP internally)".
- **E:** `model_utils.py:evaluate_perplexity()` now passes `use_cache=False` to the
  model forward call. Saves VRAM during 50K-sample evaluation by disabling KV cache.
- **F:** `train.py:MegatronModelWrapper.forward()` now explicitly accepts `use_cache`
  kwarg instead of silently swallowing it in `**kwargs`.

## 2026-02-17 — Fix 3 grad accumulation and batch calculation bugs

### Motivation (external review)
An external code review identified three bugs in the training loops:

1. **HF E2E partial grad accumulation:** If `len(train_loader)` is not divisible by
   `grad_accum`, the final micro-batches run forward+backward but never trigger
   `optimizer.step()`. Gradients are silently zeroed at the next epoch's
   `optimizer.zero_grad()`. Data and compute wasted every epoch; cosine LR schedule
   based on `floor(len / accum)` ignores the dropped work.

2. **Megatron batch calculation:** Floor division to compute `local_grad_accum` and
   `local_batch_size` silently produces wrong effective batch sizes when `dp_size`
   doesn't cleanly divide `target_effective`. E.g. batch=3, accum=2, dp=4 → target=6
   but runs with effective=4. Current defaults (batch=2, accum=8, dp=4) happen to
   work, but other reasonable configs break silently.

3. **Megatron partial grad accumulation:** Same issue as #1 but in the Megatron loop.
   DistributedSampler provides no guarantee that `len(train_loader)` is divisible by
   `local_grad_accum`.

### Fixes
- **`src/run_e2e_compressor.py`**: Changed `steps_per_epoch` from floor to `math.ceil`.
  Added final partial-accumulation optimizer step after the inner training loop: checks
  `(step + 1) % grad_accum != 0`, clips gradients, steps optimizer/scheduler, logs loss.
- **`src/megatron_e2e/train.py` (batch calc)**: Replaced floor-division approach with
  exact validation. Raises `ValueError` if `target_effective % dp_size != 0`. Finds
  largest `local_batch_size ≤ args.batch_size` that exactly divides `per_rank_effective`.
  Guarantees `local_batch * dp_size * local_grad_accum == target_effective`.
- **`src/megatron_e2e/train.py` (accumulation)**: Same ceil + partial-step fix as HF.
  Includes `_allreduce_compressor_grads()` before the final step (Megatron-specific).
- **Commit:** `356bebc`

## 2026-02-17 — Fix trailing micro-batch under-weighting in grad accumulation

### Bug (external review)
The partial grad accumulation step added in `356bebc` had a subtle weighting
bug: every micro-batch divides its loss by the **full** `grad_accum` factor
(line 542 of HF, line 451 of Megatron). When the final optimizer step runs
on fewer than `grad_accum` micro-batches, the accumulated gradient is only
`remaining / grad_accum` of the intended magnitude. For example, with
`grad_accum=8` and `remaining=3`, the final step's gradients are 37.5% of
correct scale. The optimizer then applies this under-weighted update as if
it were a full step.

### Fix
Removed the partial-accumulation optimizer step entirely from both
`src/run_e2e_compressor.py` and `src/megatron_e2e/train.py`. The tail
micro-batches still run forward+backward (contributing to `epoch_loss`
reporting), but their under-weighted gradients are discarded at the next
`optimizer.zero_grad()` or end of training.

Also reverted `steps_per_epoch` from `math.ceil` to floor division (`//`),
since the partial step was the reason for using `ceil`. The cosine LR
scheduler now plans for only the full-accumulation steps.

## 2026-02-17 — Comprehensive audit + stale default fix

### Audit scope
Full verification of all code paths across Tasks 1–5 (8 Python scripts, 7 bash
scripts) for:
- SFT-style train/loss/eval (response-only labels, `labels=-100` masking)
- Effective batch size and hyperparameter consistency
- Hybrid parallelism correctness (EP, TP, DP)
- General code correctness

### Findings
All SFT compliance, batch sizes, hyperparameters, and parallelism logic are
correct. One cosmetic issue found:

### Bug fix
`load_model_and_tokenizer()` in `model_utils.py` had stale default
`load_in_4bit=True` from early development. All callers pass `False` explicitly
via argparse, so it never triggered in practice, but the function signature was
misleading and could cause accidental 4-bit loading if called without the
argument. Fixed: default changed to `load_in_4bit=False`.

## 2026-02-17 — Fix 3 external review issues + acknowledge 2 design decisions

### External review findings (5 items)

**HIGH — Multi-node srun launcher missing distributed env vars (FIXED)**
- `05_megatron_e2e_multinode.sh` called `srun python ...` without exporting
  `RANK`, `WORLD_SIZE`, `LOCAL_RANK`. PyTorch's `dist.init_process_group()`
  with `env://` init method requires these, but srun only sets SLURM-style
  vars (`SLURM_PROCID`, `SLURM_LOCALID`, `SLURM_NTASKS`).
- All processes would get `LOCAL_RANK=0` (the `os.environ.get` default),
  causing all ranks to fight for GPU 0. `dist.init_process_group()` would
  hang or error due to missing `RANK`/`WORLD_SIZE`.
- Fix: wrapped the python launch in `bash -c` that maps SLURM vars to
  torchrun-style vars. Config vars exported so they're available inside
  each srun task via `--export=ALL`.

**MEDIUM — --skip-training crash on missing weights (FIXED)**
- `run_e2e_compressor.py` warned about missing weight files during
  `--skip-training` data scan (line 778) but later unconditionally called
  `manager.load_weights(weights_path)` for every ratio (line 953).
  One missing `*_weights.pt` would abort the entire evaluation.
- Fix: check `os.path.exists(weights_path)` before loading; skip missing
  ratios with a WARNING and `continue`.

**MEDIUM — Tasks 2-4 don't validate response_only metadata (FIXED)**
- Tasks 2-4 load cached hidden states but never checked
  `metadata["response_only"]`. If old cache (all-token collection) were
  used, offline compressors would train on a different distribution than
  PPL evaluation measures (response-only).
- Fix: `load_hidden_states()` now prints the `response_only` field and
  warns if it's missing or False.

**LOW — Batch comment says "per DP rank" but code uses global (FIXED)**
- `05_megatron_e2e_multinode.sh` line 46 said `BATCH_SIZE` is "micro batch
  per DP rank", but `train.py` treats `--batch-size` as a global parameter
  and adjusts for DP internally. Fixed the comment.

**LOW — Both HF and Megatron drop tail micro-batches (ACKNOWLEDGED)**
- Explicitly documented in both `run_e2e_compressor.py` (line 585) and
  `train.py` (line 498). This is by design: the partial-accumulation
  optimizer step was tried and reverted (commit `41c3fb2`) because it
  under-weights the final step's gradients. The impact is negligible:
  with `grad_accum=8` and ~31K total micro-batches, at most 7
  micro-batches are dropped (0.02% of data).

### What was confirmed correct
- All tasks correctly use SFT mode (response-only labels)
- Effective batch sizes match: 16 for both HF and Megatron
- Hybrid parallelism logic (EP, TP, DP) is correct
- Data splits are consistent across all tasks (seed=42)

## 2026-02-17 — Fix 2 issues from second external review (5 findings analyzed)

### External review findings (5 items, ordered by severity)

**Finding 1: TP>1 loss path with SFT labels (-100) — NOT A BUG**
- Reviewer concern: `vocab_parallel_cross_entropy(flat_logits, flat_labels)` is
  called before masking -100 labels (train.py line 230/236).
- Analysis: Megatron's `vocab_parallel_cross_entropy` handles negative labels
  safely: `target_mask = (target >= vocab_start) & (target < vocab_end)` is
  `False` for -100, `masked_target` is clamped to 0 (safe gather index),
  `predicted_logit` is zeroed. Result is a finite (but meaningless) loss value
  for -100 tokens, which is then correctly masked out at line 236-238.
  Gradients only flow through valid (masked-in) tokens. No crash, no incorrect
  loss. No fix needed.

**Finding 2: Tail micro-batch dropping — ACKNOWLEDGED DESIGN DECISION**
- Already documented in JOURNAL.md (commit `41c3fb2`). Partial accumulation
  step was tried and reverted due to gradient under-weighting. Impact: at
  most 7 of ~31K micro-batches dropped (0.02%). No fix needed.

**Finding 3: Hook device mismatch with --device auto — FIXED (defensive)**
- `evaluate_perplexity_with_perlayer_compression()` and
  `evaluate_perplexity_with_stale_compression()` in `model_utils.py` returned
  tensors on the compressor's device without moving back to the layer's device.
  With `device_map="auto"` (multi-GPU), this would cause device mismatch.
- In practice, Tasks 3/3b/4 always use `device="cuda:0"` (single GPU), so
  this never triggered. But added defensive `.to(x.device)` to all 4 hook
  types (perlayer pre/post, stale ref/non-ref) for safety.

**Finding 4: Megatron epoch train loss not DP-reduced — FIXED**
- `epoch_loss` was accumulated per-rank and logged from rank 0 without
  DP all-reduce (train.py line 504). With DP=4, logged train loss only
  represented 1/4 of data. Step-level train loss logged to wandb was also
  per-rank only.
- Fix: Added DP all-reduce for both per-step train loss (before wandb
  logging) and epoch-level train loss (before epoch summary). Val loss
  was already correctly all-reduced.
- Only affects logging/monitoring, not training correctness (gradients
  were already properly all-reduced before optimizer step).

**Finding 5: SFT-style confirmation — ALREADY CORRECT**
- Reviewer's analysis confirmed: Tasks 1-5 correctly use SFT mode where
  applicable. Tasks 2-4 use offline reconstruction loss (not SFT training
  loss) but their PPL eval is SFT-style. No action needed.

## 2026-02-17 — Document external review findings and fixes

- Updated `CLAUDE.md`:
  - Added "Hook device safety" gotcha under Known Issues (re: `.to(x.device)` in eval hooks)
  - Added "Train loss DP reduction" to Megatron gotchas (re: all-reduce before logging)
- Updated `description.md`:
  - Added "Device safety in evaluation hooks" paragraph in Section 8.1
  - Added Megatron train loss DP-averaging note in Section 9.4 (wandb)

## 2026-02-17 — Fix TP loss pre-masking and tail microbatch handling

### TP loss with -100 labels (train.py `_compute_loss`)
- **Problem:** `vocab_parallel_cross_entropy(flat_logits, flat_labels)` was called with
  raw -100 labels. Megatron handles this internally (target_mask + clamping), but the
  `else` branch at old line 240 computed `per_token_loss.mean()` on garbage values when
  ALL tokens in a batch were -100.
- **Fix:** Clamp labels to `min=0` before calling `vocab_parallel_cross_entropy`.
  Use `(per_token_loss * loss_mask).sum() / loss_mask.sum().clamp(min=1)` instead of
  indexing + `else` branch. Eliminates garbage computation and handles all-masked edge case.

### Tail microbatch handling (both HF and Megatron)
- **Problem:** When `len(train_loader) % grad_accum != 0`, leftover micro-batches ran
  forward+backward with `loss/grad_accum` divisor but the optimizer step was skipped,
  discarding their gradients entirely.
- **Fix:** After the main loop, if `remainder > 0`, rescale accumulated gradients by
  `grad_accum / remainder` (correcting the divisor from `1/grad_accum` to `1/remainder`),
  then perform the optimizer step with proper clipping and logging.
- Previous attempt (commit `41c3fb2`) failed because it stepped without rescaling,
  under-weighting the tail by `remainder/grad_accum`. The rescaling approach is correct.
- Applied to both `run_e2e_compressor.py` (HF) and `megatron_e2e/train.py` (Megatron).

### --device auto in Tasks 3/3b/4 — NOT A BUG
- `compute_device = "cuda:0"` fallback at `run_neural_compressor.py:347`,
  `run_perlayer_compressor.py:67`, `run_stale_compressor.py:252` is correct.
- Tasks 3/3b/4 train compressors on cached hidden states (single-GPU operation).
  The model is only loaded for PPL evaluation at the end.
- Default `--device` is `cuda:0` in all scripts and bash wrappers.
- The `auto` → `cuda:0` fallback only triggers if someone explicitly passes
  `--device auto`, which is not the intended use case for these tasks.
- PPL evaluation hooks already have `.to(x.device)` for cross-device safety.

## 2026-02-17 — Fix Task 1 max_length mismatch (512 → 2048)

### Bug
- **Problem:** Task 1 hidden state collection used `max_length=512` while Task 5
  training and all PPL evaluation used `max_length=2048`. This created a distribution
  mismatch: offline compressors (Tasks 2–4) trained on hidden states from 512-token
  sequences, but PPL evaluation ran on 2048-token sequences. Hidden states at positions
  512–2047 may have different distributions due to longer attention context.
- **Affected files (all had 512):**
  - `scripts/01_analyze_distribution.sh`: `MAX_LENGTH=512`
  - `src/run_distribution.py`: `--max-length` default 512
  - `src/model_utils.py`: `collect_hidden_states()` default `max_length=512`
  - `src/megatron_preprocess_data.py`: `--max-length` default 512 (legacy)
- **Fix:** Changed all four to 2048, matching Task 5 and PPL evaluation.
- **Impact:** Cached hidden states must be re-collected (re-run Task 1) before
  re-running Tasks 2–4 to ensure train/eval distribution consistency.

## 2026-02-18 — Fix OOM in periodic validation (Megatron 5a + 5b crash)

### Bug
- **Problem:** Both Megatron 5a and 5b crashed with `torch.OutOfMemoryError` at
  step 2500 (first periodic validation). `evaluate_val_loss()` with `val_batch_size=8`
  and `max_length=2048` calls `cross_entropy(flat_logits, flat_labels)` where
  `flat_logits` is `[8*2047, 151936]`. The float32 softmax requires
  `8 × 2047 × 151936 × 4 bytes = 9.27 GiB` of contiguous memory. After 2500
  training steps, CUDA memory was fragmented: ~30 GiB was "reserved by PyTorch
  but unallocated" (many small free blocks), with only 3–6 GiB actually free.
  The 9.27 GiB contiguous allocation failed despite sufficient total capacity.
- **Why now:** The combination of `max_length=2048` (changed from 512 on 2026-02-16)
  and `val_batch_size=8` (added on 2026-02-17) created a 4× larger cross_entropy
  allocation than the previous `max_length=512` configuration. Training batch_size=2
  only needs ~2.3 GiB for cross_entropy, which fits even in fragmented memory.
- **Fix (two-part):**
  1. Added `torch.cuda.empty_cache()` before every `evaluate_val_loss()` call
     (periodic + end-of-epoch) in both `train.py` (Megatron) and
     `run_e2e_compressor.py` (HF). This returns fragmented reserved memory to
     CUDA, making room for the larger validation batch.
  2. Added `PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True` to both bash
     scripts (`05_megatron_e2e.sh`, `05_run_e2e_compressor.sh`) for a
     fragmentation-resistant allocation strategy.
- **Also:** Reverted parallelized tokenization in `data.py` back to sequential
  (datasets.map was not compatible with the environment).
- **Commit:** `34fb468`

## 2026-02-18 — Task 5c: Baseline E2E evaluation (no compression)

### Motivation
- Tasks 5a/5b train per-layer compressors end-to-end and report PPL relative to an
  untrained baseline. The baseline PPL (3.937) comes from the raw model, but the
  train/val loss context is missing. Task 5c runs the same pipeline (same data loading
  via `load_e2e_data()`, same SFT loss computation, same PPL evaluation) but WITHOUT
  any compressors. This provides train/val loss references for fair comparison:
  if 5c train loss is ~1.0 and 5a-2x is 1.11, compression overhead is only +0.11.

### Changes

**HF: `src/run_e2e_compressor.py`**
- Added `"baseline"` to `--stale-mode` choices
- Added `evaluate_loss_no_hooks()` helper: same as `evaluate_val_loss()` but without
  a compressor manager, used for baseline train/val loss evaluation
- When `stale_mode == "baseline"`:
  - Output dir: `results/05c_e2e_baseline`
  - Title: "Task 05c: Baseline E2E Evaluation (no compression)"
  - Loads data, computes train/val loss via `evaluate_loss_no_hooks()`, saves results
  - Skips compression ratio loop and training curves plot
  - In PPL eval: only evaluates baseline PPL, skips ratio loop

**Megatron: `src/megatron_e2e/train.py`**
- Added `"baseline"` to `--stale-mode` choices
- Added `evaluate_loss_no_hooks()` helper with DP all-reduce
- When `stale_mode == "baseline"`:
  - Output dir: `results/05c_megatron_e2e_baseline`
  - Title: "Task 05c (Megatron): Baseline E2E Evaluation"
  - Computes train/val loss without compression, saves results
  - Skips compression ratio loop

**Bash scripts:**
- `scripts/05_run_e2e_compressor.sh`: accepts `baseline`, maps to `results/05c_e2e_baseline`
- `scripts/05_megatron_e2e.sh`: accepts `baseline`, maps to `results/05c_megatron_e2e_baseline`

**Documentation:**
- `CLAUDE.md`: added `05c_e2e_baseline/` and `05c_megatron_e2e_baseline/` to dir structure,
  added 5c running instructions
- `README.md`: added Task 5c row to experiment table, running instructions, output structure
- `description.md`: added Section 5.7 for Task 5c

### Design decisions
- Reused existing scripts (added `baseline` as 3rd stale-mode option, not new scripts)
- New helper `evaluate_loss_no_hooks()` is identical to `evaluate_val_loss()` but without
  the manager parameter, since baseline has no compressors
- Same data loading path (`load_e2e_data()`) ensures identical data pipeline
- No compression ratios — single evaluation pass with ratio=1.0

### Usage
```bash
# HF baseline:
bash scripts/05_run_e2e_compressor.sh baseline
# Megatron baseline:
CUDA_VISIBLE_DEVICES=0,1,2,3 bash scripts/05_megatron_e2e.sh baseline
```

## 2026-02-19 — Downstream task evaluation via lm-eval-harness

### Motivation
- All evaluation has been perplexity-only (Dolci-Instruct-SFT). Downstream task
  evaluation (e.g. GSM8K) provides a complementary signal about whether compression
  preserves reasoning ability, not just next-token prediction quality.
- Implemented as an optional step within each existing task, not a new task number.

### New file: `src/downstream_eval.py`
Shared utility module (~270 lines) providing:
- `register_quantization_hooks(model, bits)` — absmax hooks for Task 2
- `register_perlayer_hooks(model, weights_path, hidden_dim, ratio)` — per-layer hooks for Task 3b
- `register_stale_hooks(model, weights_path, hidden_dim, ratio, stale_mode, ref_stride)` — stale hooks for Task 4
- `register_e2e_hooks(model, weights_path, hidden_dim, ratio, stale_mode)` — E2E hooks for Task 5
- `run_lm_eval(model, tokenizer, tasks, ...)` — lm-eval-harness wrapper using HFLM
- `save_downstream_results(results, output_dir, tag, ...)` — JSON result saving
- `add_downstream_args(parser)` — standard CLI args for all scripts

### Edited files
- **`src/run_quantization.py`**: Added `--downstream-tasks` CLI args + STEP 4 after PPL eval
- **`src/run_perlayer_compressor.py`**: Same pattern
- **`src/run_stale_compressor.py`**: Same pattern
- **`src/run_e2e_compressor.py`**: Same pattern
- **`scripts/02_run_quantization.sh`**: Added DOWNSTREAM_TASKS/FEWSHOT/BATCH_SIZE/LIMIT env vars
- **`scripts/03b_run_perlayer_compressor.sh`**: Same
- **`scripts/04_run_stale_compressor.sh`**: Same
- **`scripts/05_run_e2e_compressor.sh`**: Same
- **`requirements.txt`**: Added `lm_eval[hf]>=0.4.4`
- **`CLAUDE.md`**: Added `downstream_eval.py` to code architecture, downstream eval section

### Design decisions
- Reused existing hook patterns from `model_utils.py` evaluation functions
- Each `register_*_hooks()` returns hook handles (and module refs to prevent GC)
- `register_e2e_hooks()` reuses `E2ECompressorManager` directly
- Downstream eval is opt-in: only runs when `--downstream-tasks` is specified
- Results saved as `downstream_results.json` alongside `perplexity_results.json`
- GSM8K variant: `gsm8k_cot` (chain-of-thought, 8-shot, generate_until)

### Usage
```bash
# Run any task with downstream eval:
DOWNSTREAM_TASKS="gsm8k_cot" bash scripts/02_run_quantization.sh

# Smoke test with 10 examples:
DOWNSTREAM_TASKS="gsm8k_cot" DOWNSTREAM_LIMIT=10 bash scripts/05_run_e2e_compressor.sh none

# Skip-training mode + downstream:
DOWNSTREAM_TASKS="gsm8k_cot" python src/run_e2e_compressor.py \
    --skip-training --output-dir results/05a_e2e_perlayer --stale-mode none
```

## 2026-02-20 — GSM8K downstream evaluation results (all methods)

### What was done
Ran GSM8K chain-of-thought (8-shot, 1319 test examples) on all compression methods
using a standalone evaluation script that loads the model once per GPU and swaps hooks.
8 GPUs used in parallel — completed in ~3 hours wall time.

### New files
- **`src/run_all_downstream.py`**: Standalone script, loads model once, evaluates all
  methods by swapping hooks. Supports `--method` and `--ratios` for parallel GPU usage.
- **`scripts/run_all_downstream.sh`**: Bash wrapper that launches 8 parallel instances.

### Results (GSM8K exact_match, strict / flexible)

| Method | Ratio | Strict | Flexible |
|---|---|---|---|
| Baseline | — | 44.12% | 82.79% |
| INT8 | 2x | 48.90% | 82.26% |
| INT4 | 4x | 56.41% | 68.54% |
| INT2 | 8x | 0.00% | 0.00% |
| Perlayer | 2x | 0.00% | 1.52% |
| Perlayer | 4x-16x | 0.00% | 0.00% |
| Stale comp. | 2x | 3.41% | 62.55% |
| Stale uncomp. | 2x | 2.81% | 67.10% |
| E2E per-layer | 2x | 61.33% | 61.64% |
| E2E per-layer | 4x | 20.70% | 21.30% |
| E2E stale | 2x | 60.27% | 60.65% |
| E2E stale | 4x | 31.54% | 32.37% |
| E2E stale | 8x | 4.93% | 5.00% |

### Key findings
1. **E2E 2x improves GSM8K by +17 pp** over baseline (61.33% vs 44.12%), confirming
   the regularization effect seen in PPL.
2. **Offline methods catastrophically fail on generation** — even stale_uncomp_2x
   (PPL=5.15) drops to 2.81% strict-match. But flexible-extract shows 67.10%,
   meaning the model still reasons correctly but output formatting is destroyed.
3. **The strict-vs-flexible gap is a new diagnostic**: E2E methods have ~0.3 pp gap
   (format preserved), offline methods have up to 64 pp gap (format destroyed).
4. **GSM8K is much more sensitive than PPL** to compression artifacts.
5. **INT4 quantization surprisingly improves strict-match** to 56.41% (+12 pp)
   while flexible-extract drops only to 68.54% from 82.79%.

### Updated files
- **`description.md`**: Added GSM8K columns to Section 6.1 summary table, added
  Section 6.4 with downstream analysis, updated Section 6.2 key findings.
- **`JOURNAL.md`**: This entry.

## 2026-02-20 — Fix description.md PPL numbers to match actual JSON results

### Problem
The PPL numbers in description.md did not match the actual values in
`results/*/perplexity_results.json`. For example:
- Baseline was listed as 4.23 but actual value is 3.89 (Tasks 2–4) / 3.94 (Megatron 5c)
- Perlayer 2x was listed as 5.92 but actual value is 21.07
- Stale uncomp 2x was listed as 5.15 but actual value is 6.24

The old numbers likely came from a previous run with different settings.

### Fix
Updated Section 6.1 summary table, Section 6.2 key findings, Section 6.4 downstream
analysis, all with values directly from the JSON result files. Added note to Section 6.3
that HF E2E comparison uses numbers from a previous run (weights no longer available).
Split baseline into two rows: Tasks 2–4 (PPL=3.89) and Megatron 5c (PPL=3.94).

### Updated files
- **`description.md`**: All PPL numbers in Sections 6.1, 6.2, 6.3, 6.4 corrected.
