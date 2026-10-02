"""Reproducibly construct the missing MOVE ONE fixtures from legal boards."""
import json
from pathlib import Path
from enumerate_solutions import enumerate_solutions, valid_moves, violation_lines

ROOT = Path(__file__).resolve().parents[1]
NAMES = ["LAST ONE", "TWO LEFT", "THIRD", "WHOLE BOARD", "EIGHT", "ROWS",
         "COLUMNS", "TWO PER LINE", "HALF SLOPE", "STEEP", "REVERSE", "CENTER TRAP",
         "GHOST GRID", "SHADOW LINES", "THREE SEEDS", "TWO POINTS",
         "INTERSECTION", "ONE SHIFT", "CROSSING", "INVISIBLE KNOT"]
SEEDS = [
    [(1,1),(2,1),(1,2),(3,2),(2,3)],
    [(2,1),(3,1),(1,2),(3,2)],
    [(1,1),(2,1),(1,2)], [(3,1)],
    [(1,1),(2,1),(3,2),(4,2),(1,3),(2,3)],
    [(1,1),(3,1),(1,2),(3,2),(2,3)],
    [(1,1),(3,1),(2,2),(4,2)], [(1,1),(4,1)],
    [(1,1),(2,1),(1,2),(4,2),(4,3),(5,3),(2,4)],
    [(1,1),(2,1),(2,2),(4,2),(1,3),(3,5)],
    [(1,1),(3,1),(1,2),(4,3),(3,5)], [(1,1),(3,1),(5,2),(1,4)],
    [(1,1),(2,1),(2,2)], [(1,1),(3,3),(1,4),(3,4)],
    [(3,2),(5,2),(5,4)], [(1,1),(6,6)],
]
SIZES = [3]*4 + [4]*4 + [5]*5 + [6]*3
CHAPTERS = ["THIRD", "TWO PER LINE", "NOT DIAGONAL", "INVISIBLE", "MOVE ONE"]


def build() -> None:
    stages = []
    fixtures = []
    for index, (size, seeds) in enumerate(zip(SIZES, SEEDS), 1):
        answers = enumerate_solutions(size, seeds, size * 2)
        print(f"Stage {index:03} original solutions={len(answers)}", flush=True)
        stages.append(dict(id=index, name=NAMES[index-1], chapter=CHAPTERS[(index-1)//4],
                           size=size, mode="place", target=2*size, initial=seeds))
        fixtures.append(dict(id=index, expected_count=1, solution=answers[0] if answers else []))
    all_boards = {}
    for stage_id, size, source, destination in [
        (17,4,(1,2),(4,4)), (18,4,(3,1),(2,4)),
        (19,5,(3,3),(2,4)), (20,6,(3,3),(6,5)),
    ]:
        if size not in all_boards:
            all_boards[size] = enumerate_solutions(size, [], size*2)
        for solution in all_boards[size]:
            if destination not in solution or source in solution:
                continue
            initial = [source if p == destination else p for p in solution]
            if violation_lines(initial) and valid_moves(size, initial) == [(source, destination)]:
                stages.append(dict(id=stage_id, name=NAMES[stage_id-1], chapter=CHAPTERS[4],
                                   size=size, mode="move_one", target=2*size, initial=initial))
                fixtures.append(dict(id=stage_id, expected_count=1, move=[source,destination]))
                print(f"Stage {stage_id:03} generated unique move", flush=True)
                break
        else:
            raise RuntimeError(f"No fixture found for stage {stage_id}")
    (ROOT / "data").mkdir(exist_ok=True)
    (ROOT / "tests/fixtures").mkdir(parents=True, exist_ok=True)
    (ROOT / "data/stages.json").write_text(json.dumps(stages, indent=2)+"\n", encoding="utf-8")
    (ROOT / "tests/fixtures/stage_solutions.json").write_text(json.dumps(fixtures, indent=2)+"\n", encoding="utf-8")


if __name__ == "__main__":
    build()
