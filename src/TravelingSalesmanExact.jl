module TravelingSalesmanExact

using JuMP, UnicodePlots, Logging, LinearAlgebra, Printf
import MathOptInterface
const MOI = MathOptInterface
export get_optimal_tour,
       plot_cities,
       simple_parse_tsp,
       set_default_optimizer!

# added in Julia 1.2
if VERSION < v"1.2.0-"
    import Base.>
    >(x) = Base.Fix2(>, x)
end

# added in Julia 1.1
if VERSION < v"1.1.0-"
    isnothing(::Any) = false
    isnothing(::Nothing) = true
end

const default_optimizer = Ref{Any}(nothing)

const SLOW_SLEEP = Ref(1.5)

"""
    set_default_optimizer(O)

Sets the default optimizer. For example,

    using GLPK
    set_default_optimizer(GLPK.Optimizer)
"""
set_default_optimizer!(O) = default_optimizer[] = O

"""
    get_default_optimizer()

Gets the default optimizer, which is set by `set_default_optimizer`.
"""
get_default_optimizer() = default_optimizer[]


reset_default_optimizer!() = default_optimizer[] = nothing

"""
    plot_cities(cities)

Uses `UnicodePlots`'s `lineplot` to make a plot of the tour of the cities in
`cities`, in order (including going from the last city back to the first).
"""
function plot_cities(cities)
    loop = [cities[mod1(j+1, end)] for j = 0:length(cities)]
    return lineplot(first.(loop), last.(loop); height=18)
end

"""
    find_cycle(perm_matrix, starting_ind)

Returns the cycle in the permutation described by `perm_matrix` which includes
`starting_ind`.
"""
function find_cycle(perm_matrix, starting_ind = 1)
    cycle = [starting_ind]
    prev_ind = ind = starting_ind
    while true
        # the comparisons `x > (0.5)` should mean `x == 1`. Due to floating point results returned
        # by the solvers, instead we sometimes have `x ≈ 1.0` instead. Since these are binary
        # values, we might as well just compare to 1/2.
        next_ind = findfirst(>(0.5), @views(perm_matrix[ind, 1:prev_ind-1]))
        if isnothing(next_ind)
            next_ind = findfirst(>(0.5), @views(perm_matrix[ind, prev_ind+1:end])) +
                       prev_ind
        end
        next_ind == starting_ind && break
        push!(cycle, next_ind)
        prev_ind, ind = ind, next_ind
    end
    return cycle
end

"""
    get_cycles(perm_matrix)

Returns a list of cycles from the permutation described by `perm_matrix`.
"""
function get_cycles(perm_matrix)
    N = size(perm_matrix, 1)
    remaining_inds = Set(1:N)
    cycles = Vector{Int}[]
    while length(remaining_inds) > 0
        cycle = find_cycle(perm_matrix, first(remaining_inds))
        push!(cycles, cycle)
        setdiff!(remaining_inds, cycle)
    end
    return cycles
end

"""
    show_tour(cities, perm_matrix)

Show a plot of the tour described by `perm_matrix` of the cities in the vector `cities`.
"""
function plot_tour(cities, perm_matrix)
    cycles = get_cycles(perm_matrix)
    tour = reduce(vcat, cycles)
    return plot_cities(cities[tour])
end

"""
    remove_cycles!(model, tour_matrix)

Find the (non-maximal-length) cycles in the current solution `tour_matrix`
and add constraints to the JuMP model to disallow them. Returns the
number of cycles found.
"""
function remove_cycles!(model, tour_matrix; symmetric)
    tour_matrix_val = value.(tour_matrix)
    cycles = get_cycles(tour_matrix_val)
    length(cycles) == 1 && return 1
    for cycle in cycles
        constr = symmetric ? 2 * length(cycle) - 2 : length(cycle) - 1
        @constraint(model, sum(tour_matrix[cycle, cycle]) <= constr)
    end
    return length(cycles)
end

"""
    euclidean_distance(city1, city2)

The usual Euclidean distance measure.
"""
euclidean_distance(city1, city2) = sqrt((city1[1] - city2[1])^2 + (city1[2] - city2[2])^2)

