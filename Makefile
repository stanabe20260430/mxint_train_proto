
CC          = gcc
OPENMP     ?= -fopenmp
CFLAGS      = -O2 -Wall -Wextra -I include -I src -I host -I test/pytorch -I model/fp32 -I model/quant -I train -I configs/lenet/pins -I configs/vgg7/pins -I configs/resnet18/pins -I configs/softmax/pins -I configs/hinge/pins $(OPENMP) $(CFLAGS_EXTRA)
LDFLAGS     = -lm

TARGET_TRAIN_QUANT  = train_quant
TARGET_UT_PYTORCH   = unit_test_pytorch
TARGET_VIT_CHECK    = vit_selfcheck

SRCS_SRC    = src/quant_lut.c \
              src/quant_ops_common.c \
              src/quant_ops_vit_matmul.c \
              src/quant_ops_vit_softmax.c \
              src/quant_ops_vit_embed.c \
              src/quant_ops_elemwise.c \
              src/quant_ops_relu.c \
              src/quant_ops_pool.c \
              src/quant_ops_conv.c \
              src/quant_ops_conv_two_stage.c \
              src/quant_ops_linear.c \
              src/quant_ops_linear_two_stage.c \
              src/quant_ops_dispatch.c \
              src/quant_ops_softmax.c \
              src/quant_ops_layernorm.c \
              src/quant_ops_batchnorm.c \
              src/quant_ops_global_avgpool.c \
              src/quant_ops_branch.c \
              src/quant_ops_sgd.c \
              src/quant_ops_flatten.c \
              src/quant_ops_hinge.c \
              src/prng.c

SRCS_HOST   = host/qconvert.c \
              host/qconvert_vit.c \
              host/mnist_loader.c \
              host/fp32_xavier.c \
              host/fp32_ref_alloc.c \
              host/fp32_loss_monitor.c

SRCS_MODEL_FP32   = model/fp32/fp32_lenet.c
SRCS_MODEL_QUANT  = model/quant/quant_lenet.c model/quant/quant_lenet_pinned.c model/quant/quant_lenet_softmax_pinned.c configs/lenet/pins/table.c configs/softmax/pins/table.c configs/hinge/pins/table.c model/quant/quant_lenet_hinge.c

SRCS_TEST_EXTRA = train/model_io_quant.c \
                  train/train_common.c train/train_eval.c train/train_options.c \
                  train/binio.c
OBJS_TEST_EXTRA = $(SRCS_TEST_EXTRA:.c=.o)

SRCS_TEST_PYTORCH = test/pytorch/unit_test.c \
                    test/pytorch/unit_test_softmax_pytorch.c \
                    test/pytorch/unit_test_rsqrt_pytorch.c \
                    test/pytorch/unit_test_layernorm_pytorch.c \
                    test/pytorch/unit_test_batchnorm_pytorch.c \
                    test/pytorch/unit_test_avgpool_pytorch.c \
                    test/pytorch/unit_test_branch_pytorch.c \
                   test/pytorch/unit_test_vit_pytorch.c \
                    test/pytorch/unit_test_hinge_pytorch.c \
                    test/pytorch/unit_test_relu_pytorch.c \
                    test/pytorch/unit_test_flatten_pytorch.c \
                    test/pytorch/unit_test_elemwise_pytorch.c \
                    test/pytorch/unit_test_linear_pytorch.c \
                    test/pytorch/unit_test_maxpool_pytorch.c \
                    test/pytorch/unit_test_conv_pytorch.c \
                    test/pytorch/unit_test_onehot_pytorch.c \
                    test/pytorch/unit_test_sgd_pytorch.c \
                    test/pytorch/load_golden.c
OBJS_TEST_PYTORCH = $(SRCS_TEST_PYTORCH:.c=.o)

SRCS_TRAIN_QUANT = train/train_common.c train/train_eval.c train/model_io_quant.c train/binio.c train/train_options.c train/scale_stats.c train/dump_state.c train/dump_raw.c train/train_quant.c train/train_quant_args.c train/train_quant_eval.c train/train_quant_setup.c train/quant_lenet_ops_table.c train/train_quant_step.c
OBJS_TRAIN_QUANT = $(SRCS_TRAIN_QUANT:.c=.o)


