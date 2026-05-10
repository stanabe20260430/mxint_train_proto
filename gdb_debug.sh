make clean && make CFLAGS_EXTRA="-g -O0 -DQUANT_BITS=8 -DQUANT_DEBUG -DMX_BLOCK_SIZE=8" -j8
gdb --args ./train_quant --seed 101 \
    --model-variant w16_dx8_conv12conv24fc4 \
    --epochs 1 --batch-size 256 --s-eta 13 --log-interval 1

---
(gdb) break main
Breakpoint 1 at 0x21c0d: file train/train_quant.c, line 21.
(gdb) run
Starting program: /home/tkb/work/mxint_train_proto/train_quant --seed 101 --model-variant w16_dx8_conv12conv24fc4 --epochs 1 --batch-size 256 --s-eta 13 --log-interval 1

This GDB supports auto-downloading debuginfo from the following URLs:
  <https://debuginfod.ubuntu.com>
Enable debuginfod for this session? (y or [n]) y
Debuginfod has been enabled.
To make this setting permanent, add 'set debuginfod enabled on' to .gdbinit.
Downloading separate debug info for system-supplied DSO at 0x7ffff7fc3000
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".

Breakpoint 1, main (argc=13, argv=0x7fffffffdca8) at train/train_quant.c:21
21	{
(gdb) n
23	    parse_args(argc, argv, &args);
(gdb) p args
$1 = {common = {max_batches = 4160511328, seed = 157536133, batch_size = 63084, epochs = 32767, log_interval = 1,
    data_dir = 0xde4466bea7fef000 <error: Cannot access memory at address 0xde4466bea7fef000>, s_eta_init = 0, val_size = 0,
    patience = 1, save_best = 0x7fffffffd8d0 "\220\333\377\377\377\177"}, save_stats = -136817258, stats_interval = 32767,
  s_wd = 8388608, save_interval = 0, resume_path = 0x7ffff7c98914 <__lll_elision_init+132> "\213\005\026\316\026",
  dump_raw_bins_dir = 0x3ffffd8d0 <error: Cannot access memory at address 0x3ffffd8d0>, dump_start = 2818502656,
  dump_end = 3729024702, loss_type = (unknown: 0xe59e301c), model_variant = 59923}
(gdb) n
24	    if (validate_args(&args) != 0) return 1;
(gdb) p argv[0]
quit
$2 = 0x7fffffffe06e "/home/tkb/work/mxint_train_proto/train_quant"
(gdb) exit

A debugging session is active.

	Inferior 1 [process 26679] will be killed.

Quit anyway? (y or n) y

