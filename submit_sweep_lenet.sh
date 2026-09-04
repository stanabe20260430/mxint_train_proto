#!/bin/bash
set -eu

JOB="sbatch/lenet_job.sh"

LOSS_SETA=(
  "softmax:11,12"
  "hinge:13,14"
)
SEEDS=($(seq 701 701))
WEIGHTS=(16 8 4 2)
DXS=(16 8 4 2)
ACTS=(16 8 4 2 convs2fc4)
BLOCKS=("32:32:32")
INBITS_ARR=(8)
INBLOCKS=(32)
ACCS=("c-f_l-f_b-f")
CORE=128
MAX_RUNNING=38
POLL=60

echo "[build]"
make clean >/dev/null 2>&1
make train_quant CFLAGS_EXTRA="-march=native -DMXINT_ROUNDING=1" -j 8
mkdir -p build
cp train_quant build/train_quant

count_jobs() { squeue -u "$USER" -h -t RUNNING,PENDING -o "%i" | wc -l; }

submitted=0
for BLK in "${BLOCKS[@]}"; do
   IFS=':' read -r WBLK DXBLK ABLK <<< "$BLK"
   for INBLK in "${INBLOCKS[@]}"; do
   for INB in "${INBITS_ARR[@]}"; do
   for ACC in "${ACCS[@]}"; do
   for ls in "${LOSS_SETA[@]}"; do
    LOSS="${ls%%:*}"
    SETAS="${ls#*:}"
    IFS=',' read -r -a SETA_ARR <<< "$SETAS"
    for W in "${WEIGHTS[@]}"; do
     for DX in "${DXS[@]}"; do
      for ACT in "${ACTS[@]}"; do
       for SETA in "${SETA_ARR[@]}"; do
        for SEED in "${SEEDS[@]}"; do
         while [ "$(count_jobs)" -ge "$MAX_RUNNING" ]; do
           echo "[wait] running/pending >= ${MAX_RUNNING}; sleep ${POLL}s"
           sleep "$POLL"
         done
         echo "[submit] loss=${LOSS} seta=${SETA} seed=${SEED} bits=${W}/${DX}/${ACT}/in${INB} blocks=${WBLK}/${DXBLK}/${ABLK}/in${INBLK} acc=${ACC}"
         sbatch -c "$CORE" "$JOB" "$LOSS" "$SETA" "$SEED" "$W" "$DX" "$ACT" "$WBLK" "$DXBLK" "$ABLK" "$INB" "$INBLK" "$ACC" "$CORE"
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
done

echo "[done] submitted ${submitted} jobs"
