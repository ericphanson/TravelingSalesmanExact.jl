# TSP_MIP

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ericphanson.github.io/TSP_MIP.jl/dev)
[![Build Status](https://travis-ci.com/ericphanson/TSP_MIP.jl.svg?branch=master)](https://travis-ci.com/ericphanson/TSP_MIP.jl)

This is a simple Julia package to solve the travelling saleman problem using an adaptive Dantzig-Fulkerson-Johnson algorithm.

Requires Julia (<https://julialang.org/downloads/>).

To install the package, add the package from GitHub:
```julia
] add https://github.com/ericphanson/TSP_MIP.jl
```

## Usage

```julia
using TSP_MIP
n = 50
cities = [ [rand(1.0:100.0), rand(1.0:100.0)] for _ in 1:n];
results = get_optimal_tour(cities)
```

![Example](example.svg)