# TravelingSalesmanExact.jl

```@index
```

## Example


```@setup 1
using Main: @gif_str
```

```@example 1
gif"""
using TravelingSalesmanExact, GLPK
set_default_optimizer!(GLPK.Optimizer)
cities = TravelingSalesmanExact.get_ATT48_cities();
distance = TravelingSalesmanExact.ATT;
tour, cost = get_optimal_tour(cities; distance, verbose=true, slow=true)
"""
```


## API Reference

```@autodocs
Modules = [TravelingSalesmanExact]
```