"""
    ATT(city1, city2)

The `ATT` distance measure as specified in TSPLIB:
<http://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/tsp95.pdf>.
"""
function ATT(city1, city2)
    xd = city1[1] - city2[1]
    yd = city1[2] - city2[2]
    r = sqrt((xd^2 + yd^2) / 10.0)
    t = round(Int, r)
    if t < r
        d = t + 1
    else
        d = t
    end
    return d
end

"""
    get_optimal_tour(
        cities::AbstractVector,
        optimizer = get_default_optimizer();
        distance = euclidean_distance,
        kwargs...
    )

    get_optimal_tour(
        cost::AbstractMatrix
        optimizer = get_default_optimizer();
        kwargs...
    )


Solves the travelling salesman problem for a list of cities using JuMP by
formulating a MILP using the Dantzig-Fulkerson-Johnson formulation and
adaptively adding constraints to disallow non-maximal cycles. Returns an optimal
tour and the cost of the optimal path. Optionally specify a distance metric. 

The second argument is mandatory if a default optimizer has not been set (via
`set_default_optimizer`). This argument should be a function which creates an optimizer, e.g.

    get_optimal_tour(cities, GLPK.Optimizer)

There are five boolean optional keyword arguments:

* `verbose` (default: false) indicates whether or not to print lots of information as the algorithm proceeds.
* `symmetric` indicates whether or not the cost matrix is symmetric. By default, `issymmetric` is used to check.
* `lazy_constraints` indicates whether lazy constraints should be used (which requires a [compatible solver](https://www.juliaopt.org/JuMP.jl/v0.21/callbacks/#Available-solvers-1)).
* `slow` artifically sleeps after each solve to slow down the output for visualization purposes. Only takes affect if `verbose==true`.
* `silent_optimizer` calls `JuMP.set_silent` on the resulting model to prevent the optimizer from emitting logging information.

## Example

```jldoctest
julia> using TravelingSalesmanExact, GLPK, LinearAlgebra

julia> set_default_optimizer!(GLPK.Optimizer)
GLPK.Optimizer

julia> cities = [[0, 0], [0, 1], [1, 1], [1, 0]]
4-element Vector{Vector{Int64}}:
 [0, 0]
 [0, 1]
 [1, 1]
 [1, 0]

julia> tour, cost = get_optimal_tour(cities)
([4, 1, 2, 3], 4.0)

julia> cost_matrix = [norm(cities[i] - cities[j]) for i = 1:4, j = 1:4]
4×4 Matrix{Float64}:
 0.0      1.0      1.41421  1.0
 1.0      0.0      1.0      1.41421
 1.41421  1.0      0.0      1.0
 1.0      1.41421  1.0      0.0

julia> tour, cost = get_optimal_tour(cost_matrix)
([4, 1, 2, 3], 4.0)

```
"""
get_optimal_tour

function get_optimal_tour(
    cities::AbstractVector,
    optimizer = get_default_optimizer();
    verbose = false,
    distance = euclidean_distance,
    symmetric = nothing,
    lazy_constraints = false,
    slow=false,
    silent_optimizer=true,
)
    isnothing(optimizer) && throw(ArgumentError("An optimizer is required if a default optimizer has not been set."))
    N = length(cities)
    cost = [distance(cities[i], cities[j]) for i = 1:N, j = 1:N]
    if symmetric === nothing
        symmetric = issymmetric(cost)
    end
    return _get_optimal_tour(cost, optimizer, symmetric, verbose, lazy_constraints, cities, slow, silent_optimizer)
end

function get_optimal_tour(
    cost::AbstractMatrix,
    optimizer = get_default_optimizer();
    verbose = false,
    symmetric = issymmetric(cost),
    lazy_constraints = false,
    slow = false,
    silent_optimizer=true
)
    size(cost, 1) == size(cost, 2) || throw(ArgumentError("First argument must be a square matrix"))
    isnothing(optimizer) && throw(ArgumentError("An optimizer is required if a default optimizer has not been set."))
    return _get_optimal_tour(cost, optimizer, symmetric, verbose, lazy_constraints, nothing, slow, silent_optimizer)
end


