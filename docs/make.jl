using Documenter, TravelingSalesmanExact

# asciinema install and cache invalidation
using Scratch, Conda, UUIDs
using TOML, Git
env = :asciinema
Conda.pip_interop(true, env)
Conda.pip("install", "asciinema", env)
asciinema = joinpath(Conda.python_dir(env), "asciinema")

# We store casts in a scratch directory, so we don't
# need to rebuild them unless the code changes.
const ASCIINEMA_CAST_DIR = get_scratch!(TravelingSalesmanExact, "gifs")

# We create an asciinema config
# so that we can start Julia in quiet mode
# and clear the screen before starting.
# Otherwise, the contents that we wish to type
# into the Julia session are printed first,
# before the Julia session starts.
const ASCIINEMA_CONFIG_DIR = get_scratch!(TravelingSalesmanExact, "asciinema_config")
open(joinpath(ASCIINEMA_CONFIG_DIR, "config"), write=true) do io
    println(io, """
    [record]

    command = clear -x && julia --startup-file=no -q

    """)
end

function record(commands, path)
    io = IOBuffer()
    write(io, commands)
    # Make sure we press enter after all the commands
    endswith(commands, '\n') || write(io, '\n')
    write(io, 0x4) # write ctrl-d to exit the process and end the cast
    seekstart(io)
    env_dict = Conda._get_conda_env(env)
    env_dict["ASCIINEMA_CONFIG_HOME"] = ASCIINEMA_CONFIG_DIR
    env_dict["JULIA_PROJECT"] = Base.active_project()
    env_dict["TERM"] = "xterm-256color"
    run(pipeline(addenv(`$asciinema rec $path --overwrite`, env_dict); stdin=io))
    return nothing
end

function get_version()
    return VersionNumber(TOML.parsefile(joinpath(dirname(@__DIR__), "Project.toml"))["version"])
end

macro gif_str(commands)
    # When should a gif be invalidated?
    key = if success(`$(git()) rev-parse --git-dir`)
        # in a git repo:
        # if the source code changes, if the commands change, or if the Project.toml changes
    hash((readchomp(`$(git()) rev-parse HEAD:src`), readchomp(`$(git()) rev-parse HEAD:docs/Project.toml`), commands))
    else
        # not in a git repo: when the package version number changes
        hash((get_version(), commands))
    end

    # We use a hash of the commands to name the cast
    filename = string(key, ".cast")

    path = joinpath(ASCIINEMA_CAST_DIR, filename)
    isfile(path) || record(commands, path)
    relative_path = "./assets/gifs/$filename"

    # We start at 0.25 seconds so that we can skip the initial 
    # printing of commands and some of the Julia startup time.
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

# Copy the gifs into the build directory
cp(ASCIINEMA_CAST_DIR, joinpath(@__DIR__, "build", "assets", "gifs"); force=true)

# Very hacky fix to load the asciinema JS before Documenter's require.js
# <https://github.com/JuliaDocs/Documenter.jl/issues/1433>
# Note: we strict compat-bound Documenter in case the version of requires changes in patch releases (which would be totally valid)
req_script = """<script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.6/require.min.js" data-main="assets/documenter.js"></script>"""
asciinema_script = """<script src="https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/2.6.1/asciinema-player.min.js"></script>"""
index_path = joinpath(@__DIR__, "build", "index.html")
index = read(index_path, String)
index = replace(index, asciinema_script => "")
index = replace(index, req_script => asciinema_script*req_script)
write(index_path, index)


deploydocs(;
    repo="github.com/ericphanson/TravelingSalesmanExact.jl",
    push_preview=true,
)
