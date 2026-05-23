#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import io
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Force UTF-8 output on Windows to avoid cp1252 encode errors
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
"""
run_tests.py - Verilog Simulation Test Runner
=============================================
Supports Icarus Verilog (iverilog/vvp) and Vivado Simulator (xvlog/xelab/xsim).

Directory Convention
--------------------
Each test case lives in its own subfolder under the testbench root:

    testbench/
    └── test_001/
        ├── PC_tb.v          <-- testbench (top-level module)
        ├── expected.txt     <-- gold file (exact expected stdout)
        └── (optional) extra_src.v  <-- additional per-test sources

Usage examples
--------------
  # Auto-detect simulator, use src/ as source directory
  python run_tests.py --src src --testbench testbench

  # Force Icarus Verilog
  python run_tests.py --src src --testbench testbench --sim icarus

  # Force Vivado, point to a specific Vivado bin
  python run_tests.py --src src --testbench testbench --sim vivado --vivado-bin "C:/Xilinx/Vivado/2024.2/bin"

  # Run only specific test cases
  python run_tests.py --src src --testbench testbench --filter test_001 test_002

  # Loose comparison (ignore blank lines and leading/trailing whitespace)
  python run_tests.py --src src --testbench testbench --loose
"""


# ─────────────────────────────────────────────
# ANSI colour helpers (no external libs needed)
# ─────────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

def _colour(text: str, code: str) -> str:
    """Return coloured text if stdout is a real terminal."""
    if sys.stdout.isatty():
        return f"{code}{text}{RESET}"
    return text

def pass_tag()  -> str: return _colour("[PASS]", GREEN + BOLD)
def fail_tag()  -> str: return _colour("[FAIL]", RED   + BOLD)
def error_tag() -> str: return _colour("[ERROR]", RED  + BOLD)
def skip_tag()  -> str: return _colour("[SKIP]", YELLOW + BOLD)
def info(msg)         : print(_colour(msg, CYAN))
def header(msg)       : print(_colour(f"\n{'='*60}\n{msg}\n{'='*60}", BOLD))


# ─────────────────────────────────────────────
# Simulator auto-detection
# ─────────────────────────────────────────────
VIVADO_COMMON_PATHS = [
    r"C:\Xilinx\Vivado\2025.2\bin",
    r"C:\Xilinx\Vivado\2025.1\bin",
    r"C:\Xilinx\Vivado\2024.2\bin",
    r"C:\Xilinx\Vivado\2024.1\bin",
    r"C:\Xilinx\Vivado\2023.2\bin",
    r"C:\Xilinx\Vivado\2023.1\bin",
]

def _find_vivado_bin() -> str | None:
    """Locate the Vivado bin directory automatically."""
    # 1. Already on PATH?
    if shutil.which("xvlog") or shutil.which("xvlog.bat"):
        return None  # Use whatever is on PATH
    # 2. Known install locations
    for p in VIVADO_COMMON_PATHS:
        if Path(p).is_dir():
            return p
    return None

def _cmd(name: str, vivado_bin: str | None) -> str:
    """Return the full command path for a Vivado tool."""
    if vivado_bin:
        candidate = Path(vivado_bin) / f"{name}.bat"
        if candidate.exists():
            return str(candidate)
        return str(Path(vivado_bin) / name)
    return name

def detect_simulator() -> tuple[str, str | None]:
    """Return ('icarus'|'vivado', vivado_bin_or_None)."""
    if shutil.which("iverilog"):
        return "icarus", None
    vivado_bin = _find_vivado_bin()
    xvlog_path = _cmd("xvlog", vivado_bin)
    if shutil.which(xvlog_path) or Path(xvlog_path).exists():
        return "vivado", vivado_bin
    return "none", None


# ─────────────────────────────────────────────
# Subprocess helpers
# ─────────────────────────────────────────────
def _run(cmd: list[str], cwd: str | None = None, timeout: int = 120) -> tuple[int, str, str]:
    """Run a command and return (returncode, stdout, stderr)."""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result.returncode, result.stdout, result.stderr
    except FileNotFoundError as exc:
        return -1, "", f"Command not found: {exc}"
    except subprocess.TimeoutExpired:
        return -1, "", f"Command timed out after {timeout}s: {' '.join(cmd)}"