function build_tour_matrix(model, cost::AbstractMatrix, symmetric::Bool)
    N = size(cost, 1)
    if symmetric
        # `tour_matrix` has tour_matrix[i,j] = 1 iff cities i and j should be connected
       @variable(model, tour_matrix[1:N, 1:N], Symmetric, binary = true)

       # cost of the tour
       @objective(model, Min, sum(tour_matrix[i, j] * cost[i, j] for i = 1:N, j = 1:i))
       for i = 1:N
           @constraint(model, sum(tour_matrix[i, :]) == 2) # degree of each city is 2
           @constraint(model, tour_matrix[i, i] == 0) # rule out cycles of length 1
       end
   else
       # `tour_matrix` will be a permutation matrix
       @variable(model, tour_matrix[1:N, 1:N], binary = true)
       @objective(model, Min, sum(tour_matrix[i, j] * cost[i, j] for i = 1:N, j = 1:N))
       for i = 1:N
           @constraint(model, sum(tour_matrix[i, :]) == 1) # row-sum is 1
           @constraint(model, sum(tour_matrix[:, i]) == 1) # col-sum is 1
           @constraint(model, tour_matrix[i, i] == 0) # rule out cycles of length 1
           for j = 1:N
               @constraint(model, tour_matrix[i, j] + tour_matrix[j, i] <= 1) # rule out cycles of length 2
           end
       end
   end
   return tour_matrix
end

function format_time(t)
    # I want more decimal digits to print the smaller the number is,
    # but never more than 4 decimal digits.
    # I think `round(t; sigdigits = ...)` might be a way to do
    # something like this, but I couldn't get it to work.
    str = if t > 100
        @sprintf("%.0f", t)
    elseif t > 1
        @sprintf("%.2f", t)
    elseif t > 0.1
        @sprintf("%.3f", t)
    else
        @sprintf("%.4f", t)
    end
    return str * " seconds"
end


function _get_optimal_tour(
    cost::AbstractMatrix,
    optimizer,
    symmetric,
    verbose,
    lazy_constraints,
    cities,
    slow,
    silent_optimizer,
)
    has_cities = !isnothing(cities)

    model = Model(optimizer)
    silent_optimizer && set_silent(model)
    tour_matrix = build_tour_matrix(model, cost, symmetric)

    if has_cities && verbose
        @info "Starting optimization." plot_cities(cities)
    elseif verbose
        @info "Starting optimization."
    end

    # counts for logging
    iter = Ref(0) 
    tot_cycles = Ref(0)
    all_time = Ref(0.0)

    if lazy_constraints
        remove_cycles_callback = make_remove_cycles_callback(model, tour_matrix, has_cities, cities, verbose, symmetric, tot_cycles)
        MOI.set(model, MOI.LazyConstraintCallback(), remove_cycles_callback)
    end
    
    num_cycles = 2 # just something > 1

    while num_cycles > 1
        t = @elapsed optimize!(model)
        all_time[] += t
        status = termination_status(model)
        status == MOI.OPTIMAL || @warn("Problem status not optimal; got status $status")
        num_cycles = remove_cycles!(model, tour_matrix; symmetric = symmetric)
        tot_cycles[] += num_cycles
        iter[] += 1
        if verbose
            if num_cycles == 1
                description = "found a full cycle!"
            else
                description = "disallowed $num_cycles cycles."
            end

            if has_cities
                slow && sleep(max(0, SLOW_SLEEP[] - t))
                @info "Iteration $(iter[]) took $(format_time(t)), $description" plot_tour(
                    cities,
                    value.(tour_matrix),
                )
            else
                @info "Iteration $(iter[]) took $(format_time(t)), $description"
            end
        end
    end
    tot_cycles[] -= 1 # remove the true cycle

    status = termination_status(model)
    status == MOI.OPTIMAL || @warn(status)

    cycles = get_cycles(value.(tour_matrix))
    length(cycles) == 1 || error("Something went wrong; did not elimate all subtours. Please file an issue.")

    if verbose
        slow && sleep(SLOW_SLEEP[])
        obj = objective_value(model)
        obj_string = isinteger(obj) ? @sprintf("%i", obj) : @sprintf("%.2f", obj)
        @info "Optimization finished; adaptively disallowed $(tot_cycles[]) cycles."
        @info "The optimization runs took $(format_time(all_time[])) in total."
        @info "Final path has length $(obj_string)."
        @info "Final problem has $(num_constraints(model, VariableRef, MOI.ZeroOne)) binary variables,
            $(num_constraints(model,
            GenericAffExpr{Float64,VariableRef}, MOI.LessThan{Float64})) inequality constraints, and
            $(num_constraints(model, GenericAffExpr{Float64,VariableRef}, MOI.EqualTo{Float64})) equality constraints."
    end
    return first(cycles), objective_value(model)
