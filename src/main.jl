include("./plotter.jl")
include("./tsp_solver.jl")
include("./arg_parser.jl")
using TspSolver
using Plotter
using ArgumentParser

using JuMP
using DataFrames
using CSV



function main(args)

  ##################
  # PARSE INSTANCE #
  ##################

  # Parse the arguments, return them as a dictionary.
  argsDict = parseArgs(args)

  # Name of the file to open.
  instanceName = argsDict["instancename"]
  fileName = string("./instances/", instanceName)
  # Seed to be used by the random number generator. Can be "nothing".
  randomSeed = argsDict["randomseed"]
  # Name of the solver to be used.
  solverName = argsDict["solver"]
  # Type of subtour elimination constraints to be used.
  constrName = argsDict["constraints"]
  # Amount of details to be printed. Integer value >= 0.
  printLevel = argsDict["printlevel"]
  # Whether to plot or not the final graph.
  drawGraph = argsDict["drawgraph"]
  # Whether to save the results
  saveResult = argsDict["saveresult"]

  # Open the file, get the number of cities.
  f = open(fileName)
  # Get the number of instances.
  # Do so by reading the first line, remove the first 2 characters, remove spaces and \n, cast to Int.
  matrixSize = parse(Int, lstrip(chomp(readlines(f)[1])[3:end]))
  close(f)

  # Read and build the adjacency matrix.
  f = open(fileName)
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

  # Start measuring the execution time.
  startTime = tic()

  #################
  # MODEL #########
  #################
  m = buildmodel(matrixSize, costMatrix, adjacencyMatrix=a, seed=randomSeed, solver=solverName, subtourConstrType=constrName)


  ############
  # SOLVE ####
  ############
  solvemodel!(m, printDetails=printLevel)

  # Compute the execution time.
  execTime = toc()
  println("EXECUTION TIME:", execTime)

  ##########
  # PLOT ###
  ##########
  if drawGraph
    drawgraph(a, getvariable(m, :x), instanceName, costMatrix)
  end


  ################
  # SAVE RESULTS #
  ################
  if saveResult
    res = DataFrame(instance_name=instanceName,
                    exec_time=execTime,
                    random_seed=join(Base.Random.GLOBAL_RNG.seed, "_"),
                    constraints_type=constrName,
                    optim=0,
                    solution_value=getobjectivevalue(m)
                  )
    # Append the statistics to the csv file
    CSV.write("solutions/solutions.csv", res; append=true)

    # Store the variable values in a matrix.
    writedlm(string("solutions/", instanceName, "_solution.txt"), getvalue(getvariable(m, :x)))
  end
end


main(ARGS)
