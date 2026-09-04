#!/bin/bash
set -uo pipefail
BITSS=(16:16:16 8:8:8 4:4:4 2:2:2)
BLOCKSS=(32:32:32 4:4:4)
ACCUMS=(flat)
LOSS_SETA=(
  "softmax:10"
  "hinge:12"
)
INBLOCK="${INBLOCK:-32}"
EPOCHS="${EPOCHS:-48}"
SEED="${SEED:-701}"
THREADS="${THREADS:-16}"
make clean-tiny_vit
make train_quant_tiny_vit CFLAGS_EXTRA="-march=native -DMXINT_ROUNDING=1" -j "$THREADS"
export OMP_NUM_THREADS="$THREADS"
export OMP_PROC_BIND=close
export OMP_PLACES=cores
for BITS in "${BITSS[@]}"; do
  IFS=: read -r WBITS DXBITS ABITS <<< "$BITS"
  TAG="w${WBITS}dx${DXBITS}a${ABITS}"
for BLOCKS in "${BLOCKSS[@]}"; do
  IFS=: read -r WBLK DXBLK ABLK <<< "$BLOCKS"
  BTAG="wb${WBLK}gb${DXBLK}ab${ABLK}"
for ACC in "${ACCUMS[@]}"; do
for ls in "${LOSS_SETA[@]}"; do
  LOSS="${ls%%:*}"
  IFS=',' read -r -a SETA_ARR <<< "${ls#*:}"
for SETA in "${SETA_ARR[@]}"; do
  OUTDIR="out/local/tiny_vit_p4_${TAG}_${BTAG}_mom3_${ACC}/${LOSS}_seta${SETA}"
  mkdir -p "$OUTDIR"
  echo "=== tiny_vit p4 ${LOSS} bits=${WBITS}:${DXBITS}:${ABITS} blocks=${WBLK}:${DXBLK}:${ABLK} accum=${ACC} seta=${SETA} seed=${SEED} ==="
  /usr/bin/time -v ./train_quant_tiny_vit \
    --weight-bits "$WBITS" --gradient-bits "$DXBITS" --activation-bits "$ABITS" \
    --weight-block "$WBLK" --gradient-block "$DXBLK" --activation-block "$ABLK" \
    --input-bits 8 --input-block "$INBLOCK" \
    --accum-mode-conv "$ACC" --accum-shift-conv 12 \
    --accum-mode-linear "$ACC" --accum-shift-linear 12 \
    --loss "$LOSS" --s-eta "$SETA" --lr-halve-every 16 \
    --momentum 3 --momentum-bits 0 \
    --lr-schedule plateau --lr-patience 2 \
    --batch-size 256 --epochs "$EPOCHS" --val-size 10000 --patience 4 \
    --select-by acc --save-best "$OUTDIR/seed${SEED}_best" \
    --augment --log-interval 1 --seed "$SEED" \
    2>&1 | tee "$OUTDIR/seed${SEED}.log"
  rc=${PIPESTATUS[0]}
  if [ "$rc" -ne 0 ]; then
    echo "=== FAILED (rc=$rc): tiny_vit p4 ${LOSS} bits=${WBITS}:${DXBITS}:${ABITS} blocks=${WBLK}:${DXBLK}:${ABLK} accum=${ACC} seta=${SETA} ===" | tee -a "$OUTDIR/seed${SEED}.log"
  fi
done
done
done
done
done
