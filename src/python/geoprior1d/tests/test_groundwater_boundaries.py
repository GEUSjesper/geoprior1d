"""Water-table cell regression tests; run with python -m unittest discover -s tests -v."""
import unittest
from unittest.mock import patch

import numpy as np

from geoprior1d.resistivity import prior_res_reals


def resistivity(uncertainty=.1):
    """Saturated 100/20/200 and unsaturated 1000/200/2000 ohm-m for classes 1-3."""
    return {'Resistivity': {
        'res': np.array([100., 20., 200.]), 'res_unc': np.full(3, uncertainty),
        'unsat_res': np.array([1000., 200., 2000.]), 'unsat_res_unc': np.full(3, uncertainty),
    }}


class GroundwaterTests(unittest.TestCase):
    def setUp(self):
        self.info = resistivity(0.)  # no uncertainty, so values are exact

    def sample(self, water, dz=1., count=4):
        z = np.arange(1, count + 1) * dz
        return prior_res_reals(self.info, np.ones(count), water, np.ones(count), z)

    def test_surface_first_cell_and_exact_boundaries(self):
        # Cell bottoms at 1-4 m. A cell ending at the water table is wholly unsaturated,
        # a cell crossing it is the thickness-weighted mean of the two values.
        cases = [(0., [100, 100, 100, 100]), (.5, [550, 100, 100, 100]),
                 (1., [1000, 100, 100, 100]), (1.5, [1000, 550, 100, 100]),
                 (2., [1000, 1000, 100, 100]), (4., [1000]*4), (5., [1000]*4)]
        for water, expected in cases:
            with self.subTest(water=water):
                np.testing.assert_allclose(self.sample(water), expected, rtol=0, atol=1e-12)

    def test_fractional_cells_and_continuity(self):
        np.testing.assert_allclose(self.sample(.05, .1), [550, 100, 100, 100])
        np.testing.assert_allclose(self.sample(.3, .1), [1000, 1000, 1000, 100])
        for depth in (1., 2.):
            exact = self.sample(depth)
            for nearby in (np.nextafter(depth, 0), np.nextafter(depth, np.inf)):
                np.testing.assert_allclose(self.sample(nearby), exact, rtol=0, atol=1e-10)

    def test_per_layer_sampling_and_draw_order(self):
        info = resistivity()
        m = np.array([1., 1., 2., 2.])
        layers = np.array([2, 2, 1, 1])
        z = np.arange(1., 5.)
        # Sorted layer IDs: class 2 sat/unsat, then class 1 sat/unsat.
        with patch('numpy.random.randn', side_effect=[.1, .2, .3, .4]) as draws:
            actual = prior_res_reals(info, m, 2.5, layers, z)
        sat2, unsat2 = 20 * 10**.01, 200 * 10**.02
        unsat1 = 1000 * 10**.04
        np.testing.assert_allclose(actual, [unsat1, unsat1, (sat2+unsat2)/2, sat2])
        self.assertEqual(draws.call_count, 4)

    def test_dry_draw_order_is_preserved(self):
        with patch('numpy.random.randn', side_effect=[.1, .2]) as draws:
            np.testing.assert_array_equal(self.sample(0.), [100.]*4)
        self.assertEqual(draws.call_count, 2)


if __name__ == '__main__':
    unittest.main()
