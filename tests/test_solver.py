"""Independent geometry tests; the Godot suite tests the shipping rule code."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from enumerate_solutions import are_collinear, canonical_line_key, can_add, violation_lines
from validate_stages import validate

class GeometryTests(unittest.TestCase):
    def test_angles(self):
        triples = [((1,1),(2,1),(6,1)), ((1,1),(1,2),(1,6)),
                   ((1,1),(2,2),(6,6)), ((1,1),(3,2),(5,3)),
                   ((1,1),(2,3),(3,5)), ((1,5),(3,3),(5,1))]
        for triple in triples:
            with self.subTest(triple=triple):
                self.assertTrue(are_collinear(*triple))
        self.assertFalse(are_collinear((1,1),(2,2),(3,1)))

    def test_canonical_lines_and_deduplication(self):
        self.assertEqual(canonical_line_key((1,1),(3,2)), canonical_line_key((5,3),(3,2)))
        self.assertEqual(canonical_line_key((1,1),(2,1)), (0,1,-1))
        self.assertEqual(canonical_line_key((1,1),(1,2)), (1,0,-1))
        self.assertEqual(len(violation_lines([(1,1),(2,2),(3,3),(4,4)])), 1)

    def test_placement(self):
        self.assertTrue(can_add([(1,1),(2,1)], (1,2)))
        self.assertFalse(can_add([(1,1),(2,1)], (3,1)))
        self.assertFalse(can_add([(1,1),(1,2)], (1,3)))
        self.assertFalse(can_add([(1,1),(3,2)], (5,3)))
        self.assertFalse(can_add([(1,1)], (1,1)))

    def test_twenty_stages(self):
        self.assertTrue(validate())

if __name__ == "__main__":
    unittest.main()
