using Documenter, TravelingSalesmanExact

using Conda, UUIDs
env = :asciinema
Conda.pip_interop(true, env)
Conda.pip("install", "asciinema", env)

asciinema = joinpath(Conda.python_dir(env), "asciinema")

cast_dir = joinpath(@__DIR__, "src", "assets", "gifs")
ispath(cast_dir) || mkpath(cast_dir)

function record(commands, name)
    config_dir = mktempdir()
    config_file = joinpath(config_dir, "config")
    open(config_file, write=true) do io
        println(io, """
        [record]

        command = clear -x && julia --startup-file=no -q

        """)

    end
    path = string(name, ".cast")
    isfile(path) && (@info "Rming"; rm(path))
    @info "Generating $name" commands
    io = IOBuffer()
    write(io, commands)
    endswith(commands, '\n') || write(io, '\n')
    write(io, 0x4) # write ctrl-d to exit the process and end the cast
    seekstart(io)
    run(pipeline(addenv(`$asciinema rec $path --overwrite`, "ASCIINEMA_CONFIG_HOME" => config_dir,
    "JULIA_PROJECT" => Base.active_project()); stdin=io))
    return nothing
end

macro gif_str(commands)
    name  = string(uuid5(UUID("faedbbc1-c8d1-4dfe-aa46-8b80407bf145"), commands))
    path = joinpath(cast_dir, name)
    isfile(path) || record(commands, path)
    relative_path = "./assets/gifs/$(name).cast"
    return HTML("""<asciinema-player src="$relative_path" idle-time-limit="2" autoplay="true" start-at="0.25"></asciinema-player >""")
end

makedocs(;
    modules=[TravelingSalesmanExact],
    authors="Eric P. Hanson",
    repo="https://github.com/ericphanson/TravelingSalesmanExact.jl/blob/{commit}{path}#L{line}",
    sitename="TravelingSalesmanExact.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ericphanson.github.io/TravelingSalesmanExact.jl",
        assets=[asset("https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/2.6.1/asciinema-player.min.js"),
                asset("https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/2.6.1/asciinema-player.min.css")],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

cp(cast_dir, joinpath(@__DIR__, "build", "assets", "gifs"); force=true)

deploydocs(;
    repo="github.com/ericphanson/TravelingSalesmanExact.jl",
)
