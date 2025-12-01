import numpy as np

def prior_water_reals(info):
  
    o = np.random.rand() * (info['Water Level']['max'] - info['Water Level']['min']) + info['Water Level']['min']
    return o
