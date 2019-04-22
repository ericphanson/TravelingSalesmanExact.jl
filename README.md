# TravelingSalesmanExact

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ericphanson.github.io/TravelingSalesmanExact.jl/dev)
[![Build Status](https://travis-ci.com/ericphanson/TravelingSalesmanExact.jl.svg?branch=master)](https://travis-ci.com/ericphanson/TravelingSalesmanExact.jl)
[![codecov](https://codecov.io/gh/ericphanson/TravelingSalesmanExact.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ericphanson/TravelingSalesmanExact.jl)

This is a simple Julia package to solve the travelling saleman problem using an Dantzig-Fulkerson-Johnson algorithm. I learned about this kind of algorithm from the very nice blog post <http://opensourc.es/blog/mip-tsp> which also has a [Julia implementation](https://github.com/opensourcesblog/mip_tsp). In the symmetric case, the implementation in this package uses the symmetry of the problem to reduce the number of variables, and essentially is the most basic version of the algorithms described by (Pferschy and Staněk, 2017) (i.e. no warmstarts or clustering methods for subtour elimination as a presolve step).

See also [TravelingSalesmanHeuristics.jl](https://github.com/evanfields/TravelingSalesmanHeuristics.jl) for a Julia implementation of heuristic solutions to the TSP (which will be much more performant, especially for large problems, although not exact).
Additionally, see [TravelingSalesmanBenchmarks](https://github.com/ericphanson/TravelingSalesmanBenchmarks.jl) for one use of this package: generating exact cost values for test-cases to help tune the heuristics of the aforementioned `TravelingSalesmanHeuristics.jl`.

>Generating subtour elimination constraints for the TSP from pure integer solutions  
>Pferschy, U. & Staněk, R. Cent Eur J Oper Res (2017) 25: 231.  
><https://doi.org/10.1007/s10100-016-0437-8>


>Solution of a Large-Scale Traveling-Salesman Problem  
>G. Dantzig, R. Fulkerson, and S. Johnson, 	J. Oper. Res. Soc. (1954) 2:4, 393-410  
><https://doi.org/10.1287/opre.2.4.393>


## Setup

Requires Julia (<https://julialang.org/downloads/>).

This package is registered, so you can add it via

```julia
] add TravelingSalesmanExact
```

You also need a [mixed-integer solver compatible with JuMP 19+](http://www.juliaopt.org/JuMP.jl/v0.19.0/installation/#Getting-Solvers-1) to do the underlying optimization. For example, `GLPK` is a free, open-source solver (see <https://github.com/JuliaOpt/GLPK.jl> for the compatible Julia wrapper) and can be installed by

```julia
] add GLPK
```

`Gurobi` is a commerical wrapper that offers free academic licenses. It has a compatible Julia wrapper `Gurobi` (<https://github.com/JuliaOpt/Gurobi.jl>)
that can be installed via

```julia
] add Gurobi
```

Note you also need Gurobi itself installed and a license properly configured.

### Examples

![Example](example.svg)

With GLPK:

```julia
using TravelingSalesmanExact, GLPK
set_default_optimizer!(with_optimizer(GLPK.Optimizer))
n = 50
cities = [ 100*rand(2) for _ in 1:n];
tour, cost = get_optimal_tour(cities; verbose = true)
plot_cities(cities[tour])
```

To use Gurobi, the first few lines can be changed to:

```julia
using TravelingSalesmanExact, Gurobi
const GurobiEnv = Gurobi.Env()
set_default_optimizer!(with_optimizer(Gurobi.Optimizer, GurobiEnv, OutputFlag = 0))
```

Note that without the `OutputFlag = 0` keyword argument to the `with_optimizer` call, Gurobi will print a lot of information about each iteration of the solve. 

`Mosek` is another commerical wrapper that offers free academic licenses. It has a compatible Julia wrapper `MosekTools` (<https://github.com/JuliaOpt/MosekTools.jl>). You also need a license properly configured; the older wrapper [Mosek.jl](https://github.com/JuliaOpt/Mosek.jl#installation) offers instructions for this. `Mosek` can be used as e.g.

```julia
using TravelingSalesmanExact, MosekTools
set_default_optimizer!(with_optimizer(Mosek.Optimizer, QUIET = true))
```

One can also pass an optimizer to `get_optimal_tour` instead of setting the default for the session, e.g.

```julia
using TravelingSalesmanExact, GLPK
n = 50
cities = [ 100*rand(2) for _ in 1:n];
tour, cost = get_optimal_tour(cities, with_optimizer(GLPK.Optimizer); verbose = true)
plot_cities(cities[tour])
```

See <https://ericphanson.github.io/TravelingSalesmanBenchmarks.jl/html/random_50_cities_stats.html> for a benchmark comparing the computation time between these solvers on random problems as well as comparing to  that of heuristics.