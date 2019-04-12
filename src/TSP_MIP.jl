module TSP_MIP

using JuMP, GLPK, UnicodePlots
import MathOptInterface
const MOI = MathOptInterface
export get_optimal_tour, plot_cities, simple_parse_tsp

≈(x) = Base.Fix2(isapprox, x)

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

# Simpler implementation with slightly more allocations:
# function find_cycle(perm_matrix, starting_ind = 1)
#     cycle = [starting_ind]
#     while true
#         new_inds = findall(≈(1.0), @views(perm_matrix[cycle[end], :]))
#         diff = setdiff(new_inds, cycle)
#         isempty(diff) && break
#         append!(cycle, diff)
#     end
#     cycle
# end

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
    remove_cycles!(model, tour_matrix,

Find the (non-maximal-length) cycles in the current solution `tour_matrix`
and add constraints to the JuMP model to disallow them. Returns the
number of cycles found.
"""
function remove_cycles!(model, tour_matrix)
    tour_matrix_val = value.(tour_matrix)
    cycles = get_cycles(tour_matrix_val)
    length(cycles) == 1 && return 1
    for cycle in cycles
        @constraint(model, sum(tour_matrix[cycle, cycle]) <= 2*length(cycle)-2)
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
    get_optimal_tour(cities::AbstractVector; distance = euclidean_distance, optimizer = GLPK.Optimizer)

Solves the travelling salesman problem for a list of cities using
JuMP by formulating a MILP using the Dantzig-Fulkerson-Johnson
formulation and adaptively adding constraints to disallow non-maximal
cycles. Returns an optimal tour. Optionally specify a distance metric
and an optimizer for JuMP.
"""
function get_optimal_tour(cities::AbstractVector; distance = euclidean_distance, optimizer = GLPK.Optimizer)
    N = length(cities)

    model = Model(with_optimizer(optimizer))

    # `tour_matrix` has tour_matrix[i,j] = 1 iff cities i and j should be connected
    @variable(model, tour_matrix[1:N,1:N], Symmetric, binary=true)
    
    # cost of the tour
    @objective(model, Min, sum(tour_matrix[i,j]*distance(cities[i], cities[j]) for i=1:N,j=1:i))
    for i = 1:N
        @constraint(model, sum(tour_matrix[i,:]) == 2) # degree of each city is 2

        @constraint(model, tour_matrix[i,i] == 0) # rule out cycles of length 1
    end
    @info "Starting optimization." plot_cities(cities)
    iter = 0
    num_cycles = 2 # just something > 1
    tot_cycles = 0
    while num_cycles > 1
        t = @elapsed optimize!(model)
        status = termination_status(model)
        status == MOI.OPTIMAL || throw(ErrorException("Error: problem status $status"))
        iter += 1
        num_cycles = remove_cycles!(model, tour_matrix)
        tot_cycles += num_cycles
        @info "Iteration $iter took $(round(t, digits=3))s, disallowed $num_cycles cycles." plot_tour(cities, value.(tour_matrix))
    end
    tot_cycles -= 1 # remove the true cycle

    status = termination_status(model)
    status == MOI.OPTIMAL || @warn(status)

    @info "Optimization finished; adaptively disallowed $tot_cycles cycles."
    @info "Final path has length $(objective_value(model))." 
    @info "Final problem has $(length(model.variable_to_zero_one)) binary variables, $(num_constraints(model, GenericAffExpr{Float64,VariableRef}, MOI.LessThan{Float64})) inequality constraints, and $(num_constraints(model, GenericAffExpr{Float64,VariableRef}, MOI.EqualTo{Float64})) equality constraints."
    return (tour = find_cycle(value.(tour_matrix)), cost = objective_value(model))
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
        else
            println(line)
        end
    end
    return cities
end

end # module