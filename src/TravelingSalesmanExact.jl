module TravelingSalesmanExact

using JuMP, UnicodePlots, Logging, LinearAlgebra
import MathOptInterface
const MOI = MathOptInterface
export get_optimal_tour, plot_cities, simple_parse_tsp, with_optimizer, set_default_optimizer!

≈(x) = Base.Fix2(isapprox, x)

const default_optimizer = Ref{Union{OptimizerFactory, Nothing}}(nothing)

"""
    set_default_optimizer(O::OptimizerFactory)

Sets the default optimizer. For example,

    using GLPK
    set_default_optimizer(with_optimizer(GLPK.Optimizer))
"""

set_default_optimizer!(O::OptimizerFactory) = default_optimizer[] = O

"""
    get_default_optimizer()

Gets the default optimizer, which is set by `set_default_optimizer`.
"""
get_default_optimizer() =  default_optimizer[]


reset_default_optimizer!() =  default_optimizer[] = nothing

"""
    plot_cities(cities)

Uses `UnicodePlots`'s `lineplot` to make a plot of the tour of the cities in `cities`, in order (including going from the last city back to the first).
"""
function plot_cities(cities)
    n = length(cities)
    inc(a) = a == n ? one(a) : a + 1
    lineplot([cities[inc(j)][1] for j = 0:n], [cities[inc(j)][2] for j = 0:n])
end

"""
    find_cycle(perm_matrix, starting_ind)

Returns the cycle in the permutation described by `perm_matrix` which includes `starting_ind`.
"""
function find_cycle(perm_matrix, starting_ind = 1)
    cycle = [starting_ind]
    prev_ind = ind = starting_ind
    while true
        next_ind = findfirst(≈(1.0), @views(perm_matrix[ind, 1:prev_ind-1]))
        if isnothing(next_ind)
            next_ind = findfirst(≈(1.0), @views(perm_matrix[ind, prev_ind+1:end]))  + prev_ind
        end
        next_ind == starting_ind && break
        push!(cycle, next_ind)
        prev_ind, ind = ind, next_ind
    end
    cycle
end

"""
    get_cycles(perm_matrix)

Returns a list of cycles from the permutation described by `perm_matrix`.
"""
function get_cycles(perm_matrix)
    N = size(perm_matrix, 1)
    remaining_inds = Set(1:N)
    cycles = []
    while length(remaining_inds) > 0
        cycle = find_cycle(perm_matrix, first(remaining_inds))
        push!(cycles, cycle)
        setdiff!(remaining_inds, cycle)
    end
    cycles
end

"""
    show_tour(cities, perm_matrix)

Show a plot of the tour described by `perm_matrix` of the cities in the vector `cities`.
"""
function plot_tour(cities, perm_matrix)
    cycles = get_cycles(perm_matrix)
    tour = reduce(vcat, cycles)
    plot_cities(cities[tour])
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
        constr = symmetric ? 2*length(cycle)-2 : length(cycle)-1
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
<https://www.iwr.uni-heidelberg.de/groups/comopt/software/TSPLIB95/tsp95.pdf>.
"""
function ATT(city1, city2)
    xd = city1[1] - city2[1]
    yd = city1[2] - city2[2]
    r = sqrt( (xd^2 + yd^2) /10.0 )
    t = round(Int, r)
    if t < r
        d = t+ 1
    else
        d = t
    end
    return d
end


"""
    get_optimal_tour(cities::AbstractVector, with_optimizer = get_default_optimizer(); verbose = false, distance = euclidean_distance, symmetric = true)

Solves the travelling salesman problem for a list of cities using
JuMP by formulating a MILP using the Dantzig-Fulkerson-Johnson
formulation and adaptively adding constraints to disallow non-maximal
cycles. Returns an optimal tour and the cost of the optimal path. Optionally specify a distance metric. 

The second argument is mandatory if a default optimizer has not been set (via `set_default_optimizer`). This argument should be the result of a call to `JuMP.with_optimizer`, e.g.

    get_optimal_tour(cities, with_optimizer(GLPK.Optimizer))
"""
function get_optimal_tour(cities::AbstractVector, with_optimizer = get_default_optimizer(); verbose = false, distance = euclidean_distance, symmetric = true)
    with_optimizer === nothing && throw(ArgumentError("An optimizer is required if a default optimizer has not been set."))
    N = length(cities)
    cost = [ distance(cities[i], cities[j]) for i=1:N, j=1:N ]
    return _get_optimal_tour(cost, with_optimizer, symmetric, verbose, cities)
end

"""
    get_optimal_tour(cost::AbstractMatrix, with_optimizer = get_default_optimizer(); verbose = false, symmetric = issymmetric(cost))

