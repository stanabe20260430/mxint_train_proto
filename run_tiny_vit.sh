#!/usr/bin/env bash
set -uo pipefail

SETAS=(8 10 12 14 16)
LOSS="${LOSS:-softmax}"
EPOCHS="${EPOCHS:-1}"
SEED="${SEED:-701}"

make clean-tiny_vit
make train_quant_tiny_vit CFLAGS_EXTRA="-march=native -DMXINT_ROUNDING=1 -DTV_PATCH=8" -j 16

export OMP_NUM_THREADS=16
export OMP_PROC_BIND=close
export OMP_PLACES=cores

for SETA in "${SETAS[@]}"; do
  OUTDIR="out/local/tiny_vit_p8_w16_blk32_mom3/${LOSS}_seta${SETA}"
  mkdir -p "$OUTDIR"
  echo "=== tiny_vit ${LOSS} seta=${SETA} seed=${SEED} ==="
  /usr/bin/time -v ./train_quant_tiny_vit \
    --weight-bits 16 --gradient-bits 16 --activation-bits 16 \
    --weight-block 32 --gradient-block 32 --activation-block 32 \
    --input-bits 8 --input-block 32 \
    --accum-mode-conv two_stage --accum-shift-conv 12 \
    --accum-mode-linear two_stage --accum-shift-linear 12 \
    --loss "$LOSS" --s-eta "$SETA" --lr-halve-every 16 \
    --momentum 3 --momentum-bits 0 \
    --lr-schedule plateau --lr-patience 2 \
    --batch-size 256 --epochs "$EPOCHS" --val-size 10000 --patience 4 \
    --select-by acc --save-best "$OUTDIR/seed${SEED}_best" \
    --augment --log-interval 1 --seed "$SEED" \
    2>&1 | tee "$OUTDIR/seed${SEED}.log"
  rc=${PIPESTATUS[0]}
  if [ "$rc" -ne 0 ]; then
    echo "=== FAILED (rc=$rc): tiny_vit ${LOSS} seta=${SETA} ===" | tee -a "$OUTDIR/seed${SEED}.log"
  fi
done
