# Name of the file to open.
instanceName = "1.atsp"
filename = string("./instances/", instanceName)

# Open the file.
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









using JuMP
using GLPKMathProgInterface

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

using JuMP, Gurobi

m = Model(solver=GurobiSolver(Presolve=0))

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


###################
# MTZ CONSTRAINTS #
###################

# @variable(m, u[i=2:n])
#
# @constraintref subtourmtz[1:(n-1)^2]
# for i=2:n
#   for j=2:n
#     subtourmtz[(n-1) * (i-2) + (j-1)] = @constraint(m, (n - 1) * x[i, j] + u[i] - u[j] <= n - 2)
#   end
# end

#####################
# CLAUS CONSTRAINTS #
#####################

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


############
# SOLVE ####
############

println(m)

status = solve(m)

println("OPTIMAL TOUR:", getvalue(x))
println("TOUR COST:", getobjectivevalue(m))


##########
# PLOT ###
##########

using LightGraphs
using GraphPlot
using Compose

h = Graph(a)
draw(SVG(string("img/graph_", instanceName, ".svg"), 16cm, 16cm), gplot(h, nodelabel=h.vertices))

# Get the solution
sol = getvalue(x)
# Turn it into am adjacency matrix, for plotting.
sol = (sol + sol') / 2 .>= 0.5
solg = Graph(sol)
draw(SVG(string("img/graph_", instanceName, "_sol.svg"), 16cm, 16cm), gplot(solg, nodelabel=solg.vertices))
