"""Exact integer solver for NO THREE; never imported by the game."""
from __future__ import annotations

import argparse
from itertools import combinations
import json
from math import gcd
from pathlib import Path

Point = tuple[int, int]


def are_collinear(a: Point, b: Point, c: Point) -> bool:
    return (b[0] - a[0]) * (c[1] - a[1]) == (b[1] - a[1]) * (c[0] - a[0])


def canonical_line_key(a: Point, b: Point) -> tuple[int, int, int]:
    if a == b:
        raise ValueError("A line requires two distinct points")
    aa, bb = b[1] - a[1], a[0] - b[0]
    cc = -(aa * a[0] + bb * a[1])
    divisor = gcd(gcd(abs(aa), abs(bb)), abs(cc))
    aa, bb, cc = aa // divisor, bb // divisor, cc // divisor
    if aa < 0 or (aa == 0 and bb < 0):
        aa, bb, cc = -aa, -bb, -cc
    return aa, bb, cc


def violation_lines(points: list[Point]) -> set[tuple[int, int, int]]:
    return {canonical_line_key(a, b) for a, b, c in combinations(points, 3)
            if are_collinear(a, b, c)}


def can_add(points: list[Point], p: Point) -> bool:
    return p not in points and not any(are_collinear(a, b, p)
                                     for a, b in combinations(points, 2))


def enumerate_solutions(size: int, initial: list[Point], target: int,
                        limit: int | None = None) -> list[list[Point]]:
    if violation_lines(initial) or len(set(initial)) != len(initial):
        return []
    answers: list[list[Point]] = []
    if target == 2 * size:
        # Every complete row must contain exactly two dots. This is a solver
        # pruning fact, deliberately absent from player-facing instructions.
        choices = []
        for y in range(1, size + 1):
            seeds = [p for p in initial if p[1] == y]
            if len(seeds) > 2:
                return []
            empty = [(x, y) for x in range(1, size + 1) if (x, y) not in seeds]
            choices.append([list(pair) for pair in combinations(empty, 2 - len(seeds))])
        rows = sorted(range(size), key=lambda row: len(choices[row]))

        def visit(depth: int, placed: list[Point]) -> None:
            if limit is not None and len(answers) >= limit:
                return
            if depth == size:
                answers.append(sorted(placed, key=lambda p: (p[1], p[0])))
                return
            for additions in choices[rows[depth]]:
                next_points = placed.copy()
                for p in additions:
                    if not can_add(next_points, p):
                        break
                    next_points.append(p)
                else:
                    visit(depth + 1, next_points)

        visit(0, initial.copy())
    else:
        candidates = [(x, y) for y in range(1, size + 1)
                      for x in range(1, size + 1) if (x, y) not in initial]

        def visit_general(start: int, placed: list[Point]) -> None:
            if limit is not None and len(answers) >= limit:
                return
            if len(placed) == target:
                answers.append(placed.copy())
                return
            for index in range(start, len(candidates) - (target - len(placed)) + 1):
                p = candidates[index]
                if can_add(placed, p):
                    visit_general(index + 1, placed + [p])

        visit_general(0, initial.copy())
    return answers


def valid_moves(size: int, initial: list[Point]) -> list[tuple[Point, Point]]:
    answers = []
    for source in initial:
        remaining = [p for p in initial if p != source]
        if violation_lines(remaining):
            continue
        for y in range(1, size + 1):
            for x in range(1, size + 1):
                destination = (x, y)
                if destination not in initial and can_add(remaining, destination):
                    answers.append((source, destination))
    return answers


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("stage", type=int)
    parser.add_argument("--data", type=Path, default=Path(__file__).resolve().parents[1] / "data/stages.json")
    args = parser.parse_args()
    stage = next(s for s in json.loads(args.data.read_text(encoding="utf-8")) if s["id"] == args.stage)
    initial = [tuple(p) for p in stage["initial"]]
    result = (valid_moves(stage["size"], initial) if stage["mode"] == "move_one"
              else enumerate_solutions(stage["size"], initial, stage["target"]))
    print(json.dumps(result))
