# TSP_MIP

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ericphanson.github.io/TSP_MIP.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ericphanson.github.io/TSP_MIP.jl/dev)
[![Build Status](https://travis-ci.com/ericphanson/TSP_MIP.jl.svg?branch=master)](https://travis-ci.com/ericphanson/TSP_MIP.jl)

To install, add the package from github:
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