# ─────────────────────────────────────────────
# Icarus Verilog flow
# ─────────────────────────────────────────────
def run_icarus(src_files: list[str], tb_file: str, work_dir: str,
               top_module: str) -> tuple[bool, str, str]:
    """
    Compile and simulate with Icarus Verilog.

    Returns (success, stdout_log, error_message).
    """
    vvp_out = str(Path(work_dir) / "sim.vvp")

    # ── 1. Compile ──────────────────────────────────
    compile_cmd = ["iverilog", "-o", vvp_out, "-g2005"] + src_files + [tb_file]
    rc, _, stderr = _run(compile_cmd)
    if rc != 0:
        return False, "", f"Compilation failed:\n{stderr}"

    # ── 2. Simulate ─────────────────────────────────
    rc, stdout, stderr = _run(["vvp", vvp_out])
    if rc != 0:
        return False, stdout, f"Simulation failed:\n{stderr}"

    return True, stdout, ""


# ─────────────────────────────────────────────
# Vivado Simulator flow
# ─────────────────────────────────────────────
def run_vivado(src_files: list[str], tb_file: str, work_dir: str,
               top_module: str, vivado_bin: str | None) -> tuple[bool, str, str]:
    """
    Compile (xvlog) → Elaborate (xelab) → Simulate (xsim).

    Returns (success, stdout_log, error_message).
    """
    xvlog = _cmd("xvlog", vivado_bin)
    xelab = _cmd("xelab", vivado_bin)
    xsim  = _cmd("xsim",  vivado_bin)
    snap  = f"{top_module}_sim"

    # ── 1. xvlog ────────────────────────────────────
    all_v = src_files + [tb_file]
    rc, stdout, stderr = _run([xvlog, "--nolog", "-sv"] + all_v, cwd=work_dir)
    if rc != 0:
        return False, "", f"xvlog failed:\n{stdout}\n{stderr}"

    # ── 2. xelab ────────────────────────────────────
    rc, stdout, stderr = _run(
        [xelab, "--nolog", "--debug", "typical", top_module, "-s", snap],
        cwd=work_dir,
    )
    if rc != 0:
        return False, "", f"xelab failed:\n{stdout}\n{stderr}"

    # ── 3. xsim ─────────────────────────────────────
    rc, stdout, stderr = _run(
        [xsim, "--nolog", snap, "-R"],
        cwd=work_dir,
    )
    if rc != 0:
        return False, stdout, f"xsim failed:\n{stderr}"

    return True, stdout, ""


# ─────────────────────────────────────────────
# Output comparison
# ─────────────────────────────────────────────
def clean_log(text: str, sim: str) -> str:
    """Filter out simulator-specific noise."""
    cleaned = []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue

        if sim == "vivado":
            # Ignore Vivado noise
            if line.startswith("****** xsim"):
                continue
            if line.startswith("**** SW Build"):
                continue
            if line.startswith("**** IP Build"):
                continue
            if line.startswith("**** SharedData Build"):
                continue
            if line.startswith("**** Start of session"):
                continue
            if line.startswith("** Copyright"):
                continue
            if line.startswith("source xsim.dir"):
                continue
            if line.startswith("# xsim"):
                continue
            if line.startswith("Time resolution"):
                continue
            if line == "run -all":
                continue
            if line.startswith("Vivado Simulator"):
                continue
            if line.startswith("Copyright"):
                continue
            if line.startswith("Time Resolution"):
                continue
            if "Simulator is doing nothing" in line:
                continue
            if "$finish called at time" in line:
                continue
            if line.startswith("INFO:") or line.startswith("WARNING:"):
                continue
            if line.startswith("xsim%"):
                continue
            if line.startswith("exit"):
                continue
        elif sim == "icarus":
            # Ignore Icarus noise
            if line.startswith("VCD info:"):
                continue
            if "LXT2 info:" in line:
                continue
            if "FST info:" in line:
                continue
            if "$finish called at time" in line:
                continue

        cleaned.append(line)
    return "\n".join(cleaned)


def _normalise(text: str, loose: bool) -> list[str]:
    """
    Split text into lines for comparison.
    If loose=True: strip whitespace, drop blank lines.
    """
    lines = text.splitlines()
    if loose:
        lines = [ln.strip() for ln in lines]
        lines = [ln for ln in lines if ln]
    return lines


