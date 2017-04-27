include("./plotter.jl")
include("./tsp_solver.jl")
using TspSolver
using Plotter
using JuMP



function main()

  ##################
  # PARSE INSTANCE #
  ##################

  # Name of the file to open.
  instanceName = "1.atsp"
  filename = string("./instances/", instanceName)

  # Open the file, get the number of cities.
  f = open(filename)
  # Get the number of instances.
  # Do so by reading the first line, remove the first 2 characters, remove spaces and \n, cast to Int.
  matrixSize = parse(Int, lstrip(chomp(readlines(f)[1])[3:end]))
  close(f)

  # Read and build the adjacency matrix.
  f = open(filename)
  # Read the entire file as a single string.
  s = readstring(f)
  # Remove \n
  s = replace(s, "\n", "")
  # Tokenize the text, by splitting on spaces (which are removed)
  ssplit = split(s, " ", keep=false)
  # Remove the tokens relative to the first line and to the ending bracket.
  ssplit = ssplit[4:end-1]
  # Cast to integer the cost matrix.
  ssplit = map(x->parse(Int, x), ssplit)
  # Build a matrix of size matrixSize^2, by reshaping the tokenized string.
  costMatrix = reshape(ssplit, matrixSize, matrixSize)
  # Build the adjacency matrix of the graph, in our case a full matrix.
  a = ones(matrixSize, matrixSize)
  close(f)


  #################
  # MODEL #########
  #################

  m = buildmodel(matrixSize, costMatrix, adjacencyMatrix=a)

  ############
  # SOLVE ####
  ############

  solvemodel!(m)

  ##########
  # PLOT ###
  ##########

  drawgraph(a, getvariable(m, :x), instanceName, costMatrix)
end


main()
