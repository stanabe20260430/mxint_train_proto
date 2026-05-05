# mxint_train_proto

A research prototype for training LeNet-5 on MNIST with
[OCP MX](https://www.opencompute.org/documents/ocp-microscaling-formats-mx-v1-0-spec-final-pdf)
shared-exponent integer formats (MXINT16 / MXINT8 / MXINT4 / MXINT2).

This code accompanies submission MPS158 to PDPTA'26. It is a single-author
research prototype written in portable C (no float, no 64-bit division, no
libc dependency beyond stdio/stdlib/string/math/time in the host layer) so
the core kernels can run unchanged on a 32-bit RISC-V target.

**Status:** research prototype. Expect rough edges.
**License:** see `LICENSE`.


## Quick start

Training takes fp32 MNIST IDX files in `./data/`.

```
cd mxint_train_proto
make CFLAGS_EXTRA="-DQUANT_BITS=8 -DQUANT_DEBUG -DMX_BLOCK_SIZE=8" -j18

./train_quant --seed 101 --loss-type hinge \
              --model-variant w16_dx8_conv12conv24fc4 \
              --epochs 1 --batch-size 256 --s-eta 13
```

Build-time flags:

- `-DQUANT_BITS={8,16}` — element width used by the core ops. The
  mixed-precision variants are built with `QUANT_BITS=8`; `QUANT_BITS=16`
  is for the pure-INT16 baseline built as a simpler standalone.
- `-DMX_BLOCK_SIZE={4,8,16,32,64}` — shared-exponent block size. Default 32,
  matches the OCP MX spec.
- `-DQUANT_DEBUG` — enables per-tensor underflow/overflow counters written
  to `analysis/scale_stats_*.csv` via `--save-scale-stats`.

Runtime flags of interest:

- `--loss-type {hinge,softmax}` — Weston–Watkins hinge or base-2 softmax+CE.
- `--model-variant <n>` — picks a per-tensor bit-width layout. The 18
  supported names are listed below. All variants require the
  `QUANT_BITS=8` build. Each hinge variant has a matching `_softmax` twin
  with identical bit layout but a softmax+CE head instead of
  Weston–Watkins hinge.

  | Variant (hinge) | Variant (softmax) | W | dx | a |
  | --- | --- | --- | --- | --- |
  | `w16_dx16_a16` | `w16_dx16_a16_softmax` | 16 | 16 | 16 |
  | `w8_dx8_a8` | `w8_dx8_a8_softmax` | 8 | 8 | 8 |
  | `w16_dx8_a8` | `w16_dx8_a8_softmax` | 16 | 8 | 8 |
  | `w16_dx8_a4` | `w16_dx8_a4_softmax` | 16 | 8 | 4 |
  | `w16_dx4_a4` | `w16_dx4_a4_softmax` | 16 | 4 | 4 |
  | `w16_dx8_a2` | `w16_dx8_a2_softmax` | 16 | 8 | 2 |
  | `w16_dx8_convs2fc4` | `w16_dx8_convs2fc4_softmax` | 16 | 8 | 2 / 4 |
  | `w16_dx8_convs2ip14tip28` | `w16_dx8_convs2ip14tip28_softmax` | 16 | 8 | 2 / 4 / 8 |
  | `w16_dx8_conv12conv24fc4` | `w16_dx8_conv12conv24fc4_softmax` | 16 | 8 | 2 / 4 |

  Columns: `W` = weight width (bits), `dx` = gradient width (bits),
  `a` = forward activation width (bits). Multiple values in one cell
  (e.g. `2 / 4`) denote per-layer widths applied along the forward
  path (conv stage → FC tail); see `model/quant/quant_lenet_<variant>.c`
  for the exact per-tensor mapping. The name convention is
  `w{W}_dx{dx}_a{a}` for uniform cases; mixed per-layer layouts get
  descriptive names (e.g. `convs2fc4` = "conv stage INT2, FC INT4").

- `--s-eta N` — learning rate exponent (lr = 2^-N; halves every epoch).
- `--save-scale-stats` — write per-block underflow counters and data-range
  statistics to CSV for post-hoc analysis.


## Directory layout

```
mxint_train_proto/
├── Makefile                 Build rules for train_quant / convert_ckpt /
│                            unit_test_pytorch.
├── include/                 Public headers (qtensor, qconvert, quant_ops,
│                            fp32_ref, mnist_loader, lenet_shape, …).
├── src/                     Core quantized tensor ops (no stdlib float, no
│                            division, no int64). One file per op family:
│                            conv, linear, softmax, hinge, pool, relu,
│                            elemwise, flatten, sgd.
├── host/                    Host-only helpers that do use float: Xavier
│                            init, fp32 reference forward/softmax, MNIST
│                            loader, fp32<->MXINT conversion.
├── model/
│   ├── fp32/                FP32 LeNet-5 reference, used only for weight
│                            initialisation and accuracy comparison.
│   └── quant/               Per-variant LeNet-5 pins (one pair of .c/.h
│                            per --model-variant value). Each file wires
│                            up per-tensor bit widths and calls the core
│                            ops in src/.
├── train/                   Training-loop driver.
│   ├── train_quant.c        main() — MNIST dataloader, per-epoch loop,
│                            checkpoint/resume, scale-stats CSV.
│   ├── train_quant_args.c   CLI parse / validate / startup-log.
│                            MODEL_VARIANT_TABLE lives here.
│   ├── train_quant_eval.c   Dataset-level accuracy/loss computation.
│   ├── train_quant_setup.c  Weight initialisation + checkpoint save.
│   ├── scale_stats.c        Per-block underflow/overflow CSV writer.
│   ├── dump_state.c         Tensor snapshot format for reproducibility.
│   ├── convert_checkpoint.c Standalone tool to convert fp32 checkpoints
│                            to MXINT layout.
│   └── …                    Common I/O helpers.
├── test/pytorch/            Per-op regression tests against PyTorch
│                            goldens. Reports error metrics (max_abs,
│                            mean_abs, max_rel, mean_rel); no pass/fail
│                            threshold is encoded.
├── scripts/                 Shell and Python helpers for sweeping and
│                            aggregation. `run_debug_sweep.sh` runs the
│                            full variant × seed × s-eta sweep with
│                            scale-stats CSV output;
│                            `run_quant_variant.sh <variant>` runs a
│                            single variant. `summarize_test_acc.py`
│                            and `summarize_underflow_acc.py` aggregate
│                            sweep CSVs into per-variant tables.
├── README.md                This file.
└── LICENSE                  Licensing terms.
```


## Contact

Author: Satoshi Tanabe.
For questions, please cite the paper and contact via the submission system.
