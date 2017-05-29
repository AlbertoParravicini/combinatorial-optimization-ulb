module NearestNeighbour

export neareastneighbour

function neareastneighbour(numCities, costMatrix; printDetails = 0)
  # Start measuring the execution time.
  startTime = tic()
  # Rename parameter, for simplicity.
  n = numCities

  # Take one city at random to initiate the tour.
  currentCity = rand(1:n)

  # Vector of visited cities.
  visited = falses(n)

  # Create a solution vector.
  sol = collect(1:n)

  sol[1] = currentCity
  visited[currentCity] = true

  # NN
  for i=2:n
    bestWeight = Inf
    best = -1
    for j=1:n
      if j!=currentCity && !visited[j] && costMatrix[currentCity, j] < bestWeight
        best = j
        bestWeight = costMatrix[currentCity, j]
      end
    end
    currentCity = best
    visited[best] = true
    sol[i] = currentCity
  end

  displayDetails(printDetails, toc(), costMatrix, sol)

  return buildinitialmatrix(sol)

end


function displayDetails(printDetails, execTime, costMatrix, solution)
  bestres = computetourcost(solution, costMatrix)
  if printDetails > 0
    println("INITIAL HEURISTIC RESULT:", bestres)
    println("HEURISTIC EXECUTION TIME:", execTime)
  end
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