Solves the travelling salesman problem for a square cost matrix using
JuMP by formulating a MILP using the Dantzig-Fulkerson-Johnson
formulation and adaptively adding constraints to disallow non-maximal
cycles. Returns an optimal tour and the cost of the optimal path.

The second argument is mandatory if a default optimizer has not been set (via `set_default_optimizer`). This argument should be the result of a call to `JuMP.with_optimizer`, e.g.

    get_optimal_tour(cities, with_optimizer(GLPK.Optimizer))
"""
function get_optimal_tour(cost::AbstractMatrix, with_optimizer =  get_default_optimizer(); verbose = false, symmetric = issymmetric(cost))
    size(cost, 1) == size(cost,2) || throw(ArgumentError("First argument must be a square matrix"))
    with_optimizer === nothing && throw(ArgumentError("An optimizer is required if a default optimizer has not been set."))
    return _get_optimal_tour(cost, with_optimizer, symmetric, verbose)
end

function _get_optimal_tour(cost::AbstractMatrix, with_optimizer, symmetric, verbose, cities = nothing)
    N = size(cost,1)
    has_cities = !isnothing(cities)

    model = Model(with_optimizer)
    if symmetric
         # `tour_matrix` has tour_matrix[i,j] = 1 iff cities i and j should be connected
        @variable(model, tour_matrix[1:N,1:N], Symmetric, binary=true)

        # cost of the tour
        @objective(model, Min, sum(tour_matrix[i,j]*cost[i,j] for i=1:N,j=1:i))
        for i = 1:N
            @constraint(model, sum(tour_matrix[i,:]) == 2) # degree of each city is 2
            @constraint(model, tour_matrix[i,i] == 0) # rule out cycles of length 1
        end
    else
        # `tour_matrix` will be a permutation matrix
        @variable(model, tour_matrix[1:N,1:N], binary=true)
        @objective(model, Min, sum(tour_matrix[i,j]*cost[i,j] for i=1:N,j=1:N))
        for i = 1:N
            @constraint(model, sum(tour_matrix[i,:]) == 1) # row-sum is 1
            @constraint(model, sum(tour_matrix[:,i]) == 1) # col-sum is 1
            @constraint(model, tour_matrix[i,i] == 0) # rule out cycles of length 1
            for j = 1:N
                @constraint(model, tour_matrix[i,j]+tour_matrix[j,i] <= 1) # rule out cycles of length 2
            end
         end
    end

   
   if has_cities && verbose
        @info "Starting optimization." plot_cities(cities)
   elseif verbose
        @info "Starting optimization."
   end


    iter = 0 # count for logging
    tot_cycles = 0 # count for logging
    num_cycles = 2 # just something > 1
    while num_cycles > 1
        t = @elapsed optimize!(model)
        status = termination_status(model)
        status == MOI.OPTIMAL || throw(ErrorException("Error: problem status $status"))
        num_cycles = remove_cycles!(model, tour_matrix; symmetric = symmetric)
        tot_cycles += num_cycles
        iter += 1
        if has_cities && verbose
            @info "Iteration $iter took $(round(t, digits=3))s, disallowed $num_cycles cycles." plot_tour(cities, value.(tour_matrix))
        elseif verbose
            @info "Iteration $iter took $(round(t, digits=3))s, disallowed $num_cycles cycles."
        end
    end
    tot_cycles -= 1 # remove the true cycle

    status = termination_status(model)
    status == MOI.OPTIMAL || @warn(status)

    if verbose
        @info "Optimization finished; adaptively disallowed $tot_cycles cycles."
        @info "Final path has length $(objective_value(model))." 
        @info "Final problem has $(length(model.variable_to_zero_one)) binary variables, $(num_constraints(model, GenericAffExpr{Float64,VariableRef}, MOI.LessThan{Float64})) inequality constraints, and $(num_constraints(model, GenericAffExpr{Float64,VariableRef}, MOI.EqualTo{Float64})) equality constraints."
    end
    return find_cycle(value.(tour_matrix)), objective_value(model)
end

"""
    simple_parse_tsp(filename; verbose = true)

Try to parse the ".tsp" file given by `filename`. Very simple implementation just to be able to test the optimization; may break on other files. Returns a list of cities for use in `get_optimal_tour`.
"""
function simple_parse_tsp(filename; verbose = true)
    cities = []
    for line in readlines(filename)
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

end # module