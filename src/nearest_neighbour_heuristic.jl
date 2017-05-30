module NearestNeighbour

export nearestneighbour

function nearestneighbour(numCities, costMatrix; printDetails=0)
  #start measuring the execution time.
  startTime = tic()
  # Rename parameter, for simplicity.
  n = numCities

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

end


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
end
