"""Black-box output-boundary contract against the actual packaged Windows EXE.

Red uses only a newly owned E: sentinel directory. Invalid green pixel cases
use headless mode so a regressed guard cannot write res:// or user:// output:
the existing pixel fixture rejects headless before any capture file access.
The verification marker still proves that loading a fixture is a failure.
Legal green uses real GL and requires a native image plus the original PASS.
This standalone CLI does not add a Python unittest class or change its count.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
BASELINE = "f208911d8b6712407c68dbac2a2b5bd675d3e211"
OWNED = (ROOT / ".godot/issue31-rc3",
    Path("E:/Projects/game_hundouluo_codex_artifacts/v0.1.1-rc.3"))
DIAGNOSTIC = re.compile(r"^\s*(?:ERROR:|SCRIPT ERROR:|WARNING:)", re.MULTILINE)
MARKER = "RC3_RENDER_VERIFICATION "


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT,
        encoding="utf-8").rstrip("\r\n")


def source_state():
    return dict(head=git("rev-parse", "HEAD"),
        status=git("status", "--porcelain=v1", "--untracked-files=all").splitlines(),
        normalized_diff=git("diff", "--name-only").splitlines(),
        staged_diff=git("diff", "--cached", "--name-only").splitlines())


def snapshot(path):
    if not path.exists():
        return dict(exists=False)
    info = path.stat()
    return dict(exists=True, directory=path.is_dir(), mtime_ns=info.st_mtime_ns,
        size=info.st_size, sha256=sha(path) if path.is_file() else None,
        children=sorted(p.relative_to(path).as_posix() for p in path.rglob("*"))
            if path.is_dir() else None)


def decoded(value):
    return value.decode("utf-8", errors="replace") if isinstance(value, bytes) else (value or "")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", choices=("red", "red-matrix", "green"), required=True)
    parser.add_argument("--executable", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--expect-commit", help="Required clean HEAD/build for formal green")
    args = parser.parse_args()
    start = source_state()
    executable = args.executable.resolve()
    build_info = (executable.parent / "BUILD_INFO.txt").read_text(encoding="utf-8-sig")
    match = re.search(r"^source_commit=([0-9a-f]{40})\s*$", build_info, re.MULTILINE)
    if not match:
        raise ValueError("EXE requires adjacent source_commit BUILD_INFO")
    build_commit = match[1]
    if args.phase in ("red", "red-matrix") and build_commit != BASELINE:
        raise ValueError("Safe red is only the preserved f208 Windows package")
    if args.phase == "green" and (not args.expect_commit or args.expect_commit == BASELINE
        or build_commit != args.expect_commit or start["head"] != args.expect_commit
        or start["status"]):
        raise ValueError("Formal green requires new matching clean HEAD and packaged EXE")
    output = args.output.resolve()
    if output.drive.upper() != "E:" or output.exists() or not output.parent.is_dir() \
        or not any(output.is_relative_to(scope.resolve()) for scope in OWNED):
        raise ValueError("Harness report must be a new owned E: leaf with an existing parent")
    output.mkdir()
    logs = output / "logs"
    logs.mkdir()
    records = []

    def run(name, user_args, expected, targets=(), sentinels=(), headless=True, default=False):
        before = {str(path): snapshot(path) for path in (*targets, *sentinels)}
        command = [str(executable), "--rendering-method", "gl_compatibility",
            "--fixed-fps", "60", "--log-file", str(logs / (name + "-godot.log"))]
        if headless:
            command.append("--headless")
        if default:
            command += ["--quit-after", "90"]
        else:
            command += ["--", *user_args]
        began = time.monotonic()
        timeout, exit_code = None, None
        try:
            result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                encoding="utf-8", errors="replace", timeout=60)
            stdout, stderr, exit_code = result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired as error:
            stdout, stderr, timeout = decoded(error.stdout), decoded(error.stderr), 60
        (logs / (name + "-stdout.log")).write_text(stdout, encoding="utf-8")
        (logs / (name + "-stderr.log")).write_text(stderr, encoding="utf-8")
        log = stdout + stderr
        diagnostics = [line for line in log.splitlines() if DIAGNOSTIC.match(line)]
        after = {str(path): snapshot(path) for path in (*targets, *sentinels)}
        marker = MARKER in log
        untouched = before == after
        passed = timeout is None and exit_code == expected and not diagnostics
        if expected == 1:
            passed = passed and not marker and untouched and "FAIL:" in log
        elif default:
            passed = passed and not marker
        else:
            pngs = sorted(targets[0].glob("frames/*.png"))
            # PNG IHDR dimensions, independent of Pillow/the rendering fixture.
            native = bool(pngs) and all(p.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n"
                and int.from_bytes(p.read_bytes()[16:20], "big") == 640
                and int.from_bytes(p.read_bytes()[20:24], "big") == 360 for p in pngs)
            passed = passed and marker and bool(re.search(r"^PASS(?:\s|:)", log, re.MULTILINE)) and native
        record = dict(name=name, argv=command, exit=exit_code, expected_exit=expected,
            timeout_seconds=timeout, diagnostics=diagnostics, fixture_marker=marker,
            before=before, after=after, untouched=untouched, passed=passed,
            wall_seconds=round(time.monotonic()-began, 3), headless=headless,
            stdout_sha256=sha(logs / (name + "-stdout.log")),
            stderr_sha256=sha(logs / (name + "-stderr.log")))
        records.append(record)
        print(f"{name}: exit={exit_code} expected={expected} marker={marker} untouched={untouched} passed={passed}", flush=True)
        return record

    pixel = ["--rc3-render-verification=pixels", "--ticks=1"]
    existing = output / "existing"
    existing.mkdir()
    sentinel = existing / "trace.json"
    sentinel.write_bytes(b'{"owned_boundary_sentinel":"DO_NOT_OVERWRITE"}\n')
    if args.phase == "red":
        record = run("existing-output-red", [*pixel, "--out=" + str(existing)],
            1, (existing,), (sentinel,), headless=False)
        reproduced = record["exit"] == 0 and record["fixture_marker"] \
            and record["before"][str(sentinel)]["sha256"] != record["after"][str(sentinel)]["sha256"]
    else:
        reproduced = None
        candidates = output / "candidates"
        candidates.mkdir()
        candidate = lambda name: candidates / name
        file_target = output / "existing-file"
        file_target.write_bytes(b"owned-file-sentinel\n")
        dot_parent = candidate("dot-parent")
        dot_parent.mkdir()
        outside_parent = ROOT / ".godot" / ("rc3-boundary-outside-" + uuid.uuid4().hex)
        outside_parent.mkdir()
        link_target = candidate("link-target")
        link_target.mkdir()
        linked = candidate("linked-parent")
        quote = lambda value: "'" + str(value).replace("'", "''") + "'"
        junction_argv = ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command",
            "New-Item -ItemType Junction -Path " + quote(linked) + " -Target " + quote(link_target)]
        junction = subprocess.run(junction_argv, capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=30, creationflags=subprocess.CREATE_NO_WINDOW)
        (logs / "create-junction.log").write_text(junction.stdout + junction.stderr, encoding="utf-8")
        if junction.returncode or not (linked.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT):
            raise ValueError("Linked-parent test requires a real newly owned reparse directory")
        (output / "junction-setup.json").write_text(json.dumps(dict(argv=junction_argv,
            exit=junction.returncode, link=str(linked), target=str(link_target)), indent=2), encoding="utf-8")
        invalid = [
            ("missing", [], (), ()),
            ("empty", ["--out="], (), ()),
            ("bare", ["--out"], (), ()),
            ("duplicate", ["--out="+str(candidate("duplicate-a")), "--out="+str(candidate("duplicate-b"))],
                (candidate("duplicate-a"), candidate("duplicate-b")), ()),
            ("res", ["--out=res://boundary-invalid-"+output.name], (), ()),
            ("user", ["--out=user://boundary-invalid-"+output.name], (), ()),
            ("relative", ["--out=.godot/issue31-rc3/relative-invalid-"+output.name],
                (ROOT / ".godot/issue31-rc3" / ("relative-invalid-"+output.name),), ()),
            ("other-drive", ["--out=Z:/boundary-invalid-"+output.name+"/leaf"], (), ()),
            ("dot", ["--out="+str(dot_parent)+"/./leaf"], (dot_parent / "leaf",), ()),
            ("dotdot", ["--out="+str(dot_parent)+"/../dotdot-leaf"], (candidate("dotdot-leaf"),), ()),
            ("leading-whitespace", ["--out= "+str(candidate("leading-space"))],
                (candidate("leading-space"),), ()),
            ("trailing-whitespace", ["--out="+str(candidate("trailing-whitespace"))+" "],
                (candidate("trailing-whitespace"),), ()),
            ("unc", ["--out=//localhost/E$/boundary-invalid-"+output.name], (), ()),
            ("duplicate-slash", ["--out="+str(candidates)+"//double-slash-leaf"],
                (candidate("double-slash-leaf"),), ()),
            ("trailing-slash", ["--out="+str(candidate("trailing-slash"))+"/"],
                (candidate("trailing-slash"),), ()),
            ("trailing-dot", ["--out="+str(candidate("trailing-dot"))+"."],
                (candidate("trailing-dot"),), ()),
            ("component-trailing-space", ["--out="+str(dot_parent)+" /leaf"],
                (dot_parent / "leaf",), ()),
            ("illegal-character", ["--out="+str(candidate("illegal<leaf"))],
                (candidate("illegal<leaf"),), ()),
            ("colon", ["--out="+str(candidate("colon:leaf"))], (), ()),
            ("device-con", ["--out="+str(candidate("CON"))], (), ()),
            ("device-com1", ["--out="+str(candidate("COM1"))], (), ()),
            ("existing-directory", ["--out="+str(existing)], (existing,), (sentinel,)),
            ("existing-file", ["--out="+str(file_target)], (file_target,), ()),
            ("file-parent", ["--out="+str(file_target / "leaf")], (file_target,), ()),
            ("outside-owned", ["--out="+str(outside_parent / "leaf")], (outside_parent / "leaf",), ()),
            ("linked-parent", ["--out="+str(linked / "leaf")], (linked / "leaf", link_target / "leaf"), ()),
            ("missing-parent", ["--out="+str(candidate("absent-parent") / "leaf")],
                (candidate("absent-parent"),), ()),
        ]
        for name, arguments, targets, sentinels in invalid:
            run(name, [*pixel, *arguments], 1, targets, sentinels)
        if args.phase == "green":
            for mode in ("motion", "outcomes", "integrated"):
                run(mode + "-missing-out", ["--rc3-render-verification="+mode, "--ticks=1"], 1)
        legal = candidate("legal-new")
        run("legal-new-GL", [*pixel, "--out="+str(legal)], 0, (legal,), headless=False)
        run("unknown-mode", ["--rc3-render-verification=unknown", "--out="+str(candidate("unknown"))],
            1, (candidate("unknown"),))
        run("repeated-mode", [*pixel, "--rc3-render-verification=motion", "--out="+str(candidate("repeated"))],
            1, (candidate("repeated"),))
        run("ordinary-default-GL90", [], 0, headless=False, default=True)
        if args.phase == "red-matrix":
            reproduced = any(record["expected_exit"] == 1 and record["fixture_marker"]
                and not record["passed"] for record in records)
    end = source_state()
    unchanged = end["head"] == start["head"] and end["normalized_diff"] == start["normalized_diff"] \
        and end["staged_diff"] == start["staged_diff"] and end["status"] == start["status"]
    strict = all(record["passed"] for record in records) and unchanged
    report = dict(phase=args.phase, formal=args.phase == "green", source_start=start, source_end=end,
        source_unchanged=unchanged, build_commit=build_commit, build_info=build_info,
        executable=str(executable), executable_sha256=sha(executable), checks=records,
        strict_pass=strict, baseline_bug_reproduced=reproduced,
        invalid_fixture_safety="Invalid pixel cases are headless: if a guard regresses, the pixel fixture stops before filesystem output; its verification marker still fails the guard contract.",
        disclosure="Red explicitly records dirty development source and the untouched old packaged EXE; never represents new formal implementation. Formal green is standalone CLI evidence, not extra unittest discovery or a new 21-test count.")
    (output / "results.json").write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print("REPORT " + str(output / "results.json"), flush=True)
    return 0 if strict else 1


if __name__ == "__main__":
    raise SystemExit(main())
