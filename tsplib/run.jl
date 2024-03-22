using TravelingSalesmanExact, SCIP, TSPLIB, CairoMakie, CSV
using AlgebraOfGraphics, Dates
using InteractiveUtils
using ArgCheck
using JuMP

MAX_NUM_CITIES = 200
set_default_optimizer!(SCIP.Optimizer)

# set_default_optimizer!(optimizer_with_attributes(HiGHS.Optimizer, "time_limit" => 120))

problems = []
for name in readdir(TSPLIB.TSPLIB95_path)
    endswith(name, ".tsp") || continue
    name = first(split(name, "."))
    n_cities = parse(Int, match(r"^[a-zA-Z]*([0-9]*)$", name)[1])
    n_cities > MAX_NUM_CITIES && continue
    @info "Loading $name"
    p = readTSPLIB(Symbol(name))
    push!(problems, p)
end
sort!(problems; by=p -> p.dimension)

# Warmup:
get_optimal_tour(first(problems).weights)

results = []
for tsp in problems
    (tour, cost), timing... = @timed get_optimal_tour(tsp.weights)
    optimal = cost ≈ tsp.optimal
    @info "Solved $(tsp.name)" optimal timing.time cost tsp.optimal
    @check optimal
    push!(results, (; tsp.name, tsp.dimension, optimal, timing...))
end

CSV.write("$(today())-results.csv", results)

@check all(row.optimal for row in results)

open("$(today())-metadata.txt"; write=true) do io
    println(io, "Version info:")
    versioninfo(io)
    println(io)
    println(io, "Manifest:")
    println(io)
    write(io, read("Manifest.toml"))
end

function save_plot(file, results)
    group = :name => "Problem name"
    plt = data(results) * mapping(:dimension => "Number of cities", :time => "Time (seconds)"; color=group, marker=group) * visual(Scatter)
    save(file, draw(plt; figure=(; size=(960, 540)), legend=(; position=:bottom, nbanks=6)); px_per_unit=4)
end

save_plot("$(MAX_NUM_CITIES).png", results)
save_plot("50.png", [row for row in results if row.dimension <= 50])
