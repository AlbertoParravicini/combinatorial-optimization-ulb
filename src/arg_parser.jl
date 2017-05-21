module ArgumentParser

using ArgParse

export parseArgs

function parseArgs(args)
  # initialize the settings (the description is for the help-screen)
  s = ArgParseSettings(description = "Asymmetric Travelling Salesman Problem (ATSP) Solver.\n" *
                      "The program solves to optimality the provided ATSP instance by employing Combinatorial Optimization.",
                      version="Version 0.1", add_version=true)

  @add_arg_table s begin
      "--instancename", "-i"
          required = true
          help = "Name of the ATSP instance to be solved.\n The file is assumed to be located in the 'instances' folder."
      "--randomseed", "-r"
          nargs = '?'
          arg_type = UInt32
          help = "Value that will be used as seed of the random number generator."
      "--solver", "-s"
          nargs = '?'
          default = "gurobi"
          constant = "gurobi"
          help = "Name of the solver that will be used;\n choose between 'gurobi' and 'glpk';\n note that Gurobi requires a license to be used!"
      "--constraints", "-c"
          nargs = '?'
          default = "claus"
          constant = "claus"
          help = "Type of subtour elimination constraints used in the model;\n choose between 'mtz', 'fcg', 'claus'."
      "--usehotstart"
            nargs = '?'
            default = "none"
            constant = "none"
            help = "Compute the initial solution using the specified heuristic algorithm;\n choose between 'none', 'random', 'annealing'."
      "--printlevel", "-p"
          nargs = '?'
          default = 0
          constant = 0
          arg_type = Int64
          help = "Amount of details that will be printed by the solver;\n it takes an integer value >= 0;\n higher values will print more details."
      "--drawgraph", "-d"
          nargs = '?'
          default = false
          constant = false
          arg_type = Bool
          help = "If true, draws the graph corresponding to the given instance, and highlights the optimal tour;\n the optimal tour is also drawn on a separate file."
      "--saveresult", "-v"
          nargs = '?'
          default = false
          constant = false
          arg_type = Bool
          help = "If true, the variable values are stored in a file, and the statistics of the computation are appended to the file 'results.csv'"
  end

  # Add an epilogue to the help-screen
  s.epilog = """
        Examples:\n
        \n
        julia main.jl -i 1.atsp -r 69 --constraints mtz -d true -p 2\n
        """

  parsed_args = parse_args(args, s)
  return parsed_args
end

end