OBJS_COMMON = $(SRCS_SRC:.c=.o) $(SRCS_HOST:.c=.o) \
              $(SRCS_MODEL_FP32:.c=.o) $(SRCS_MODEL_QUANT:.c=.o)

TARGET_TRAIN_QUANT_VGG7 = train_quant_vgg7
TARGET_TRAIN_QUANT_R18  = train_quant_resnet18
TARGET_TRAIN_QUANT_R9   = train_quant_resnet9
TARGET_TRAIN_QUANT_TV   = train_quant_tiny_vit

SRCS_HOST_VGG7        = host/qconvert.c host/qconvert_vit.c host/cifar_loader.c host/fp32_xavier.c \
                        host/fp32_ref_alloc.c host/fp32_loss_monitor.c
SRCS_MODEL_FP32_VGG7  = model/fp32/fp32_vgg7.c
SRCS_MODEL_QUANT_R18 = model/quant/quant_resnet18.c model/quant/quant_resnet18_pinned.c configs/resnet18/pins/table.c
SRCS_TRAIN_QUANT_R18 = train/train_quant_resnet18.c train/train_quant_resnet18_args.c \
                       train/train_quant_resnet18_setup.c train/train_quant_resnet18_step.c \
                       train/train_quant_resnet18_eval.c train/quant_resnet18_ops_table.c \
                       train/model_io_quant_resnet18.c
OBJS_R18 = $(SRCS_MODEL_QUANT_R18:.c=.o) $(SRCS_TRAIN_QUANT_R18:.c=.o)

SRCS_MODEL_QUANT_R9 = model/quant/quant_resnet9.c model/quant/quant_resnet9_pinned.c \
                      configs/resnet18/pins/table.c
SRCS_TRAIN_QUANT_R9 = train/train_quant_resnet9.c train/train_quant_resnet9_args.c \
                      train/train_quant_resnet9_setup.c train/train_quant_resnet9_step.c \
                      train/train_quant_resnet9_eval.c \
                      train/model_io_quant_resnet9.c

SRCS_MODEL_QUANT_TV = model/quant/quant_tiny_vit.c model/quant/quant_tiny_vit_pinned.c \
                      configs/resnet18/pins/table.c
SRCS_TRAIN_QUANT_TV = train/train_quant_tiny_vit.c train/train_quant_tiny_vit_args.c \
                      train/train_quant_tiny_vit_setup.c train/train_quant_tiny_vit_step.c \
                      train/train_quant_tiny_vit_eval.c \
                      train/model_io_quant_tiny_vit.c

SRCS_MODEL_QUANT_VGG7 = model/quant/quant_vgg7.c model/quant/quant_vgg7_pinned.c model/quant/quant_vgg7_softmax_pinned.c configs/vgg7/pins/table.c configs/softmax/pins/table.c configs/hinge/pins/table.c model/quant/quant_vgg7_hinge.c
                       
SRCS_TRAIN_QUANT_VGG7 = train/train_common_vgg7.c train/train_eval.c \
                        train/train_options.c train/train_quant_vgg7_setup.c \
                        train/train_quant_vgg7_step.c train/train_quant_vgg7_eval.c \
                        train/model_io_quant_vgg7.c train/binio.c train/scale_stats.c \
                        train/quant_vgg7_ops_table.c train/train_quant_vgg7_args.c \
                        train/train_quant_vgg7.c

OBJS_TRAIN_QUANT_VGG7 = $(SRCS_SRC:.c=.o) $(SRCS_HOST_VGG7:.c=.o) \
                        $(SRCS_MODEL_FP32_VGG7:.c=.o) \
                        $(SRCS_MODEL_QUANT_VGG7:.c=.o) \
                        $(SRCS_TRAIN_QUANT_VGG7:.c=.o)

.PHONY: all clean gen-pytorch-goldens test-pytorch

all: $(TARGET_TRAIN_QUANT)

$(TARGET_TRAIN_QUANT): $(OBJS_COMMON) $(OBJS_TRAIN_QUANT)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(TARGET_TRAIN_QUANT_VGG7): $(OBJS_TRAIN_QUANT_VGG7)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)



.PHONY: clean-vgg7 clean-resnet18 clean-resnet9 clean-tiny_vit
clean-tiny_vit:
	rm -f $(OBJS_TRAIN_QUANT_TV) $(TARGET_TRAIN_QUANT_TV)

