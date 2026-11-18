# Phase 3 verification on the course server

From the existing repository on the server, run these commands in the course C shell.
The checked-in programs and expected memories are ready to use.

```csh
git fetch origin
git switch phase3-verification
git pull --ff-only
cd Phase3_for_student
source setup_v1721.csh
make verify-waves
```

If the server has an older Git, use `git checkout phase3-verification` in place of `git switch`.
From bash, after changing directories use `csh -f -c 'source setup_v1721.csh; make verify-waves'`.

`make verify-waves` runs all checks and records the three SimVision databases for the report.
`make verify` runs the same comparisons without recording waves. Each invocation prints its
new `../phase3-evidence/<run>/` directory. It contains `summary.tsv`, per-test logs, memory
dumps, and (for a successful sample) `sample-packets.tsv`. Each rerun gets its own directory.
A failed comparison, timeout, missing file or absent verdict stops the suite with a nonzero
status. Start with the failing test's log. The original `make nic` and `make test` targets
still work independently. The sample comparison in `make test` runs twice by default.

## Collect the report evidence

Use **your NC-Sim run's** values, addresses and times. In the examples below replace
`<run>` with the directory name printed by make. Open each database in SimVision on a
graphical course-server session.

| Guide item | Source and what to show |
| --- | --- |
| R1(a–i) | Open `../phase3-evidence/<run>/waves/nic/nic.shm`. In `tb_cardinal_nic`, display `case_id` as ASCII. The nine rows of `nic.log` give the window for each case. Take one readable capture per case. Mark the sampled rising edge and show the signals that prove the result. |
| R2(a) | Open `../phase3-evidence/<run>/waves/cmp_test/cmp.shm`. Use the first node-0 **inject** time in `cmp_test.log`. Starting before it, show the PC and output-status poll, CPU NIC store (addr 2 and packet), then mesh acceptance (`net_so`, `net_ro`, polarity and packet). Sample assembly gives the loop PCs. |
| R2(b) | In that same run, use the first node-0 **receive** time. Show the arrival on `net_si/net_ri/net_di`, status poll and load at NIC address 0. Follow the **same packet** through the CPU store to MEM[5], including address, data and memory write enable. The sample collects three packets before storing them. |
| R2(c) | Use `sample-packets.tsv` to make a 16-row table. For each node show its three outbound destinations/VCs and its three received packets in observed order at MEM[5..7]. Describe the source, destination and unary hop encoding. The golden comparison permits any arrival order and masks only the received hop byte. |
| R2(d) | Use both run rows for `cmp_test` and `warm_reset`. Explain the five reset edges, memory clear/reload and clearing the per-node done flags in **one simulation**. Warm reset leaves a packet unread and r17 dirty at END. The next run stores its entry r17 and input status in MEM[40..41], both expected zero. |
| R2(e) | `processor` is the original Phase 2 backward_loop image and golden memory on all 16 CPUs. Report MEM[128] and MEM[129], the word comparison and node completion. Explain CPU NIC-region decode, mutually exclusive enables, and selection of the registered NIC load at writeback. |
| R2(f) | `routes` and `routes_flip` each cover 16 × 15 directed pairs and distances 1–6. Each node interleaves a send and a receive in each XOR-partner round. The second run inverts every packet VC. Reserved bits, a deliberately opaque source field, and payload are checked. MEM[64..78] is compared as a multiset. `tight` also sends four distinct packets per pair. |
| R2(g) | `map` checks both reset statuses, four sentinels at MEM[0..3], 0x4000/0x8000-region data reads and writes, the 0xF100–0xF103 NIC aliases, and writes to all three read-only registers. Compare the observed and expected words at MEM[24..25] and [40..47]. The bus monitor independently checks for overlapping enables. |
| R2(h) | In `burst` and `paced`, even nodes each send ten distinct VC1 packets to their odd neighbor. Odd nodes delay once or before every receive. Compare MEM[64..73] of the receivers, endpoint counts and node-0 blocked-edge/full-status-poll counts. Open `../phase3-evidence/<run>/waves/burst/cmp.shm` and use the **blocked eligible packet** time in `burst.log` to show the pending packet, low router ready, CPU status polling, then eventual acceptance. |
| R2(i) | `tight` uses complementary irregular send/receive schedules at opposite nodes, both VCs, and an immediately adjacent status load and branch. Show the instruction pair from the commented fill, four packets per endpoint, MEM[64..67], and the comparison result. |

For the NIC figures, (a) shows reset, both status reads and ready/send. (b) shows the unblocked
transfer. (c) shows a held packet and one acceptance after release. (d) and (e) show a free-slot
store and a rejected overwrite; display both input words and the one eventually delivered.
(f) and (g) show loads from a full and empty input slot; an empty read has unspecified data,
so show the ready/status state. (h) includes a CPU store alongside an incoming packet and an
edge with both router directions transferring. (i) shows VC0 accepted at polarity 1 and VC1
at polarity 0. Include the clock in every figure and explain each marked edge in one or two sentences.

For CMP signals use `tb_cmp.CMP.node0_*` and `tb_cmp.CLK`. Use `node0_addr_nic`,
`node0_nicEn`, `node0_nicWrEn`, `node0_din_nic` and `node0_dout_nic` on the CPU side;
`node0_net_*` and `node0_polarity` on the mesh side. `tb_cmp.CMP.nic0.output_buffer_full`
shows when the sender has a queued packet. Set buses to hex. Split a long transaction into
two labeled windows if the values would otherwise be unreadable.

## Reproduce one case and prepare the submission

For example, inside the configured course shell:

```csh
make test RUNS=1 PREFIX=tests/burst EXPECTED=tests/burst_exp UNORDERED= 'CHECK_ARGS=+COUNTS=10,0,0,10 +CHECK_BLOCK'
```

The sample writes 32 words per node to the submission's `dumps/` while comparing all 128
course-expected words per node. The suite keeps full 256-word custom dumps in the evidence
directory and a separate first-pass dump for reset tests. The grader's design, memory
models and DUT instance interfaces are preserved. Program generation is optional:
`python3 tests/generate.py` reproduces the files in a full repository checkout.

After saving figure screenshots, put your own `report.pdf` in this directory, run
`make clean`, and zip the directory contents using the submission guide's team filename.
The evidence directory is a sibling outside the submission root. Extract the final ZIP to
an empty directory and run `make test` and `make nic` there before submitting.
