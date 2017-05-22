module SimulatedAnnealing

export simulatedannealing

function simulatedannealing(numCities, costMatrix, initial_temp=100; printDetails=0)
  # Start measuring the execution time.
  startTime = tic()
  
  # Rename parameter, for simplicity.
  n = numCities
  # Set temperature.
  t = initial_temp
  # Coefficient for geometric cooling.
  α = 0.95
  # Stop when for a certain number of temperatures no improvement is found.
  stepsBeforeStopping = initial_temp / 10
  # Number of steps done at each temperature.
  numSteps = n * (n - 1)
  # Count the temperature steps without improvements.
  stepsWithoutImp = 0

  # Initialize the current state.
  currstate = shuffle(1:n)
  # Evaluate the current state
  currstateres = computetourcost(currstate, costMatrix)

  # Store the best result and state
  bestres = currstateres
  beststate = currstate

  while t >= 0 && stepsWithoutImp < stepsBeforeStopping
    # Set to true if an improvement was found.
    impFound = false
    for step=1:numSteps
      # The candidate neighbour state is picked at random from the 2-exchange neighbourhood.
      neighIndex = rand(1:n-1)
      # Build the neighbour at the given index
      neigh = vcat(currstate[1:neighIndex-1], currstate[neighIndex+1], currstate[neighIndex] , currstate[neighIndex+2:end])
      # Metropolis condition: always accept improving steps, else accept with prob = ...
      neighres = computetourcost(neigh, costMatrix)
      if neighres < currstateres
        currstate = neigh
        currstateres = neighres
        beststate = neigh
        bestres = neighres
        impFound = true
        stepsWithoutImp = 0
      elseif rand() < exp((currstateres - neighres) / t)
        currstate = neigh
        currstateres = neighres
      end
    end
    t *= α
    if !impFound
      stepsWithoutImp += 1
    end
  end

  execTime = toc()
  if printDetails > 0
    println("INITIAL HEURISTIC RESULT:", bestres)
    println("HEURISTIC EXECUTION TIME:", execTime)
  end
  return buildinitialmatrix(beststate)
end

function computetourcost(permutation, costMatrix)
  # Rename parameter, for simplicity.
  p = permutation
  c = costMatrix

  cost = 0
  for i=2:length(permutation)
    cost += c[p[i-1], p[i]]
  end
  cost += c[p[end], p[1]]

  return cost
end

function buildinitialmatrix(permutation)
 x = zeros(Int, length(permutation), length(permutation))
 for i=2:length(permutation)
   x[permutation[i-1], permutation[i]] = 1
 end
 x[permutation[end], permutation[1]] = 1

 return x
end

end