def compare_output(actual: str, expected: str, loose: bool) -> tuple[bool, str]:
    """
    Compare actual vs expected simulation output line by line.

    Returns (passed, diff_text).
    """
    act_lines = _normalise(actual, loose)
    exp_lines = _normalise(expected, loose)

    if act_lines == exp_lines:
        return True, ""

    diff_lines = []
    # Generate detailed line-by-line mismatch report
    for i, (act, exp) in enumerate(zip(act_lines, exp_lines), 1):
        if act != exp:
            diff_lines.append(f"Line {i}: Expected: '{exp}'")
            diff_lines.append(f"        Actual:   '{act}'")

    if len(act_lines) > len(exp_lines):
        for i in range(len(exp_lines), len(act_lines)):
            diff_lines.append(f"Line {i+1}: Extra actual output: '{act_lines[i]}'")
    elif len(exp_lines) > len(act_lines):
        for i in range(len(act_lines), len(exp_lines)):
            diff_lines.append(f"Line {i+1}: Missing expected output: '{exp_lines[i]}'")

    return False, "\n".join(diff_lines)


# ─────────────────────────────────────────────
# Single test runner
# ─────────────────────────────────────────────
def run_test(test_dir: Path, src_files: list[str],
             sim: str, vivado_bin: str | None,
             loose: bool) -> dict:
    """
    Execute one test case.

    Returns a result dict with keys:
        name, status ('PASS'|'FAIL'|'ERROR'|'SKIP'), message, diff
    """
    name = test_dir.name
    result = {"name": name, "status": "PASS", "message": "", "diff": ""}

    # ── Locate testbench ────────────────────────────
    tb_files = list(test_dir.glob("*.v")) + list(test_dir.glob("*.sv"))
    if not tb_files:
        result["status"] = "SKIP"
        result["message"] = "No Verilog testbench file found in test directory."
        return result

    tb_files = [f.resolve() for f in tb_files]
    tb_file = str(tb_files[0])
    top_module = tb_files[0].stem      # e.g. "PC_tb"

    # ── Locate expected output ──────────────────────
    expected_file = test_dir / "expected.txt"
    if not expected_file.exists():
        result["status"] = "SKIP"
        result["message"] = "No expected.txt gold file found — skipping comparison."
        return result

    expected_text = expected_file.read_text(encoding="utf-8-sig", errors="replace")

    # Additional .v sources bundled with the test (besides testbench)
    extra_src = [str(f) for f in tb_files[1:]]
    all_src = src_files + extra_src

    # ── Run in a temporary work directory ──────────
    with tempfile.TemporaryDirectory(prefix=f"vsim_{name}_") as work_dir:
        # Clean up any residual Vivado folders from current directory to prevent snapshot conflicts
        for d in ["xsim.dir", ".Xil"]:
            path = Path(d)
            if path.exists() and path.is_dir():
                shutil.rmtree(path, ignore_errors=True)

        if sim == "icarus":
            ok, stdout, err_msg = run_icarus(all_src, tb_file, work_dir, top_module)
        else:
            ok, stdout, err_msg = run_vivado(all_src, tb_file, work_dir, top_module, vivado_bin)

        if not ok:
            result["status"] = "ERROR"
            result["message"] = err_msg
            return result

        passed, diff_text = compare_output(clean_log(stdout, sim), clean_log(expected_text, sim), loose)
        if passed:
            result["status"] = "PASS"
        else:
            result["status"] = "FAIL"
            result["diff"] = diff_text

    return result


# ─────────────────────────────────────────────
# Summary printer
# ─────────────────────────────────────────────
def print_summary(results: list[dict]) -> int:
    """Print the final summary table. Returns number of failures."""
    header("SIMULATION RESULTS")
    failures = 0

    for r in results:
        name    = r["name"]
        status  = r["status"]
        message = r.get("message", "")
        diff    = r.get("diff", "")

        if status == "PASS":
            print(f"  {pass_tag()}  {name}")
        elif status == "FAIL":
            failures += 1
            print(f"  {fail_tag()}  {name}")
            if diff:
                print(_colour(f"\n--- DIFF REPORT FOR [{name}] ---", YELLOW + BOLD))
                for line in diff.splitlines():
                    if "Expected:" in line or "Missing" in line:
                        print(_colour(f"    {line}", GREEN))
                    elif "Actual:" in line or "Extra" in line:
                        print(_colour(f"    {line}", RED))
                    else:
                        print(f"    {line}")
                print()
        elif status == "ERROR":
            failures += 1
            print(f"  {error_tag()}  {name}")
            print(_colour(f"    {message}", RED))
        elif status == "SKIP":
            print(f"  {skip_tag()}  {name}  —  {message}")

    total  = len(results)
    passed = sum(1 for r in results if r["status"] == "PASS")
    skipped = sum(1 for r in results if r["status"] == "SKIP")

    header(f"Summary: {passed}/{total - skipped} passed  |  {failures} failed  |  {skipped} skipped")
    return failures


