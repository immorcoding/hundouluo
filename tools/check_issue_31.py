"""Strict integration checks with complete SceneTree inheritance discovery.

Paced mode preserves every original assertion. Fixed FPS controls simulation;
17ms process-frame waits give the audio worker real time. Default mode records
the engine's original unpaced condition separately, never as an implied pass.
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
DIAGNOSTIC = re.compile(r"^\s*(?:ERROR:|SCRIPT ERROR:|WARNING:)", re.MULTILINE)


def git(*arguments):
    return subprocess.check_output(["git", "-c", "core.quotepath=false", *arguments],
                                   cwd=ROOT, text=True, encoding="utf-8").rstrip("\r\n")


def source_state():
    return {
        "head": git("rev-parse", "HEAD"),
        "status": git("status", "--porcelain=v1", "--untracked-files=all").splitlines(),
        "normalized_diff": git("diff", "--name-only").splitlines(),
        "staged_diff": git("diff", "--cached", "--name-only").splitlines(),
    }


def scene_tree_ancestor(script, chain=()):
    if script in chain:
        raise ValueError("Cyclic test inheritance: " + str(script))
    source = script.read_text(encoding="utf-8")
    match = re.search(r'^extends\s+([^\n]+)', source, re.MULTILINE)
    if not match:
        raise ValueError("Test script has no explicit extends: " + str(script))
    parent = match[1].split("#", 1)[0].strip()
    if parent == "SceneTree":
        return True
    if parent == "Node2D":
        return False  # The two actual encounter-scene fixtures.
    resource = re.fullmatch(r'"(res://[^"]+)"', parent)
    if not resource:
        raise ValueError("Unclassified test inheritance: " + str(script) + " -> " + parent)
    ancestor = (ROOT / resource[1][6:]).resolve()
    if not ancestor.is_relative_to(ROOT.resolve()) or not ancestor.is_file():
        raise ValueError("Missing/outside test ancestor: " + str(ancestor))
    return scene_tree_ancestor(ancestor, (*chain, script))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--temp", type=Path, required=True,
                        help="Scratch outside this snapshot, for the clean package test")
    parser.add_argument("--clock", choices=("paced", "default"), default="paced")
    parser.add_argument("--tests", nargs="+", help="Explicit targeted probe, not a complete suite")
    parser.add_argument("--godot-only", action="store_true", help="Targeted probe; skip Python/package")
    args = parser.parse_args()
    start = source_state()
    if start["status"]:
        print("Refusing to identify a dirty worktree as a tested commit.", file=sys.stderr)
        return 2
    scripts, fixtures = [], []
    for script in sorted((ROOT / "tests").glob("*.gd")):
        (scripts if scene_tree_ancestor(script) else fixtures).append(script)
    if args.tests:
        missing = set(args.tests) - {p.stem for p in scripts}
        if missing:
            raise ValueError("Unknown requested tests: " + repr(sorted(missing)))
        selected = [p for p in scripts if p.stem in args.tests]
    else:
        selected = scripts
    args.output.mkdir(parents=True, exist_ok=True)
    args.temp.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(TEMP=str(args.temp.resolve()), TMP=str(args.temp.resolve()))
    env["PATH"] = str(Path(args.godot).parent) + os.pathsep + env["PATH"]
    records = []
    complete = not args.tests and not args.godot_only
    inventory = {"tests": ["tests/" + p.name for p in scripts],
                 "scene_fixtures": ["tests/" + p.name for p in fixtures],
                 "selected": ["tests/" + p.name for p in selected]}
    (args.output / "inventory.json").write_text(json.dumps(inventory, indent=2)+"\n", encoding="utf-8")

    def run(name, command, require_pass=False, condition=None):
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                text=True, encoding="utf-8", errors="replace", timeout=600)
        log = result.stdout + result.stderr
        (args.output / (name + ".log")).write_text(log, encoding="utf-8")
        diagnostics = [line for line in log.splitlines() if DIAGNOSTIC.match(line)]
        messages = [line for line in log.splitlines() if re.match(r"^PASS(?:\s|:)", line)]
        passed = result.returncode == 0 and not diagnostics and (messages or not require_pass)
        records.append({"name": name, "exit": result.returncode, "diagnostics": diagnostics,
                        "pass_messages": messages, "log": name+".log", "command": command,
                        "condition": condition, "pass": bool(passed)})
        print(f"{name}: exit={result.returncode}, diagnostics={len(diagnostics)}, pass={bool(passed)}", flush=True)

    # Consume the untouched Git commit before import changes sidecar line endings.
    if not args.godot_only:
        run("python", [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"])
    run("import", [args.godot, "--headless", "--editor", "--path", str(ROOT), "--import", "--quit"])
    wrapper_dir = ROOT / ".godot/issue-31-paced-tests"
    wrapper_dir.mkdir(parents=True, exist_ok=True)
    for script in selected:
        relative = "tests/" + script.name
        fps = 30 if script.stem == "operative_muzzle_victory" else 60
        command = [args.godot, "--headless", "--path", str(ROOT)]
        if args.clock == "paced":
            wrapper = wrapper_dir / script.name
            wrapper.write_text('extends "res://' + relative + '"\n\n'
                               'func _initialize() -> void:\n'
                               '\tprocess_frame.connect(func() -> void: OS.delay_msec(17))\n'
                               '\tsuper._initialize()\n', encoding="utf-8")
            command += ["--fixed-fps", str(fps), "--script",
                        "res://.godot/issue-31-paced-tests/" + script.name]
        else:
            command += ["--script", relative]
        run(script.stem, command, require_pass=True, condition={
            "clock": args.clock, "simulation_fps": fps if args.clock == "paced" else None,
            "process_frame_wall_wait_ms": 17 if args.clock == "paced" else 0,
            "physics_hz": 120 if script.stem == "operative_muzzle_victory" else 60})
    if complete:
        run("main-headless", [args.godot, "--headless", "--path", str(ROOT), "--quit-after", "90"])
        run("main-graphical", [args.godot, "--path", str(ROOT), "--rendering-method",
                               "gl_compatibility", "--quit-after", "90"])
    end = source_state()
    # Record importer metadata honestly; do not stage it or relax real source changes.
    metadata_only = all(line.startswith(" M ") and line.endswith(".import") for line in end["status"])
    unchanged = (end["head"] == start["head"] and not end["normalized_diff"]
                 and not end["staged_diff"] and metadata_only)
    passed = unchanged and all(record["pass"] for record in records)
    (args.output / "results.json").write_text(json.dumps({
        "tested_commit": start["head"], "strict_pass": passed, "complete_suite": complete,
        "godot_test_count": len(selected), "discovered_godot_test_count": len(scripts),
        "inventory": inventory, "source_start": start, "source_end": end,
        "normalized_source_unchanged": unchanged, "checks": records,
        "note": "All original assertions run unchanged. Paced mode = fixed simulation60fps plus explicit 17ms wall wait per process frame; victory30fps/physics120. Default failures remain separate. Import-only line-ending/stat flags may remain, with empty normalized/staged diffs. Exit/PASS/diagnostics are all gates; not new human acceptance."
    }, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
