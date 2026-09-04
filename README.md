# mxint_train_proto

MXINT only integer training prototype in C. LeNet on MNIST, VGG7 /
ResNet9 / ResNet18 / Tiny-ViT on CIFAR-10.

## Local runs (`run_*.sh`)

Each script builds its own target first (`make clean-*` + `make ...`), then
loops over its sweep axes. Output goes to `out/local/...`, one `seed<N>.log`
per configuration.

```sh
./run_vgg7.sh
./run_resnet9.sh
./run_tiny_vit.sh
./run_tiny_vit_p4.sh
./run_lenet.sh
./run_lenet_sweepbits.sh
./run_lenet_sweepblock.sh
```

Settings are overridden by environment variable:

```sh
LOSS=hinge EPOCHS=48 SEED=702 ./run_vgg7.sh
EPOCHS=8 THREADS=32 ACC=c-t12_l-t12_b-t12 ./run_lenet.sh
```

| Script | Sweep | Variables (default) |
| --- | --- | --- |
| `run_vgg7.sh` | `s_eta` 8/10/12/14/16 | `LOSS` (softmax), `EPOCHS` (1), `SEED` (701) |
| `run_resnet9.sh` | `s_eta` 8/10/12/14/16 | `LOSS` (softmax), `EPOCHS` (1), `SEED` (701) |
| `run_tiny_vit.sh` | `s_eta` 8/10/12/14/16, patch 8 | `LOSS` (softmax), `EPOCHS` (1), `SEED` (701) |
| `run_tiny_vit_p4.sh` | 4 bit-widths x 2 block sizes x 2 losses, patch 4 | `EPOCHS` (48), `INBLOCK` (32), `SEED` (701), `THREADS` (16) |
| `run_lenet.sh` | 10 bit-widths x 2 block sizes x 2 losses | `INBITS` (8), `INBLOCK` (32), `ACC` (c-f_l-f_b-f), `EPOCHS` (8), `STATS_INTERVAL` (1), `SEED` (701), `THREADS` (16) |
| `run_lenet_sweepbits.sh` | bit-width sweep at block 32, seeds 802-805 | same as above, minus `SEED`; `THREADS` (32) |
| `run_lenet_sweepblock.sh` | block-size sweep at 4 bits, seeds 802-805 | same as above, minus `SEED`; `THREADS` (32) |

`ACC` selects the accumulator mode per operation as `c-<m>_l-<m>_b-<m>`
(conv / linear / batchnorm), where `<m>` is `f` for flat or `t<S>` for
two-stage above flat shift `S`.

## Slurm sweeps (`submit_sweep_*.sh`)

Each script builds the target, then submits one `sbatch` job per
configuration to the matching `sbatch/*_job.sh`. Output goes to `out/...`.

```sh
./submit_sweep_vgg7.sh
./submit_sweep_resnet9.sh
./submit_sweep_resnet18.sh
./submit_sweep_tiny_vit.sh
./submit_sweep_lenet.sh
```

```sh
QUANT_DEBUG=1 STATS=1 LR_SCHEDULE=fixed ./submit_sweep_vgg7.sh
```

| Script | Variables (default) |
| --- | --- |
| `submit_sweep_vgg7.sh` | `SMOM` (3), `MBITS` (0), `STATS` (0), `QUANT_DEBUG` (0), `LR_SCHEDULE` (plateau), `LR_PATIENCE` (2) |
| `submit_sweep_resnet9.sh` | above plus `BNRECAL` (32) |
| `submit_sweep_resnet18.sh` | above plus `BNBITS` (16), `BNRECAL` (32) |
| `submit_sweep_tiny_vit.sh` | above plus `BNBITS` (16) |
| `submit_sweep_lenet.sh` | none |

`STATS=1` enables `--save-scale-stats`; `QUANT_DEBUG=1` adds `-DQUANT_DEBUG`
to the build for the underflow / overflow counters.

## Job control

```sh
./check_myjob.sh
```

`run_sbatch.sh` is a scratch list of tmux / squeue / scancel commands, not a
script to execute top to bottom.

## Tests

```sh
make test-pytorch
make test-vit
```

See `test/pytorch/README.md`. PyTorch baselines and log tooling are in
`scripts/README.md`.
