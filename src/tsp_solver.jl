include("simulated_annealing_heuristic.jl")
include("random_pick_heuristic.jl")
include("nearest_neighbour_heuristic.jl")

module TspSolver

using SimulatedAnnealing, RandomPick, NearestNeighbour
using JuMP
using GLPKMathProgInterface, Gurobi

export buildmodel, solvemodel!


function buildmodel(
                    matrixSize::Int,
                    costMatrix;
                    adjacencyMatrix=nothing,
                    seed=nothing,
                    solver="gurobi",
                    subtourConstrType="claus",
                    useHotStart=true,
                    printDetails=0
                  )


  # Utility functions to add the specified constraints.

  ###################
  # MTZ CONSTRAINTS #
  ###################

  function add_subtour_constr_mtz()
    @variable(m, u[i=2:n])

    @constraintref subtourmtz[1:(n-1)^2]
    for i=2:n
      for j=2:n
        subtourmtz[(n-1) * (i-2) + (j-1)] = @constraint(m, (n - 1) * x[i, j] + u[i] - u[j] <= n - 2)
      end
    end
  end



  ###################
  # FCG CONSTRAINTS #
  ###################

  function add_subtour_constr_fcg()
    @variable(m, y[i=1:n, j=1:n] >= 0)
    @variable(m, z[i=1:n, j=1:n] >= 0)

    @constraintref constrfcg14
    constrfcg14 = @constraint(m, sum(y[1, j] for j=1:n) - sum(y[j, 1] for j=1:n) == n - 1)

    @constraintref constrfcg15[1:n-1]
    for i=2:n
      constrfcg15[i-1] = @constraint(m, sum(y[i, j] for j=1:n) - sum(y[j, i] for j=1:n) == -1)
    end

    @constraintref constrfcg16
    constrfcg16 = @constraint(m, sum(z[1, j] for j=1:n) - sum(z[j, 1] for j=1:n) == 1 - n)

    @constraintref constrfcg17[1:n-1]
    for i=2:n
      constrfcg17[i-1] = @constraint(m, sum(z[i, j] for j=1:n) - sum(z[j, i] for j=1:n) == 1)
    end

    @constraintref constrfcg18[1:n]
    for i=1:n
      constrfcg18[i] = @constraint(m, sum(y[i, j] for j=1:n) + sum(z[i, j] for j=1:n) == n - 1)
    end

    @constraintref constrfcgcoupling
    constrfcgcoupling = @constraint(m, y + z .== (n - 1) * x)
  end



  #####################
  # CLAUS CONSTRAINTS #
  #####################

  function add_subtour_constr_claus()
    @variable(m, y[i=1:n, j=1:n, k=2:n] >= 0)

    @constraintref constrclaus26[1:n-1]
    for k=2:n
      constrclaus26[k - 1] = @constraint(m, sum(y[1, i, k] for i=1:n) == 1)
    end

    @constraintref constrclaus27[1:n-1]
    for k=2:n
      constrclaus26[k - 1] = @constraint(m, sum(y[i, 1, k] for i=1:n) == 0)
    end

    @constraintref constrclaus28[1:n-1]
    for k=2:n
      constrclaus26[k - 1] = @constraint(m, sum(y[i, k, k] for i=1:n) == 1)
    end

    @constraintref constrclaus29[1:n-1]
    for k=2:n
      constrclaus26[k - 1] = @constraint(m, sum(y[k, i, k] for i=1:n) == 0)
    end

    # Use a vector to store the references.
    # It must have a "fake" first element, otherwise push! won't work.
    @constraintref constrclaus30[1:1]
    for j=2:n
      for k=2:n
        if j != k
          push!(
            constrclaus30,
            @constraint(m, sum(y[i, j, k] for i=1:n) - sum(y[j, i, k] for i=1:n) == 0)
          )
        end
      end
    end
    # Remove the "fake" first element.
    deleteat!(constrclaus30, 1)

    for k=2:n
      @constraint(m, y[:, :, k] .<= x)
    end
  end



  ###################
  # BUILD THE MODEL #
  ###################

  # Set the random seed, if available, else use a random value.
  seed == nothing ? srand() : srand(seed)

  # Rename the input variable, for the sake of brevity.
  # number of cities
  n = matrixSize
  # cost matrix
  c = costMatrix

  # If an adjancency matrix is not specified, initilize a full matrix.
  a = adjacencyMatrix == nothing ? ones(n, n) : adjacencyMatrix
  # Set the main diagonal = 0, no self loops allowed in out graph!
  a[diagm(ones(Bool, n))] = 0


  #################
  # MODEL #########
  #################

  if solver == "gurobi"
    m = Model(solver=GurobiSolver())
  else
    m = Model(solver=GLPKSolverMIP())
  end

  # x_ij == 1 iff we go from city "i" to city "j".
  @variable(m, x[i=1:n, j=1:n], Bin)

  # If "useHotStart" is specified, compute the initial solution with an heuristic algorithm.
  if useHotStart == "annealing"
    initialsol = simulatedannealing(n, c, 200, printDetails=printDetails)
    setvalue(x, initialsol)
  elseif useHotStart == "random"
    initialsol = randompick(n, c, 50000, printDetails=printDetails)
    setvalue(x, initialsol)
  elseif useHotStart == "nearest"
    initialsol = neareastneighbour(n, c, printDetails=printDetails)
    setvalue(x, initialsol)
  end

  # If the adjacency matrix is 0 in some value, the corresponding value of x must be 0 too!
  @constraintref adjConstr
  adjConstr = @constraint(m, a .>= x)

  # constraint: each city is left once.
  @constraintref leftOnceConstr
  leftOnceConstr = @constraint(m, (a .* x) * ones(n) .== 1)
  # Same as:
  # @constraintref leftOnceConstr[1:n]
  # for i=1:n
  #   leftOnceConstr[i] = @constraint(m, sum(a[i, j] * x[i, j] for j=1:n) == 1)
  # end

  # constraint: each city is reached once.
  @constraintref reachedOnceConstr
  reachedOnceConstr = @constraint(m, (a .* x)' * ones(n) .== 1)
  # Same as:
  # @constraintref reachedOnceConstr[1:n]
  # for j=1:n
  #   reachedOnceConstr[j] = @constraint(m, sum(a[i, j] * x[i, j] for i=1:n) == 1)
  # end

  # objective function
  @objective(m, Min, sum(c .* a .* x))
  # Same as:
  # @objective(m, Min, sum(sum(c[i, j] * x[i, j] for i=1:n) for j=1:n))

  # Add the subtour removal constraints.
  if subtourConstrType == "mtz"
    add_subtour_constr_mtz()
  elseif subtourConstrType == "fcg"
    add_subtour_constr_fcg()
  else
    add_subtour_constr_claus()
  end

  # Return the model
  return m
end



function solvemodel!(m; printDetails=0)

  if printDetails > 1
    println(m)
  end

  # Solve the problem.
  status = solve(m)

  if printDetails > 0
    println("OPTIMAL TOUR:", getvalue(getvariable(m, :x)))
    println("TOUR COST:", getobjectivevalue(m))
  end

  return status
end


end
