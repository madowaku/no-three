"""Validate all twenty stage definitions and their independent solver fixtures."""
import argparse
import json
from pathlib import Path
from enumerate_solutions import enumerate_solutions, valid_moves, violation_lines

ROOT = Path(__file__).resolve().parents[1]

def validate(data: Path = ROOT / "data/stages.json") -> bool:
    stages = json.loads(data.read_text(encoding="utf-8"))
    fixtures = {f["id"]: f for f in json.loads((ROOT / "tests/fixtures/stage_solutions.json").read_text(encoding="utf-8"))}
    failures = []
    if [s["id"] for s in stages] != list(range(1, 21)):
        failures.append("Stage IDs must be exactly 001–020 in order")
    for stage in stages:
        stage_id, size, target = stage["id"], stage["size"], stage["target"]
        initial = [tuple(p) for p in stage["initial"]]
        errors = []
        if not 3 <= size <= 6 or not len(initial) <= target <= size*size:
            errors.append("invalid size or target")
        if len(initial) != len(set(initial)):
            errors.append("duplicate coordinates")
        if any(len(p) != 2 or any(type(c) is not int or not 1 <= c <= size for c in p) for p in initial):
            errors.append("invalid coordinates")
        fixture = fixtures[stage_id]
        if stage["mode"] == "place":
            if violation_lines(initial):
                errors.append("illegal initial PLACE board")
            answers = enumerate_solutions(size, initial, target)
            metric = f"solutions={len(answers)}"
            if len(answers) != 1 or [tuple(p) for p in fixture["solution"]] not in answers:
                errors.append("expected the single fixture solution")
        elif stage["mode"] == "move_one":
            if len(initial) != target or not violation_lines(initial):
                errors.append("MOVE_ONE must begin at target with violations")
            moves = valid_moves(size, initial)
            metric = f"moves={len(moves)}"
            if moves != [tuple(tuple(p) for p in fixture["move"])]:
                errors.append("expected the single specified fixture move")
        else:
            errors.append("unknown mode")
            metric = ""
        print(f"Stage {stage_id:03d} {'FAIL' if errors else 'PASS'} {metric}")
        failures.extend(f"Stage {stage_id:03d}: {error}" for error in errors)
    for failure in failures:
        print(failure)
    return not failures

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=Path, default=ROOT / "data/stages.json")
    args = parser.parse_args()
    raise SystemExit(0 if validate(args.data) else 1)
