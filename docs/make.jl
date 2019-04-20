using Documenter, TravelingSalesmanExact

makedocs(;
    modules=[TravelingSalesmanExact],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/ericphanson/TravelingSalesmanExact.jl/blob/{commit}{path}#L{line}",
    sitename="TravelingSalesmanExact.jl",
    authors="Eric",
    assets=nothing,
)

deploydocs(;
    repo="github.com/ericphanson/TravelingSalesmanExact.jl",
)
