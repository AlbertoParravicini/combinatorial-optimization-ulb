module Plotter

using Colors
using LightGraphs
using GraphPlot
using Compose
using JuMP

export drawgraph

"""
Draw  the graph associated to the solution.
The arcs used in the solution are highlighted.
The graphs are saved as SVG files, with their names based on the problem instance name.

:param adjacencyMatrix: adjacency matrix of the graph.
:param solutionMatrix: JuMP variables matrix.
:param instanceName: name of the instance that was solved.
"""
function drawgraph(adjacencyMatrix, solutionMatrix, instanceName, costMatrix)
  a = adjacencyMatrix
  x = solutionMatrix
  c = costMatrix

  h = Graph(a)

  # Get the solution
  sol = getvalue(x)
  # Turn it into am adjacency matrix, for plotting.
  sol = (sol + sol') / 2 .>= 0.5
  solg = Graph(sol)

  # Create an array where, for each edge,
  # we say if it is in the optimal tour (value = 2) or not (value = 1).
  # These values are used to appropriately color the edges of the graph.
  in_tour = []
  for e1 in edges(h)
    found = 1
    for e2 in edges(solg)
      if e1 == e2
        found = 2
      end
    end
    push!(in_tour, found)
  end
  edgecolor = [colorant"lightgray", colorant"orange"]
  # membership color
  edgestrokec = edgecolor[in_tour]

  # Add the costs to the arcs
  edgeLabel = []
  for e in edges(h)
    push!(edgeLabel, c[e[1], e[2]])
  end

  draw(
    SVG(string("./img/graph_", instanceName, ".svg"), 20cm, 20cm),
    gplot(h, nodelabel=h.vertices, edgelabel=edgeLabel, edgestrokec=edgestrokec, layout=circular_layout)
  )


   # Add the costs to the arcs
   edgeLabel = []
   for e in edges(solg)
     push!(edgeLabel, c[e[1], e[2]])
   end
   # Draw just the optimal tour, useful to see if we really have a tour.
   draw(
    SVG(string("./img/graph_", instanceName, "_sol.svg"), 20cm, 20cm),
    gplot(solg, nodelabel=solg.vertices, edgelabel=edgeLabel)
  )
end

end