end

function make_remove_cycles_callback(model, tour_matrix, has_cities, cities, verbose, symmetric, tot_cycles)
    num_triggers = Ref(0)
    return function remove_cycles_callback(cb_data)
        tour_matrix_val = callback_value.(Ref(cb_data), tour_matrix)

        # We only handle integral solutions
        # Could possibly also find cycles in the integer part of a mixed solution.
        any(x -> !(x ≈ round(Int, x)), tour_matrix_val) && return

        num_triggers[] += 1
        cycles = get_cycles(tour_matrix_val)

        if length(cycles) == 1
            if has_cities && verbose
                @info "Lazy constaint triggered ($(num_triggers[])); found a full cycle!" plot_tour(
                    cities,
                    tour_matrix_val,
                )
            elseif verbose
                @info "Lazy constaint triggered ($(num_triggers[])); found a full cycle!"
            end
            return nothing
        end

        for cycle in cycles
            constr = symmetric ? 2 * length(cycle) - 2 : length(cycle) - 1
            cycle_constraint = @build_constraint( sum(tour_matrix[cycle, cycle]) <= constr)
            MOI.submit(model, MOI.LazyConstraint(cb_data), cycle_constraint)
        end

        num_cycles = length(cycles)
        tot_cycles[] += num_cycles
        if has_cities && verbose
            @info "Lazy constaint triggered ($(num_triggers[])); disallowed $num_cycles cycles." plot_tour(
                cities,
                tour_matrix_val,
            )
        elseif verbose
            @info "Lazy constaint triggered ($(num_triggers[])); disallowed $num_cycles cycles."
        end
    end
    return nothing
end


"""
    simple_parse_tsp(filename; verbose = true)

Try to parse the ".tsp" file given by `filename`. Very simple implementation
just to be able to test the optimization; may break on other files. Returns a
list of cities for use in `get_optimal_tour`.
"""
function simple_parse_tsp(filename; verbose = true)
    cities = Vector{Int}[]
    for line in readlines(filename)
        line = strip(line)
        if startswith(line, '1':'9')
            nums = split(line, " ")
            @assert length(nums) == 3
            x = parse(Int, nums[2])
            y = parse(Int, nums[3])
            push!(cities, [x, y])
        elseif verbose
            println(line)
        end
    end
    return cities
end

"""
    get_ATT48_cities() -> Vector{Vector{Int}}

A simple helper function to get the problem data for the ATT48 TSPLIB problem.

# Example

```jldoctest
julia> using TravelingSalesmanExact, GLPK

julia> cities = TravelingSalesmanExact.get_ATT48_cities()
48-element Vector{Vector{Int64}}:
 [6734, 1453]
 [2233, 10]
 [5530, 1424]
 [401, 841]
 [3082, 1644]
 [7608, 4458]
 [7573, 3716]
 [7265, 1268]
 [6898, 1885]
 [1112, 2049]
 ⋮
 [6271, 2135]
 [4985, 140]
 [1916, 1569]
 [7280, 4899]
 [7509, 3239]
 [10, 2676]
 [6807, 2993]
 [5185, 3258]
 [3023, 1942]

julia> get_optimal_tour(cities, GLPK.Optimizer, distance = TravelingSalesmanExact.ATT)
([5, 42, 24, 10, 45, 35, 4, 26, 2, 29  …  30, 36, 46, 33, 20, 47, 21, 32, 39, 48], 10628.0)

```
"""
function get_ATT48_cities()
    path = joinpath(@__DIR__, "..", "data", "att48.tsp")
    cities = simple_parse_tsp(path; verbose = false)
    return cities
end

end # module
