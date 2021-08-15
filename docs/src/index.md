# TravelingSalesmanExact.jl

```@index
```

## Example


```@setup 1
using Main: @gif_str
```

```@example 1
gif"""
using TravelingSalesmanExact, GLPK, StableRNGs
rng = StableRNG(12);
set_default_optimizer!(GLPK.Optimizer)
n = 15
cities = [ 100*rand(rng, 2) for _ in 1:n];
tour, cost = get_optimal_tour(cities; verbose=true, slow=true)
plot_cities(cities[tour])
"""
```


## API Reference

```@autodocs
Modules = [TravelingSalesmanExact]
```
