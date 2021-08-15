# TravelingSalesmanExact.jl

```@index
```

## Example


```@example
gif = Main.gif"""
using TravelingSalesmanExact, GLPK
set_default_optimizer!(GLPK.Optimizer)
n = 50
cities = [ 100*rand(2) for _ in 1:n];
tour, cost = get_optimal_tour(cities; verbose = true)
plot_cities(cities[tour])
"""
```


## API Reference

```@autodocs
Modules = [TravelingSalesmanExact]
```
