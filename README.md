# TravelingSalesmanExact

[![Build Status](https://github.com/ericphanson/TravelingSalesmanExact.jl/workflows/CI/badge.svg)](https://github.com/ericphanson/TravelingSalesmanExact.jl/actions)
[![Coverage](https://codecov.io/gh/ericphanson/TravelingSalesmanExact.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ericphanson/TravelingSalesmanExact.jl)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ericphanson.github.io/TravelingSalesmanExact.jl/dev)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ericphanson.github.io/TravelingSalesmanExact.jl/stable)

This is a simple Julia package to solve the traveling salesman problem using an
Dantzig-Fulkerson-Johnson algorithm. I learned about this kind of algorithm from
the very nice blog post <http://opensourc.es/blog/mip-tsp> which also has a
[Julia implementation](https://github.com/opensourcesblog/mip_tsp). In the
symmetric case, the implementation in this package uses the symmetry of the
problem to reduce the number of variables, and is similar to the "reduced clustering"
version of the algorithms described by (Pferschy and Staněk, 2017), using TravelingSalesmanHeuristics to warmstart the solves with good solutions, as well as
splitting the problem into subproblems using Clustering.jl to obtain some good
subtour elimination constraints.

While TravelingSalesmanExact is functional and somewhat practical for small problems,
in 2003, [Concorde](https://www.math.uwaterloo.ca/tsp/concorde/benchmarks/bench.html) already could solve much larger problems faster! So we are far away from the state of the art here.
See [Performance](#performance) below for some more details.

See also
[TravelingSalesmanHeuristics.jl](https://github.com/evanfields/TravelingSalesmanHeuristics.jl)
for a Julia implementation of heuristic solutions to the TSP (which will be much
more performant, especially for large problems, although not exact).
Additionally, see
[TravelingSalesmanBenchmarks](https://github.com/ericphanson/TravelingSalesmanBenchmarks.jl)
for one use of this package: generating exact cost values for test-cases to help
tune the heuristics of the aforementioned `TravelingSalesmanHeuristics.jl`.

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

You also need a
[mixed-integer solver](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers)
to do the underlying optimization. For example, `SCIP` is a free, open-source
solver (see <https://github.com/scipopt/SCIP.jl> for the compatible Julia
wrapper) and can be installed by

```julia
] add SCIP
```

`Gurobi` is a commercial wrapper that offers free academic licenses. It has a
compatible Julia wrapper `Gurobi` (<https://github.com/JuliaOpt/Gurobi.jl>) that
can be installed via

```julia
] add Gurobi
```

Note you also need Gurobi itself installed and a license properly configured.

## Performance

See [./tsplib](./tsplib) for some benchmarking results on small problems from [TSPLIB95](http://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/).

![](./tsplib/200.png)

### Examples

![Example](example.svg)

With SCIP:

```julia
using TravelingSalesmanExact, SCIP
set_default_optimizer!(optimizer_with_attributes(SCIP.Optimizer, "limits/maxorigsol" => 100))
n = 50
cities = [ 100*rand(2) for _ in 1:n];
tour, cost = get_optimal_tour(cities; verbose = true)
plot_cities(cities[tour])
```

To use Gurobi, the first few lines can be changed to:

```julia
using TravelingSalesmanExact, Gurobi
const GurobiEnv = Gurobi.Env()
set_default_optimizer!(() -> Gurobi.Optimizer(GurobiEnv, OutputFlag = 0))
```

Note that without the `OutputFlag = 0` argument, Gurobi will print a lot of information about each iteration of the solve.

One can also pass an optimizer to `get_optimal_tour` instead of setting the default for the session, e.g.

```julia
using TravelingSalesmanExact, SCIP
n = 500
cities = [ 100*rand(2) for _ in 1:n];
tour, cost = get_optimal_tour(cities, SCIP.Optimizer; verbose = true)
plot_cities(cities[tour])
```
