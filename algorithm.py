

import matplotlib.pyplot as plt
import numpy as np


heightmap = np.zeros([10,10])

ceil = heightmap+np.Infinity



for i in range(0,10):
    for j in range(0,10):
        if i > 1 and i < 8 and j<8 and j>1:
            if i > 5 and i < 8 and j<8 and j>5:
                heightmap[i][j] = 120+i+j
                ceil[i][j] = 40-i-j
            else:
                heightmap[i][j] = 100
                ceil[i][j] = 90


######### THE ALGORITHM #########
#################################            
def myfunc(a,b):
    if a-b < 0:
        return (0)
    else:
        return (a-b)

vfunc = np.vectorize(myfunc)
diff = vfunc(heightmap,ceil)
indice = np.unravel_index(np.argmax(diff, axis=None), diff.shape)
#################################

print(heightmap,ceil,vfunc(heightmap,ceil),sep='\n\n\n')
print()
ind = np.unravel_index(np.argmax(diff, axis=None), diff.shape)
print(f"\tindice {ind}  \n\tmaximo {heightmap[ind]} \n\tminimo: {ceil[ind]}\n\tLocal de corte:{(heightmap[ind]+ceil[ind])/2}")