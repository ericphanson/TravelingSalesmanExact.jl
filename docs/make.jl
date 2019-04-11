using Documenter, TSP_MIP

makedocs(;
    modules=[TSP_MIP],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/ericphanson/TSP_MIP.jl/blob/{commit}{path}#L{line}",
    sitename="TSP_MIP.jl",
    authors="Eric",
    assets=[],
)

deploydocs(;
    repo="github.com/ericphanson/TSP_MIP.jl",
)
