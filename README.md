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

## Tree

```
.
├── Makefile                          all build targets
├── run_lenet.sh                      local: LeNet bit-width x block-size sweep
├── run_lenet_sweepbits.sh            local: LeNet bit-width sweep, seeds 802-805
├── run_lenet_sweepblock.sh           local: LeNet block-size sweep, seeds 802-805
├── run_vgg7.sh                       local: VGG7 s_eta sweep
├── run_resnet9.sh                    local: ResNet9 s_eta sweep
├── run_tiny_vit.sh                   local: Tiny-ViT patch 8 s_eta sweep
├── run_tiny_vit_p4.sh                local: Tiny-ViT patch 4 bit/block sweep
├── submit_sweep_lenet.sh             Slurm: LeNet sweep submitter
├── submit_sweep_vgg7.sh              Slurm: VGG7 sweep submitter
├── submit_sweep_resnet9.sh           Slurm: ResNet9 sweep submitter
├── submit_sweep_resnet18.sh          Slurm: ResNet18 sweep submitter
├── submit_sweep_tiny_vit.sh          Slurm: Tiny-ViT sweep submitter
├── check_myjob.sh                    squeue one-liner for the current user
├── run_sbatch.sh                     scratch tmux / scancel commands
│
├── sbatch/                           job scripts invoked by submit_sweep_*.sh
│   ├── lenet_job.sh                  one LeNet run from positional args
│   ├── vgg7_job.sh                   one VGG7 run from positional args
│   ├── resnet9_job.sh                one ResNet9 run from positional args
│   ├── resnet18_job.sh               one ResNet18 run from positional args
│   └── tiny_vit_job.sh               one Tiny-ViT run from positional args
│
├── include/                          public headers
│   ├── qtensor.h                     QTensor / QConvKernel types, block layout, accumulator globals
│   ├── quant_ops.h                   quantized operator API
│   ├── quant_ops_vit.h               ViT operator API (matmul / permute / embed descriptors)
│   ├── quant_lut.h                   lookup-table API for pow2 / reciprocal / rsqrt
│   ├── qconvert.h                    FP32 to MXINT conversion API
│   ├── qconvert_vit.h                same, for ViT tensors
│   ├── fp32_ref.h                    FP32 reference tensor types
│   ├── fp32_xavier.h                 Xavier initialization API
│   ├── fp32_loss_monitor.h           FP32 loss monitor API
│   ├── mnist_loader.h                MNIST loader API
│   ├── cifar_loader.h                CIFAR-10 loader and augmentation API
│   └── lenet_shape.h                 LeNet layer dimensions
│
├── src/                              quantized operator kernels
│   ├── quant_ops_common.c            allocation and free helpers
│   ├── quant_ops_common.h            shared internal macros and helpers
│   ├── quant_ops_dispatch.c          routes conv / linear to flat or two-stage
│   ├── quant_ops_two_stage.h         two-stage accumulation and requantization helpers
│   ├── quant_ops_conv.c              conv forward / backward, flat accumulation
│   ├── quant_ops_conv_two_stage.c    conv forward / backward, two-stage accumulation
│   ├── quant_ops_linear.c            linear forward / backward, flat accumulation
│   ├── quant_ops_linear_two_stage.c  linear forward / backward, two-stage accumulation
│   ├── quant_ops_batchnorm.c         batchnorm forward / backward and recalibration
│   ├── quant_ops_layernorm.c         layernorm forward / backward
│   ├── quant_ops_softmax.c           base-2 softmax and cross-entropy
│   ├── quant_ops_hinge.c             hinge loss forward / backward
│   ├── quant_ops_relu.c              ReLU forward / backward
│   ├── quant_ops_pool.c              max pooling forward / backward
│   ├── quant_ops_global_avgpool.c    global average pooling forward / backward
│   ├── quant_ops_flatten.c           flatten / reshape
│   ├── quant_ops_elemwise.c          element-wise add and multiply
│   ├── quant_ops_branch.c            residual branch split and join
│   ├── quant_ops_sgd.c               SGD update with momentum and weight decay
│   ├── quant_ops_vit_matmul.c        batched matmul (NN / NT) for attention
│   ├── quant_ops_vit_softmax.c       attention softmax
│   ├── quant_ops_vit_embed.c         patch embedding, cls token, positional add, permute
│   ├── quant_lut.c                   generates the pow2 / reciprocal / rsqrt tables
│   ├── prng.c                        xorshift PRNG
│   └── prng.h                        PRNG state and inline next()
│
├── model/
│   ├── fp32/                         FP32 reference models
│   │   ├── fp32_lenet.c / .h         LeNet forward in FP32
│   │   └── fp32_vgg7.c / .h          VGG7 forward in FP32
│   └── quant/                        quantized model graphs
│       ├── quant_lenet.c / .h        LeNet forward / backward
│       ├── quant_lenet_hinge.c / .h  LeNet hinge act / grad types and free
│       ├── quant_vgg7.c / .h         VGG7 forward / backward
│       ├── quant_vgg7_hinge.c / .h   VGG7 hinge act / grad types and free
│       ├── quant_resnet9.c / .h      ResNet9 forward / backward
│       ├── quant_resnet18.c / .h     ResNet18 forward / backward
│       ├── quant_tiny_vit.c / .h     Tiny-ViT forward / backward
│       ├── *_pinned.c / .h           same graphs with per-layer pinned scales applied
│       ├── vgg7_shape.h              VGG7 layer dimensions
│       ├── resnet9_shape.h           ResNet9 layer dimensions
│       ├── resnet18_shape.h          ResNet18 layer dimensions
│       └── tiny_vit_shape.h          Tiny-ViT layer dimensions
│
├── configs/                          per-layer scale pin tables
│   ├── lenet/pins/                   LeNet pin structs and lookup
│   ├── vgg7/pins/                    VGG7 pin structs and lookup
│   ├── resnet18/pins/                ResNet18 pin structs and lookup
│   ├── softmax/pins/                 pins for the softmax head
│   └── hinge/pins/                   pins for the hinge head
│
├── host/                             host-side support, not for the target
│   ├── mnist_loader.c                reads MNIST IDX files
│   ├── cifar_loader.c                reads CIFAR-10 binary batches, crop / flip augmentation
│   ├── qconvert.c                    FP32 to MXINT tensor / kernel / weight conversion
│   ├── qconvert_vit.c                same, for ViT tensors
│   ├── fp32_ref_alloc.c              allocates FP32 reference tensors with random values
│   ├── fp32_xavier.c                 Xavier range and initialization
│   └── fp32_loss_monitor.c           FP32 dyadic cross-entropy for comparison
│
├── train/                            training drivers
│   ├── train_quant.c                 LeNet training entry point
│   ├── train_quant_vgg7.c            VGG7 training entry point
│   ├── train_quant_resnet9.c         ResNet9 training entry point
│   ├── train_quant_resnet18.c        ResNet18 training entry point
│   ├── train_quant_tiny_vit.c        Tiny-ViT training entry point
│   ├── *_args.c / .h                 per-model CLI parsing and config printing
│   ├── *_setup.c / .h                per-model dataset and weight initialization
│   ├── *_step.c / .h                 per-model single training step
│   ├── *_eval.c / .h                 per-model validation and test evaluation
│   ├── train_options.c / .h          generic --flag / --key value parsing
│   ├── train_common.c / .h           MNIST dataset handling, LeNet init, batch accuracy
│   ├── train_common_vgg7.c / .h      CIFAR-10 dataset handling and VGG7 init
│   ├── train_common_resnet18.h       ResNet18 shared training declarations
│   ├── train_quant_common.h          shared quantized training config struct
│   ├── train_config_common.h         compile-time training defaults
│   ├── train_eval.c / .h             argmax accuracy and result printing
│   ├── model_io.h                    LeNet checkpoint save / load API
│   ├── model_io_quant.c              LeNet checkpoint save / load
│   ├── model_io_quant_vgg7.c / .h    VGG7 checkpoint save / load
│   ├── model_io_quant_resnet9.c / .h ResNet9 checkpoint save / load
│   ├── model_io_quant_resnet18.c / .h ResNet18 checkpoint save / load
│   ├── model_io_quant_tiny_vit.c / .h Tiny-ViT checkpoint save / load
│   ├── binio.c / .h                  little-endian integer read / write
│   ├── dump_state.c / .h             full training-state dump
│   ├── dump_raw.c / .h               raw packed-tensor dump for storage-format checks
│   ├── scale_stats.c / .h            per-tensor scale and over/underflow statistics to CSV
│   ├── quant_lenet_ops_table.c / .h  selects the LeNet loss-variant op table
│   ├── quant_vgg7_ops_table.c / .h   selects the VGG7 loss-variant op table
│   └── quant_resnet18_ops_table.c / .h selects the ResNet18 loss-variant op table
│
├── test/
│   ├── vit_selfcheck.c               goldens-free ViT kernel check (make test-vit)
│   └── pytorch/                      PyTorch-golden unit tests (make test-pytorch)
│       ├── README.md                 how to run the golden tests
│       ├── unit_test.c               test runner and CLI
│       ├── unit_test_*_pytorch.c / .h one suite per operator
│       ├── load_golden.c / .h        reads the .bin golden files
│       ├── golden_format.h           golden file header layout
│       └── pytorch_test_utils.h      comparison and reporting macros
│
└── scripts/                          PyTorch baselines and log tooling
    ├── README.md                     how to run the scripts below
    ├── run_pytorch_ref_mnist.sh      FP32 MNIST baseline sweep
    ├── run_pytorch_ref_cifar10_*.sh  FP32 CIFAR-10 baseline sweep, one per model
    ├── train_pytorch_ref_mnist.py    PyTorch MNIST training entry point
    ├── train_pytorch_ref_cifar10.py  PyTorch CIFAR-10 training entry point
    ├── gen_pytorch_goldens.py        writes the .bin goldens for the unit tests
    ├── log_to_csv.py                 parses a sweep log into CSV
    ├── baseline.txt                  recorded baseline accuracies
    └── logs/                         stored run logs
        ├── run_pytorch_ref_*.log     PyTorch baseline logs, fp32 and fp16
        └── quant/                    MXINT sweep logs, <model>/<loss>_seta<S>/seed701.log
            └── recommend_lr.txt      suggested s_eta per model
```
