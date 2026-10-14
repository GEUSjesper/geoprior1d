"""Parallel-generation regression tests; run with python -m unittest discover -s tests -v."""
import unittest

import numpy as np

from geoprior1d.sampling import _generate_single_realization, get_prior_sample


def geology():
    """A mandatory sand unit, a clay unit present in half the models, and a background class."""
    return {
        'Classes': {'min_thick': np.array([1., 1., 1.]),
                    'max_thick': np.array([10., 2., 100.])},
        'Sections': {
            'N_sections': 3, 'types': [[1], [2], [3]],
            'probabilities': [[1.], [1.], [1.]],
            'min_layers': np.array([1, 1, 1]), 'max_layers': np.array([1, 1, 1]),
            'min_thick': np.array([1., 1., 1.]), 'max_thick': np.array([10., 2., 1.]),
            'frequency': np.array([1., .5, 1.]), 'repeat': np.array([1, 1, 1]),
            'min_depth': np.array([0., 0., 0.]),
        },
        'Resistivity': {
            'res': np.array([100., 20., 200.]), 'res_unc': np.array([.1, .1, .1]),
            'unsat_res': np.array([1000., 200., 2000.]),
            'unsat_res_unc': np.array([.1, .1, .1]),
        },
    }


class BoundedBatchTests(unittest.TestCase):
    def test_bounded_batches_preserve_global_seeds_and_flags(self):
        # 2051 realizations cross the 2048-realization batch boundary.
        info = geology()
        z = np.arange(1., 21.)
        np.random.seed(123)
        offset = np.random.randint(0, 1e9)
        expected = [_generate_single_realization(i, info, z, offset) for i in range(2051)]
        for processes in (1, 2):
            np.random.seed(123)
            ms, ns, ws, flags = get_prior_sample(info, z, 2051, n_processes=processes)
            np.testing.assert_array_equal(ms, np.array([s[0] for s in expected], dtype=np.float32))
            np.testing.assert_array_equal(ns, np.array([s[1] for s in expected], dtype=np.float32))
            np.testing.assert_array_equal(ws, np.array([s[2] for s in expected], dtype=np.float32))
            np.testing.assert_allclose(flags, [max(s[3][0] for s in expected),
                                               max(s[3][1] for s in expected),
                                               sum(s[3][2] for s in expected)/2051])


if __name__ == '__main__':
    unittest.main()