clean-resnet9:
	rm -f $(OBJS_TRAIN_QUANT_R9) $(TARGET_TRAIN_QUANT_R9)

clean-resnet18:
	rm -f $(OBJS_TRAIN_QUANT_R18) $(TARGET_TRAIN_QUANT_R18)

clean-vgg7:
	rm -f host/cifar_loader.o model/fp32/fp32_vgg7.o \
	      $(SRCS_MODEL_QUANT_VGG7:.c=.o) \
	      train/train_common_vgg7.o train/train_quant_vgg7_setup.o \
	      train/train_quant_vgg7_step.o train/train_quant_vgg7_eval.o \
	      train/model_io_quant_vgg7.o \
	      train/quant_vgg7_ops_table.o train/train_quant_vgg7_args.o \
	      train/train_quant_vgg7.o \
	      $(TARGET_TRAIN_QUANT_VGG7)

OBJS_TRAIN_QUANT_R18 = $(SRCS_SRC:.c=.o) $(SRCS_HOST_VGG7:.c=.o) \
                       train/train_common_vgg7.o train/train_eval.o \
                       train/train_options.o train/binio.o \
                       train/scale_stats.o \
                       $(SRCS_MODEL_FP32_VGG7:.c=.o) \
                       configs/softmax/pins/table.o configs/hinge/pins/table.o \
                       $(SRCS_MODEL_QUANT_R18:.c=.o) \
                       $(SRCS_TRAIN_QUANT_R18:.c=.o)

$(TARGET_TRAIN_QUANT_R18): $(OBJS_TRAIN_QUANT_R18)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

OBJS_TRAIN_QUANT_R9 = $(SRCS_SRC:.c=.o) $(SRCS_HOST_VGG7:.c=.o) \
                      train/train_common_vgg7.o train/train_eval.o \
                      train/train_options.o train/binio.o \
                      train/scale_stats.o \
                      $(SRCS_MODEL_FP32_VGG7:.c=.o) \
                      configs/softmax/pins/table.o configs/hinge/pins/table.o \
                      $(SRCS_MODEL_QUANT_R9:.c=.o) \
                      $(SRCS_TRAIN_QUANT_R9:.c=.o)

$(TARGET_TRAIN_QUANT_R9): $(OBJS_TRAIN_QUANT_R9)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

OBJS_TRAIN_QUANT_TV = $(SRCS_SRC:.c=.o) $(SRCS_HOST_VGG7:.c=.o) \
                      train/train_common_vgg7.o train/train_eval.o \
                      train/train_options.o train/binio.o \
                      train/scale_stats.o \
                      $(SRCS_MODEL_FP32_VGG7:.c=.o) \
                      configs/softmax/pins/table.o configs/hinge/pins/table.o \
                      $(SRCS_MODEL_QUANT_TV:.c=.o) \
                      $(SRCS_TRAIN_QUANT_TV:.c=.o)

$(TARGET_TRAIN_QUANT_TV): $(OBJS_TRAIN_QUANT_TV)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(TARGET_UT_PYTORCH): $(OBJS_COMMON) $(OBJS_TEST_EXTRA) $(OBJS_TEST_PYTORCH)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

SRCS_VIT_CHECK = test/vit_selfcheck.c src/quant_ops_vit_matmul.c \
                 src/quant_ops_vit_softmax.c src/quant_ops_vit_embed.c \
                 src/quant_ops_common.c src/quant_lut.c host/qconvert.c \
                 host/qconvert_vit.c

$(TARGET_VIT_CHECK): $(SRCS_VIT_CHECK)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS) -lm

.PHONY: test-vit
test-vit: $(TARGET_VIT_CHECK)
	./$(TARGET_VIT_CHECK)

gen-pytorch-goldens:
	python3 scripts/gen_pytorch_goldens.py

test-pytorch: gen-pytorch-goldens $(TARGET_UT_PYTORCH)
	./$(TARGET_UT_PYTORCH)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS_COMMON) $(OBJS_TEST_EXTRA) $(OBJS_TEST_PYTORCH) \
	      $(OBJS_TRAIN_QUANT) \
	      $(TARGET_TRAIN_QUANT) $(TARGET_UT_PYTORCH)
