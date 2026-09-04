#!/usr/bin/env bash
set -uo pipefail

LOSS_SETA=(
  "softmax:11,12"
  "hinge:13,14"
)
BITSS=(4:4:4)
BLOCKSS=(128:128:128 64:64:64 16:16:16 8:8:8 4:4:4)
INBITS="${INBITS:-8}"
INBLOCK="${INBLOCK:-32}"
ACC="${ACC:-c-f_l-f_b-f}"
EPOCHS="${EPOCHS:-8}"
STATS_INTERVAL="${STATS_INTERVAL:-1}"
SEEDS=($(seq 802 805))
THREADS="${THREADS:-32}"

make clean
make train_quant CFLAGS_EXTRA="-march=native -DMXINT_ROUNDING=1 -DQUANT_DEBUG" -j "$THREADS"

export OMP_NUM_THREADS="$THREADS"
export OMP_PROC_BIND=close
export OMP_PLACES=cores


ACC_FLAGS=""
for part in ${ACC//_/ }; do
  case "$part" in
    c-*) OP=conv   ; M="${part#c-}" ;;
    l-*) OP=linear ; M="${part#l-}" ;;
    b-*) OP=bn     ; M="${part#b-}" ;;
    *) echo "[error] bad ACC part: $part" >&2; exit 1 ;;
  esac
  case "$M" in
    f)  ACC_FLAGS="${ACC_FLAGS} --accum-mode-${OP} flat" ;;
    t*) ACC_FLAGS="${ACC_FLAGS} --accum-mode-${OP} two_stage --accum-shift-${OP} ${M#t}" ;;
    *) echo "[error] bad ACC mode: $M" >&2; exit 1 ;;
  esac
done

for BLOCKS in "${BLOCKSS[@]}"; do
  IFS=':' read -r WBLK DXBLK ABLK <<< "$BLOCKS"
for ls in "${LOSS_SETA[@]}"; do
  LOSS="${ls%%:*}"
  IFS=',' read -r -a SETA_ARR <<< "${ls#*:}"
  for SETA in "${SETA_ARR[@]}"; do
    for BITS in "${BITSS[@]}"; do
      IFS=':' read -r W DX ACT <<< "$BITS"
      for SEED in "${SEEDS[@]}"; do
      OUTDIR="out/local/lenet/${LOSS}/accum_${ACC}/lr_${SETA}/weight_block_${WBLK}/gradient_block_${DXBLK}/activation_block_${ABLK}/input_block_${INBLOCK}/weight_bits_${W}/gradient_bits_${DX}/activation_bits_${ACT}/input_bits_${INBITS}"
      mkdir -p "$OUTDIR"
      echo "=== lenet ${LOSS} seta=${SETA} bits=${W}/${DX}/${ACT} acc=${ACC} seed=${SEED} ==="
      /usr/bin/time -v ./train_quant \
        --weight-bits "$W" --gradient-bits "$DX" --activation-bits "$ACT" \
        --weight-block "$WBLK" --gradient-block "$DXBLK" --activation-block "$ABLK" \
        --input-bits "$INBITS" --input-block "$INBLOCK" ${ACC_FLAGS} \
        --loss "$LOSS" --s-eta "$SETA" \
        --batch-size 256 --epochs "$EPOCHS" --val-size 10000 --patience 2 \
        --select-by acc --save-best "$OUTDIR/seed${SEED}_best" \
        --save-scale-stats --stats-interval "$STATS_INTERVAL" \
        --scale-stats-path "$OUTDIR/seed${SEED}_scale.csv" \
        --log-interval 1 --seed "$SEED" \
        2>&1 | tee "$OUTDIR/seed${SEED}.log"
      rc=${PIPESTATUS[0]}
      if [ "$rc" -ne 0 ]; then
        echo "=== FAILED (rc=$rc): lenet ${LOSS} seta=${SETA} bits=${W}/${DX}/${ACT} ===" | tee -a "$OUTDIR/seed${SEED}.log"
      fi
      done
    done
  done
done
done
