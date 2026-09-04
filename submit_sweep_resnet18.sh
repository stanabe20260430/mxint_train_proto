#!/bin/bash
set -eu

JOB="sbatch/resnet18_job.sh"

LOSS_SETA=(
  "softmax:11"
  "hinge:13"
)
SEEDS=($(seq 701 701))
BITS=("16:16:16" "8:8:8" "4:4:4" "2:2:2")
BLOCKS=("32:32:32")
INBITS_ARR=(8)
INBLOCKS=(32)
ACCS=("c-f_l-f_b-f" "c-t12_l-t12_b-t12")
HALVES=(16)
SMOM="${SMOM:-3}"
MBITS="${MBITS:-0}"
STATS="${STATS:-0}"
BNBITS="${BNBITS:-16}"
BNRECAL="${BNRECAL:-32}"
QUANT_DEBUG="${QUANT_DEBUG:-0}"
LR_SCHEDULE="${LR_SCHEDULE:-plateau}"
LR_PATIENCE="${LR_PATIENCE:-2}"
CORE=128
MAX_RUNNING=38
POLL=60

echo "[build]"
make clean clean-resnet18 >/dev/null 2>&1
DEBUG_FLAG=""
if [ "${QUANT_DEBUG}" -gt 0 ]; then DEBUG_FLAG=" -DQUANT_DEBUG"; fi
make train_quant_resnet18 CFLAGS_EXTRA="-march=native -DMXINT_ROUNDING=1${DEBUG_FLAG}" -j 8
mkdir -p build
cp train_quant_resnet18 build/train_quant_resnet18

count_jobs() { squeue -u "$USER" -h -t RUNNING,PENDING -o "%i" | wc -l; }

submitted=0
for BLK in "${BLOCKS[@]}"; do
   IFS=':' read -r WBLK DXBLK ABLK <<< "$BLK"
   for INBLK in "${INBLOCKS[@]}"; do
   for INB in "${INBITS_ARR[@]}"; do
   for ACC in "${ACCS[@]}"; do
   for HALVE in "${HALVES[@]}"; do
    for ls in "${LOSS_SETA[@]}"; do
      LOSS="${ls%%:*}"
      SETAS="${ls#*:}"
      IFS=',' read -r -a SETA_ARR <<< "$SETAS"
      for b in "${BITS[@]}"; do
        IFS=':' read -r W DX ACT <<< "$b"
        for SETA in "${SETA_ARR[@]}"; do
          for SEED in "${SEEDS[@]}"; do
            while [ "$(count_jobs)" -ge "$MAX_RUNNING" ]; do
              echo "[wait] running/pending >= ${MAX_RUNNING}; sleep ${POLL}s"
              sleep "$POLL"
            done
            echo "[submit] loss=${LOSS} seta=${SETA} seed=${SEED} bits=${W}/${DX}/${ACT}/in${INB} blocks=${WBLK}/${DXBLK}/${ABLK}/in${INBLK} acc=${ACC} mom=${SMOM}/${MBITS} stats=${STATS} bn=${BNBITS} sched=${LR_SCHEDULE}/${LR_PATIENCE}"
            sbatch -c "$CORE" "$JOB" "$LOSS" "$SETA" "$SEED" "$W" "$DX" "$ACT" "$WBLK" "$DXBLK" "$ABLK" "$INB" "$INBLK" "$ACC" "$CORE" "$HALVE" "$LR_SCHEDULE" "$LR_PATIENCE" "$SMOM" "$MBITS" "$STATS" "$BNBITS" "$BNRECAL"
            submitted=$((submitted+1))
            sleep 1
          done
        done
      done
          done
   done
   done
  done
 done
done

echo "[done] submitted ${submitted} jobs"
