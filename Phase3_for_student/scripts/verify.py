"""Run the course make targets and retain each invocation's evidence outside the ZIP root."""
import argparse
import csv
import datetime
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Counts are (even node sends, receives, odd node sends, receives).
# An empty range keeps memory comparison ordered.
CASES = (
    ("cmp_test", "R2(a-d)", 2, "5:7", "3,3,3,3", "Sample packets in MEM[5..7]; same simulation twice"),
    ("warm_reset", "R2(d)", 2, "", "1,1,1,1", "MEM[40..41] = 0 after reset; r17 and input NIC dirty at previous END"),
    ("processor", "R2(e)", 1, "", "0,0,0,0", "Phase 2 backward_loop; MEM[128]=1, MEM[129]=0"),
    ("routes", "R2(f)", 1, "64:78", "15,15,15,15", "All 240 directed pairs; MEM[64..78] matches packet multiset"),
    ("routes_flip", "R2(f)", 1, "64:78", "15,15,15,15", "Same pairs on opposite VCs; only hop byte masked"),
    ("map", "R2(g)", 1, "", "1,1,1,1", "Sentinels MEM[0..3], aliases MEM[24..25], status and data MEM[40..47]"),
    ("burst", "R2(h)", 1, "", "10,0,0,10", "10 same-VC packets per pair in MEM[64..73]; initial receive delay"),
    ("paced", "R2(h)", 1, "", "10,0,0,10", "10 same-VC packets per pair in MEM[64..73]; delay before every receive"),
    ("tight", "R2(f,i)", 1, "64:67", "4,4,4,4", "Repeated destinations; irregular sends and tight polls; MEM[64..67]"),
)
NIC_CASES = ("Reset and status", "Unblocked send", "Blocked send and release",
             "Store into free buffer", "Store into occupied buffer", "Full input read",
             "Empty input read", "Simultaneous transfer", "Both VC phases")


def invoke(args, logfile):
    print("Running " + " ".join(args[:2]) + " -> " + str(logfile), flush=True)
    with logfile.open("w") as log:
        proc = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT)
    output = logfile.read_text(errors="replace")
    if proc.returncode or "TEST FAILED" in output:
        raise RuntimeError("simulation or compile failed; see " + str(logfile))
    return output


def check_wave(path):
    if not path.is_dir() or not any(f.is_file() and f.stat().st_size for f in path.rglob("*")):
        raise RuntimeError("missing waveform database " + str(path))


def read_dump(path):
    rows = {}
    for line in path.read_text().splitlines():
        match = re.fullmatch(r"Memory location #\s*(\d+)\s*:\s*([0-9a-fA-FxX]{16})\s*", line)
        if not match:
            raise ValueError("invalid dump row in " + str(path))
        rows[int(match[1])] = match[2].lower()
    return rows


def sample_packets(evidence):
    """Join expected and observed packets by identity, retaining actual receive order."""
    with (evidence / "sample-packets.tsv").open("w", newline="") as out:
        writer = csv.writer(out, delimiter="\t")
        writer.writerow(("node", "role", "MEM", "vc", "destination_x", "destination_y",
                         "hop_byte_hex", "source_field", "expected_hex", "observed_hex"))
        for node in range(16):
            filename = f"cmp_test.dmem.{node}.dump"
            actual = read_dump(evidence / "dumps" / filename)
            expected = read_dump(Path(f"expected_dmem.{node}.dump"))
            if set(actual) != set(range(32)):
                raise RuntimeError("sample submission dump must contain precisely words 0..31")
            for slot in (0, 1, 2, 5, 6, 7):
                value = actual[slot]
                word = int(value, 16)
                if slot < 3:
                    role, wanted = "sent", expected[slot]
                else:
                    role, wanted = "received", value[:2] + "xx" + value[4:]
                    if wanted not in [expected[i] for i in (5, 6, 7)]:
                        raise RuntimeError(f"unmatched sample packet at node {node} word {slot}")
                writer.writerow((node, role, slot, word >> 63, (word >> 60) & 3, (word >> 58) & 3,
                                 value[2:4], (word >> 32) & 65535, wanted, value))
    Path("dumps").mkdir(exist_ok=True)
    for node in range(16):
        filename = f"cmp_test.dmem.{node}.dump"
        shutil.copyfile(evidence / "dumps" / filename, Path("dumps") / filename)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--waves", action="store_true")
    waves = parser.parse_args().waves
    root = Path("../phase3-evidence")
    root.mkdir(exist_ok=True)
    # Use paths relative to the framework for NC-Sim plusargs.
    evidence = Path(os.path.relpath(tempfile.mkdtemp(dir=str(root),
                         prefix=datetime.datetime.now().strftime("%Y%m%d-%H%M%S-"))))
    print("Evidence directory: " + str(evidence), flush=True)
    scope = "NIC"
    with (evidence / "summary.tsv").open("w", newline="") as out:
        table = csv.writer(out, delimiter="\t")
        table.writerow(("rubric", "test", "run", "check", "observed", "result"))
        try:
            target = "nicwave" if waves else "nic"
            text = invoke(["make", target, "WAVE_DIR=" + str(evidence / "waves" / "nic")],
                          evidence / "nic.log")
            for letter, purpose in zip("abcdefghi", NIC_CASES):
                match = re.search(r"^NIC CASE R1\(" + letter + r"\) PASS\s+([^\n]+)", text, re.M)
                if not match:
                    raise RuntimeError("missing NIC case " + letter)
                table.writerow((f"R1({letter})", "nic", 1, purpose, match[1], "PASS"))
            if not re.search(r"^NIC TEST PASSED\s*$", text, re.M):
                raise RuntimeError("missing NIC verdict")
            if waves:
                check_wave(evidence / "waves/nic/nic.shm")
            for name, rubric, runs, unordered, counts, purpose in CASES:
                scope = name
                sample = name == "cmp_test"
                prefix = name if sample else "tests/" + name
                expected = "expected_dmem" if sample else prefix + "_exp"
                blocked = name in ("burst", "paced")
                record = waves and (sample or name == "burst")
                args = ["make", "cmpwave" if record else "test", "PREFIX=" + prefix,
                        "EXPECTED=" + expected, "UNORDERED=" + unordered, f"RUNS={runs}",
                        "CHECK_ARGS=+KEEP_PASSES +COUNTS=" + counts + (" +CHECK_BLOCK" if blocked else ""),
                        "DUMP_DIR=" + str(evidence / "dumps"), "WAVE_DIR=" + str(evidence / "waves" / name)]
                text = invoke(args, evidence / (name + ".log"))
                if f"TEST PASSED: {prefix} ({runs} runs)" not in text:
                    raise RuntimeError("missing final verdict for " + name)
                for run in range(1, runs + 1):
                    words = 2048 if sample else 4096
                    match = re.search(rf"^RUN {run} words={words} mismatches=0 blocked_edges=(\d+) full_polls=(\d+)", text, re.M)
                    if not match:
                        raise RuntimeError(f"missing complete comparison for {name} run {run}")
                    table.writerow((rubric, name, run, purpose,
                                    f"{words} words; 0 mismatches; blocked edges {match[1]}; full polls {match[2]}", "PASS"))
                if record:
                    check_wave(evidence / "waves" / name / "cmp.shm")
                if sample:
                    sample_packets(evidence)
                print("PASS " + name, flush=True)
        except (OSError, ValueError, RuntimeError) as err:
            table.writerow(("", scope, "", "", str(err), "FAIL"))
            print("FAIL " + scope + " — " + str(err), file=sys.stderr)
            return 1
    print("All checks passed. Report table: " + str(evidence / "summary.tsv"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
