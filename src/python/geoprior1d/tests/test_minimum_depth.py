"""Minimum-depth regression tests; run with python -m unittest discover -s tests -v."""
import copy
import unittest

import numpy as np

from geoprior1d.lithology import _check_section_depth_constraints
from geoprior1d.sampling import _generate_single_realization


def geology(frequency):
    """Three sections: a mandatory sand unit, a clay unit with the given frequency, background."""
    return {
        'Classes': {'min_thick': np.array([1., 1., 1.]),
                    'max_thick': np.array([10., 2., 100.])},
        'Sections': {
            'N_sections': 3, 'types': [[1], [2], [3]],
            'probabilities': [[1.], [1.], [1.]],
            'min_layers': np.array([1, 1, 1]), 'max_layers': np.array([1, 1, 1]),
            'min_thick': np.array([1., 1., 1.]), 'max_thick': np.array([10., 2., 1.]),
            'frequency': np.array([1., frequency, 1.]), 'repeat': np.array([1, 1, 1]),
            'min_depth': np.array([0., 0., 0.]),
        },
        'Resistivity': {
            'res': np.array([100., 20., 200.]), 'res_unc': np.array([.1, .1, .1]),
            'unsat_res': np.array([1000., 200., 2000.]),
            'unsat_res_unc': np.array([.1, .1, .1]),
        },
    }


class MinimumDepthTests(unittest.TestCase):
    def test_only_present_upper_units_constrain_depth(self):
        depths = np.array([0., 9., 999.])
        for thicknesses, expected in [([3., 0., 0.], 0), ([3., 1., 0.], 1),
                                      ([9., 1., 0.], 0)]:
            with self.subTest(thicknesses=thicknesses):
                self.assertEqual(_check_section_depth_constraints(
                    np.array(thicknesses), 3, depths), expected)

    def test_absent_units_do_not_condition_the_ensemble(self):
        z = np.arange(.25, 20.25, .25)
        for frequency in (0., .5):
            base = geology(frequency)
            constrained = copy.deepcopy(base)
            constrained['Sections']['min_depth'][1] = 9.
            absent = present = 0
            upper_lengths = []
            for seed in range(100):
                before = _generate_single_realization(0, base, z, seed)
                after = _generate_single_realization(0, constrained, z, seed)
                if not np.any(before[0] == 2):
                    absent += 1
                    for left, right in zip(before, after):
                        np.testing.assert_array_equal(left, right)
                    upper_lengths.append(np.sum(after[0] == 1))
                else:
                    present += 1
                    self.assertTrue(np.all(z[after[0] == 2] > 9.))
                    self.assertEqual(after[3][:2], [0, 0])
            self.assertGreater(absent, 20)
            self.assertGreater(len(set(upper_lengths)), 10)
            if frequency:
                self.assertGreater(present, 20)


if __name__ == '__main__':
    unittest.main()
