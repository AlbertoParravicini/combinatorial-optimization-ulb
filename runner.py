import os
from random import randint

from os import listdir
from os.path import isfile, join

instances_path = "./instances"
instances = [f for f in listdir(instances_path) if isfile(join(instances_path, f))]

print(instances)

print_level = "0"
draw_graph = "true"
save_res = "true"
use_hot_start = "true"

for instance in instances:
	rand_seed = randint(0, 1000000)
	command_input = "julia src/main.jl -i " + instance + " -r " + str(rand_seed) + " -p " + print_level + " -d " + draw_graph + " -v " + save_res + " --usehotstart " + use_hot_start
	print("\n\nEXECUTING:", command_input)
	os.system(command_input)

