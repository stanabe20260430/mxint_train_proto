tmux kill-session -t sweep

tmux new -s sweep
bash submit_sweep_vgg7.sh

pkill -f submit_sweep_vgg7.sh
squeue -h -u $USER -o "%i %j" | awk '$2 ~ /^vgg7/ {print $1}' | xargs -r scancel
scancel -u $USER
