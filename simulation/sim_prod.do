*Simulation of Productivity
clear 
*parameters 
local p 1 
local alpha .5 
local w 2


set obs 1000 
gen i = _n 
gen A = rnormal(10,1)

gen L = ((`alpha'*A*`p')/`w')^(1-`alpha')

gen pi = `p'*A*L^`alpha' - `w'*L - 10

hist pi 

hist A if pi > 0 

