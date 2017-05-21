module RandomPick

export randompick

function randompick(numCities, costMatrix, numPicks=100; printDetails=0)

  # Rename parameter, for simplicity.
  n = numCities
  p = numPicks

  bestres = Inf
  bestsol = collect(1:n)
  for i=1:p
    tempsol = shuffle(1:n)
    tempres = computetourcost(tempsol, costMatrix)
    if tempres < bestres
      bestres = tempres
      bestsol = tempsol
    end
  end

  if printDetails > 0
    println("INITIAL HEURISTIC RESULT:", bestres)
  end
  return buildinitialmatrix(bestsol)
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
