using JuMP
using GLPKMathProgInterface

#################
# PARAMETERS ####
#################

# RNG seed
srand(1234)

# number of cities
n = 5
# max cost of a path
maxcost = 10
# cost matrix
c = rand(1:maxcost, n, n)

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



#################
# MODEL #########
#################

m = Model(solver=GLPKSolverMIP())

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
@objective(m, Min, sum(c .* x))
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


###################
# FCG CONSTRAINTS #
###################

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


#####################
# CLAUS CONSTRAINTS #
#####################

# @variable(m, y[i=1:n, j=1:n, k=2:n] >= 0)
#
# @constraintref constrclaus26[1:n-1]
# for k=2:n
#   constrclaus26[k - 1] = @constraint(m, sum(y[1, i, k] for i=1:n) == 1)
# end
#
# @constraintref constrclaus27[1:n-1]
# for k=2:n
#   constrclaus26[k - 1] = @constraint(m, sum(y[i, 1, k] for i=1:n) == 0)
# end
#
# @constraintref constrclaus28[1:n-1]
# for k=2:n
#   constrclaus26[k - 1] = @constraint(m, sum(y[i, k, k] for i=1:n) == 1)
# end
#
# @constraintref constrclaus29[1:n-1]
# for k=2:n
#   constrclaus26[k - 1] = @constraint(m, sum(y[k, i, k] for i=1:n) == 0)
# end
#
# # Use a vector to store the references.
# # It must have a "fake" first element, otherwise push! won't work.
# @constraintref constrclaus30[1:1]
# for j=2:n
#   for k=2:n
#     if j != k
#       push!(
#         constrclaus30,
#         @constraint(m, sum(y[i, j, k] for i=1:n) - sum(y[j, i, k] for i=1:n) == 0)
#       )
#     end
#   end
# end
# # Remove the "fake" first element.
# deleteat!(constrclaus30, 1)
#
# for k=2:n
#   @constraint(m, y[:, :, k] .<= x)
# end

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
draw(SVG("graph_test.svg", 16cm, 16cm), gplot(h, nodelabel=h.vertices))

# Get the solution
sol = getvalue(x)
# Turn it into am adjacency matrix, for plotting.
sol = (sol + sol') / 2 .>= 0.5
solg = Graph(sol)
draw(SVG("graph_test_sol.svg", 16cm, 16cm), gplot(solg, nodelabel=solg.vertices))
