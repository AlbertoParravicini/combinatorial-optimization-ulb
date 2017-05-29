import os
from random import randint

from os import listdir
from os.path import isfile, join

instances_path = "./instances"
instances = [f for f in listdir(instances_path) if isfile(join(instances_path, f))]

print(instances)

###########
# OPTIONS #
###########

# Amount of details printed
print_level = "1"
# Plot the graphs on a file
draw_graph = "false"
# Save the results and the statistics
save_res = "true"
# Use the specified heuristic
use_hot_start = ["random", "annealing", "nearest"]
# Use the specified solver
solver = "gurobi"
# Use the specified constraints
constr = ["mtz"]

# Run the entire thing the specified amount of times
num_iterations = 10
###########

for i in range(num_iterations):
	for c in constr: 
		for h in use_hot_start:
			rand_seed = randint(0, 1000000)
			for instance in instances:				
				command_input = "julia src/main.jl -i " + instance + " -r " + str(rand_seed) + " -p " + print_level +\
					" -d " + draw_graph + " -v " + save_res + " --usehotstart " + h +\
					" -s " + solver + " -c " + c 
				print("\n\n", i, ") EXECUTING:", command_input)
				os.system(command_input)

