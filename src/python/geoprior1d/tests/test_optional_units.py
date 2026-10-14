"""Optional-unit regression tests; run with python -m unittest discover -s tests -v."""
import unittest

import numpy as np

from geoprior1d.sampling import _generate_single_realization, get_prior_sample


def geology():
    """Two optional upper units (sand p=0.4, clay p=0.3) above a background class."""
    return {
        'Classes': {'min_thick': np.array([1., 1., 1.]),
                    'max_thick': np.array([10., 2., 100.])},
        'Sections': {
            'N_sections': 3, 'types': [[1], [2], [3]],
            'probabilities': [[1.], [1.], [1.]],
            'min_layers': np.array([1, 1, 1]), 'max_layers': np.array([1, 1, 1]),
            'min_thick': np.array([1., 1., 1.]), 'max_thick': np.array([10., 2., 1.]),
            'frequency': np.array([.4, .3, 1.]), 'repeat': np.array([1, 1, 1]),
            'min_depth': np.array([0., 0., 0.]),
        },
        'Resistivity': {
            'res': np.array([100., 20., 200.]), 'res_unc': np.array([.1, .1, .1]),
            'unsat_res': np.array([1000., 200., 2000.]),
            'unsat_res_unc': np.array([.1, .1, .1]),
        },
    }


class OptionalUnitTests(unittest.TestCase):
    def test_all_upper_units_optional_leaves_background(self):
        info = geology()
        z = np.arange(1., 21.)
        background_only = 0
        for seed in range(300):
            m, resistivity, _, flags = _generate_single_realization(0, info, z, seed)
            self.assertEqual(flags[:2], [0, 0])
            if not np.any(m != 3):
                background_only += 1
                self.assertEqual(len(np.unique(resistivity)), 1)  # one background layer
        self.assertGreater(background_only, 300 * .6 * .7 * .6)  # expected share is .42
        np.random.seed(123)
        results = [get_prior_sample(info, z, 200, n_processes=p) for p in (1, 2)]
        for _, _, _, flags in results:
            self.assertEqual(list(flags[:2]), [0, 0])


if __name__ == '__main__':
    unittest.main()