# ─────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="run_tests.py",
        description="Verilog Simulation Test Runner — Icarus or Vivado",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument(
        "--src", required=True,
        help="Directory containing Verilog source files (e.g. src/).",
    )
    p.add_argument(
        "--testbench", required=True,
        help="Root directory containing test_XXX sub-folders.",
    )
    p.add_argument(
        "--sim", choices=["icarus", "vivado", "auto"], default="auto",
        help="Simulator to use. Default: auto-detect.",
    )
    p.add_argument(
        "--vivado-bin",
        help="Path to Vivado bin directory (e.g. C:/Xilinx/Vivado/2024.2/bin). "
             "Auto-detected when omitted.",
    )
    p.add_argument(
        "--filter", nargs="+", metavar="TEST",
        help="Run only specific test case names (e.g. test_001 test_003).",
    )
    p.add_argument(
        "--loose", action="store_true",
        help="Loose comparison: ignore leading/trailing whitespace and blank lines.",
    )
    p.add_argument(
        "--timeout", type=int, default=120,
        help="Per-step timeout in seconds. Default: 120.",
    )
    return p


def main():
    args = build_parser().parse_args()

    src_dir        = Path(args.src)
    testbench_root = Path(args.testbench)

    # ── Validate paths ──────────────────────────────
    if not src_dir.is_dir():
        print(f"{error_tag()} Source directory not found: {src_dir}")
        sys.exit(1)
    if not testbench_root.is_dir():
        print(f"{error_tag()} Testbench directory not found: {testbench_root}")
        sys.exit(1)

    # ── Collect source files ────────────────────────
    src_files = [str(f.resolve()) for f in sorted(src_dir.glob("*.v"))]
    src_files += [str(f.resolve()) for f in sorted(src_dir.glob("*.sv"))]
    if not src_files:
        print(f"{error_tag()} No .v / .sv files found in {src_dir}")
        sys.exit(1)

    # ── Collect test directories ────────────────────
    test_dirs = sorted([d for d in testbench_root.iterdir() if d.is_dir()])
    if args.filter:
        test_dirs = [d for d in test_dirs if d.name in args.filter]
    if not test_dirs:
        print(f"{error_tag()} No test directories found under {testbench_root}")
        sys.exit(1)

    # ── Resolve simulator ───────────────────────────
    if args.sim == "auto":
        sim, vivado_bin = detect_simulator()
        if sim == "none":
            print(f"{error_tag()} No simulator found. Install Icarus Verilog or Vivado, "
                  "or use --sim to specify one.")
            sys.exit(1)
        info(f"Auto-detected simulator: {sim}")
    else:
        sim = args.sim
        vivado_bin = args.vivado_bin

    if sim == "vivado" and not vivado_bin:
        vivado_bin = _find_vivado_bin()
    if sim == "vivado" and vivado_bin:
        info(f"Vivado bin: {vivado_bin}")

    # ── Run all tests ───────────────────────────────
    header(f"Running {len(test_dirs)} test(s) with [{sim.upper()}]")
    info(f"Sources : {src_dir}  ({len(src_files)} file(s))")
    info(f"Tests   : {testbench_root}")

    results = []
    for test_dir in test_dirs:
        print(f"\n  Running {_colour(test_dir.name, CYAN)} ...", end=" ", flush=True)
        r = run_test(test_dir, src_files, sim, vivado_bin, args.loose)
        tag = {"PASS": pass_tag(), "FAIL": fail_tag(),
               "ERROR": error_tag(), "SKIP": skip_tag()}.get(r["status"], r["status"])
        print(tag)
        results.append(r)

    # ── Summary ─────────────────────────────────────
    failures = print_summary(results)
    sys.exit(0 if failures == 0 else 1)


if __name__ == "__main__":
    main()
