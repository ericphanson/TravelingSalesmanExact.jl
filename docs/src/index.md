# TravelingSalesmanExact.jl

```@index
```

## Examples

With GLPK:

```julia
using TravelingSalesmanExact, GLPK
set_default_optimizer!(with_optimizer(GLPK.Optimizer))
n = 50
cities = [ 100*rand(2) for _ in 1:n];
tour, cost = get_optimal_tour(cities; verbose = true)
plot_cities(cities[tour])
```

With Mosek:

```julia
using TravelingSalesmanExact, MosekTools
set_default_optimizer!(with_optimizer(Mosek.Optimizer, QUIET = true))

n = 50
cities = [ 100*rand(2) for _ in 1:n];
tour, cost = get_optimal_tour(cities; verbose = true)
plot_cities(cities[tour])
```

Note that without the `QUIET = true` keyword argument to the `with_optimizer` call, Mosek will print a lot of information about each iteration of the solve. One can also pass an optimizer to `get_optimal_tour` instead of setting the default for the session, e.g.

```julia
using TravelingSalesmanExact, GLPK
n = 50
cities = [ 100*rand(2) for _ in 1:n];
tour, cost = get_optimal_tour(cities, with_optimizer(GLPK.Optimizer); verbose = true)
plot_cities(cities[tour])
```


## Functions


```@autodocs
Modules = [TravelingSalesmanExact]
```
