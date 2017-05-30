module NearestNeighbour

<<<<<<< HEAD
export nearestneighbour

function nearestneighbour(numCities, costMatrix; printDetails=0)
  #start measuring the execution time.
=======
export neareastneighbour

function neareastneighbour(numCities, costMatrix; printDetails = 0, noMatrix = false)
  # Start measuring the execution time.
>>>>>>> 936ae0ae0afe6de368efd80b4306dacb1906f609
  startTime = tic()
  # Rename parameter, for simplicity.
  n = numCities

<<<<<<< HEAD
  #code from evanfields
  #see https://github.com/evanfields

  # put first city on path
	path = Vector{Int}()

  #start from random city
  firstcity = rand(1:n)

	push!(path, firstcity)

	# cities to visit
	citiesToVisit = collect(1:(firstcity - 1))
	append!(citiesToVisit, collect((firstcity + 1):numCities))

	# nearest neighbor loop
	while !isempty(citiesToVisit)
		curCity = path[end]
		dists = costMatrix[curCity, citiesToVisit]
		_, nextInd = findmin(dists)
		nextCity = citiesToVisit[nextInd]
		push!(path, nextCity)
		deleteat!(citiesToVisit, nextInd)
  end
  execTime = toc()
  bestres = computetourcost(path, costMatrix)

  if printDetails > 0
    println("INITIAL HEURISTIC RESULT:", path)
    println("HEURISTIC EXECUTION TIME"; execTime)
  end
  return buildinitialmatrix(path)
=======
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

  if (noMatrix)
    return sol
  else
    return buildinitialmatrix(sol)
  end
>>>>>>> 936ae0ae0afe6de368efd80b4306dacb1906f609

end


<<<<<<< HEAD
function buildinitialmatrix(permutation)
 x = zeros(Int, length(permutation), length(permutation))
 for i=2:length(permutation)
   x[permutation[i-1], permutation[i]] = 1
 end
 x[permutation[end], permutation[1]] = 1
 println("matrix ",x)
 println("permutation", permutation)
 return x
end

=======
function displayDetails(printDetails, execTime, costMatrix, solution)
  bestres = computetourcost(solution, costMatrix)
  if printDetails > 0
    println("INITIAL HEURISTIC RESULT:", bestres)
    println("HEURISTIC EXECUTION TIME:", execTime)
  end
end


>>>>>>> 936ae0ae0afe6de368efd80b4306dacb1906f609
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
<<<<<<< HEAD
end
=======


function buildinitialmatrix(permutation)
 x = zeros(Int, length(permutation), length(permutation))
 for i=2:length(permutation)
   x[permutation[i-1], permutation[i]] = 1
 end
 x[permutation[end], permutation[1]] = 1

 return x
end

end
>>>>>>> 936ae0ae0afe6de368efd80b4306dacb1906f609
