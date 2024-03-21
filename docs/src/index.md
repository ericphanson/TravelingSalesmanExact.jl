# TravelingSalesmanExact.jl

```@index
```

## Example

```@cast
using TravelingSalesmanExact, HiGHS
set_default_optimizer!(HiGHS.Optimizer)
cities = TravelingSalesmanExact.get_ATT48_cities();
distance = TravelingSalesmanExact.ATT;
tour, cost = get_optimal_tour(cities; distance, verbose=true, slow=true)
```


## API Reference

```@autodocs
Modules = [TravelingSalesmanExact]
```
