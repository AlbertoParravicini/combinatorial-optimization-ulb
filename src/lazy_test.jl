using JuMP
using GLPKMathProgInterface, Gurobi

##################
# PARSE INSTANCE #
##################


# Name of the file to open.
instanceName = "9.atsp"
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
close(f)




#################
# PARAMETERS ####
#################

# RNG seed
srand(1234)

# number of cities
n = matrixSize
# cost matrix
c = costMatrix

# optional:
# binary symmetric matrix that says which cities are connected.
# if full_graph is false, generate a random symmetric binary matrix
full_graph = true
if full_graph
  a = ones(n, n)
else
  a = rand(0:1, n, n)
  a = (a + a') / 2 .> 0.5
end

# Set the main diagonal = 0, no self loops allowed in out graph!
a -= diagm(ones(n))



#################
# MODEL #########
#################

m = Model(solver=GurobiSolver(LazyConstraints=1))

@variable(m, x[i=1:n, j=1:n], Bin)

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



function subtour(cb)
    # Find any set of cities in a subtour
    subtour, subtour_length = findSubtour(n, getvalue(x))

    if subtour_length == n
        # This "subtour" is actually all cities, so we are done
        return
    end

    # Subtour found - add lazy constraint
    # We will build it up piece-by-piece (variable-by-variable)
    arcs_from_subtour = AffExpr()

    for i = 1:n
        if !subtour[i]
            # If this city isn't in subtour, skip it
            continue
        end
        # Want to include all arcs from this city, which is in
        # the subtour, to all cities not in the subtour
        for j = 1:n
            if i == j
                # Self-arc
                continue
            elseif subtour[j]
                # Both ends in same subtour
                continue
            else
                # j isn't in subtour
                arcs_from_subtour += x[i,j]
            end
        end
    end

    # Add the new subtour elimination constraint we built
    @lazyconstraint(cb, arcs_from_subtour >= 1)
end

# findSubtour
# Given a n-by-n matrix representing solution to the relaxed
# undirected TSP problem, find a set of nodes belonging to a subtour
# Input:
#  n        Number of cities
#  sol      n-by-n 0-1 symmetric matrix representing solution
# Outputs:
#  subtour  n length vector of booleans, true iff in a particular subtour
#  subtour_length   Number of cities in subtour (if n, no subtour found)
function findSubtour(n, sol)
    # Initialize to no subtour
    subtour = fill(false,n)
    # Always start looking at city 1
    cur_city = 1
    subtour[cur_city] = true
    subtour_length = 1
    while true
        # Find next node that we haven't yet visited
        found_city = false
        for j = 1:n
            if !subtour[j]
                if sol[cur_city, j] >= 1 - 1e-6
                    # Arc to unvisited city, follow it
                    cur_city = j
                    subtour[j] = true
                    found_city = true
                    subtour_length += 1
                    break  # Move on to next city
                end
            end
        end
        if !found_city
            # We are done
            break
        end
    end
    return subtour, subtour_length
end



addlazycallback(m, subtour)
status = solve(m)

println("OPTIMAL TOUR:", getvalue(x))
println("TOUR COST:", getobjectivevalue(m))
