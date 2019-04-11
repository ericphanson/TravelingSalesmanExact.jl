module TSP_MIP

using JuMP, GLPK, UnicodePlots
import MathOptInterface
const MOI = MathOptInterface

export get_optimal_tour, plot_cities, simple_parse_tsp

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
    while true
        next_ind = findfirst(==(1.0), @views(perm_matrix[cycle[end], :]))        
        next_ind == starting_ind && break
        push!(cycle, next_ind)
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
    remove_cycles!(m, tour_matrix,

Find the (non-maximal-length) cycles in the current solution `tour_matrix`
and add constraints to the JuMP model to disallow them. Returns the
number of cycles found.
"""
function remove_cycles!(m, tour_matrix)
    tour_matrix_val = value.(tour_matrix)
    cycles = get_cycles(tour_matrix_val)
    length(cycles) == 1 && return 1
    for cycle in cycles
        @constraint(m, sum(tour_matrix[cycle, cycle]) <= length(cycle)-1)
    end
    return length(cycles)
end

euclidean_distance(city1, city2) = sqrt((city1[1] - city2[1])^2 + (city1[2] - city2[2])^2)

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
    get_optimal_tour(cost_matrix)

Solves the travelling salesman problem for a list of cities using
JuMP by formulating a MILP using the Dantzig-Fulkerson-Johnson
formulation and adaptively adding constraints to disallow non-maximal
cycles. Returns an optimal tour.
"""
function get_optimal_tour(cities::AbstractVector; distance = euclidean_distance)
    N = length(cities)

    m = Model(with_optimizer(GLPK.Optimizer))

    # `tour_matrix` will be a permutation matrix
    @variable(m, tour_matrix[1:N,1:N], binary=true)
    
    # cost of the tour
    @objective(m, Min, sum(tour_matrix[i,j]*distance(cities[i], cities[j]) for i=1:N,j=1:N))

    for i = 1:N
        @constraint(m, sum(tour_matrix[i,:]) == 1) # permutation matrix constraint
        @constraint(m, sum(tour_matrix[:,i]) == 1) # permutation matrix constraint
        @constraint(m, tour_matrix[i,i] == 0) # rule out cycles of length 1
        for j = 1:N
            @constraint(m, tour_matrix[i,j]+tour_matrix[j,i] <= 1) # rule out cycles of length 2
        end
    end
    @info "Starting optimization." plot_cities(cities)
    iter = 0
    num_cycles = 2 # just something > 1
    tot_cycles = 0
    while num_cycles > 1
        t = @elapsed optimize!(m)
        iter += 1
        num_cycles = remove_cycles!(m, tour_matrix)
        tot_cycles += num_cycles
        @info "Iteration $iter took $(round(t, digits=3))s, disallowed $num_cycles cycles." plot_tour(cities, value.(tour_matrix))
    end
    tot_cycles -= 1 # remove the true cycle

    status = termination_status(m)
    status == MOI.OPTIMAL || @warn(status)

    @info "Optimization finished; adaptively disallowed $tot_cycles cycles."
    @info "Final path has length $(objective_value(m))." 
    @info "Final problem has $(length(m.variable_to_zero_one)) binary variables, $(num_constraints(m, GenericAffExpr{Float64,VariableRef}, MOI.LessThan{Float64})) inequality constraints, and $(num_constraints(m, GenericAffExpr{Float64,VariableRef}, MOI.EqualTo{Float64})) equality constraints."
    return (tour = find_cycle(value.(tour_matrix)), cost = objective_value(m))
end

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