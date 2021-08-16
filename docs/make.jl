using Documenter, TravelingSalesmanExact, Asciicast

asciinema_version = "2.6.1"
makedocs(;
    modules=[TravelingSalesmanExact],
    authors="Eric P. Hanson",
    repo="https://github.com/ericphanson/TravelingSalesmanExact.jl/blob/{commit}{path}#L{line}",
    sitename="TravelingSalesmanExact.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ericphanson.github.io/TravelingSalesmanExact.jl",
        assets=[asset("https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/$(asciinema_version)/asciinema-player.min.js"),
                asset("https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/$(asciinema_version)/asciinema-player.min.css")],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

# Very hacky fix to load the asciinema JS before Documenter's require.js
# <https://github.com/JuliaDocs/Documenter.jl/issues/1433>
requires_regex = r"""<script src="https://cdnjs\.cloudflare\.com/ajax/libs/require\.js/[0-9]+\.[0-9]+\.[0-9]+/require\.min\.js" data-main="assets/documenter\.js"></script>"""
asciinema_script = """<script src="https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/$(asciinema_version)/asciinema-player.min.js"></script>"""
index_path = joinpath(@__DIR__, "build", "index.html")
index = read(index_path, String)
requires_script = match(requires_regex, index).match # get the right version numbers for requires.js
index = replace(index, asciinema_script => "")
index = replace(index, requires_script => asciinema_script*requires_script)
write(index_path, index)


deploydocs(;
    repo="github.com/ericphanson/TravelingSalesmanExact.jl",
    push_preview=true,
    devbranch="main"
)
