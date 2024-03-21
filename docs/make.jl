using Documenter, TravelingSalesmanExact, Asciicast
using HiGHS

makedocs(;
    modules=[TravelingSalesmanExact],
    authors="Eric P. Hanson",
    repo="https://github.com/ericphanson/TravelingSalesmanExact.jl/blob/{commit}{path}#L{line}",
    sitename="TravelingSalesmanExact.jl",
    format=Documenter.HTML(;
        ansicolor=true,
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ericphanson.github.io/TravelingSalesmanExact.jl",
        assets=Asciicast.assets(),
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ericphanson/TravelingSalesmanExact.jl",
    push_preview=true,
    devbranch="main"
)
