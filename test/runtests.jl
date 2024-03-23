using TravelingSalesmanExact, Test, GLPK, HiGHS
using TravelingSalesmanExact: format_time

if Sys.iswindows()
    set_default_optimizer!(HiGHS.Optimizer)
else
    using SCIP
    set_default_optimizer!(SCIP.Optimizer)
end

function test_valid_tour(tour, L)
    @test length(tour) == L
    @test isperm(tour)
    @test tour isa Vector{Int}
end

function tour_cost(tour, cost::AbstractMatrix)
    s = zero(eltype(cost))
    for (index, city) in enumerate(tour)
        nextcity = tour[mod1(index + 1, end)]
        s += cost[city, nextcity]
    end
    return s
end

function tour_cost(tour,
                   cities::AbstractVector;
                   distance=TravelingSalesmanExact.euclidean_distance,)
    n = length(cities)
    cost = [distance(cities[i], cities[j]) for i in 1:n, j in 1:n]
    return tour_cost(tour, cost)
end

function test_tour(input, opt=TravelingSalesmanExact.get_default_optimizer(); kwargs...)
    t, c = get_optimal_tour(input, opt; kwargs...)
    test_valid_tour(t, size(input, 1))
    if :distance in keys(kwargs)
        @test c ≈ tour_cost(t, input; distance=kwargs[:distance])
    else
        @test c ≈ tour_cost(t, input)
    end
    return t, c
end

@testset "`format_time`" begin
    @test format_time(0.052342) == "0.0523 seconds"
    @test format_time(0.452342) == "0.452 seconds"
    @test format_time(1000.452342) == "1000 seconds"
    @test format_time(1.452342) == "1.45 seconds"
end

@testset "Small random asymmetric" begin
    # chosen via rand(5,5)
    cost = 10 *
           [0.474886 0.350983 0.262651 0.138455 0.904042;
            0.683586 0.922968 0.278874 0.408406 0.0224372;
            0.513651 0.778167 0.140392 0.981211 0.891122;
            0.20529 0.976361 0.784706 0.98504 0.385203;
            0.489131 0.783738 0.538762 0.998821 0.0324331]
    t1, c1 = test_tour(cost; verbose=true)
    t2, c2 = test_tour(cost; verbose=false)
    t3, c3 = test_tour(cost, GLPK.Optimizer; verbose=false, lazy_constraints=true,
                       heuristic_warmstart=false)
    @test c1 ≈ c2
    @test c2 ≈ c3
end

@testset "Medium random asymmetric" begin
    cost = 10 * rand(15, 15)
    t1, c1 = test_tour(cost; verbose=false)
    t2, c2 = test_tour(cost, GLPK.Optimizer; verbose=true, lazy_constraints=true,
                       heuristic_warmstart=false)
    @test c1 ≈ c2
end

@testset "Small random symmetric" begin
    cost = 10 *
           [0.474886 0.350983 0.262651 0.138455 0.904042;
            0.683586 0.922968 0.278874 0.408406 0.0224372;
            0.513651 0.778167 0.140392 0.981211 0.891122;
            0.20529 0.976361 0.784706 0.98504 0.385203;
            0.489131 0.783738 0.538762 0.998821 0.0324331]
    cost_sym = cost + transpose(cost)
    t4, c4 = test_tour(cost_sym; verbose=false)
    t5, c5 = test_tour(cost_sym; symmetric=true, verbose=false)
    t6, c6 = test_tour(cost_sym; symmetric=false, verbose=false)
    t7, c7 = test_tour(cost_sym, GLPK.Optimizer; symmetric=false, verbose=true,
                       lazy_constraints=true, heuristic_warmstart=false)
    @test c4 ≈ c5
    @test c5 ≈ c6
    @test c6 ≈ c7
end

@testset "Small random cities" begin
    # cities = [ 100*rand(2) for _ in 1:5]
    cities = Array{Float64,1}[[48.8885, 41.0517],
                              [35.6635, 12.1844],
                              [95.6122, 15.9847],
                              [67.5772, 9.54407],
                              [16.6325, 51.9001]]
    t7, c7 = test_tour(cities; verbose=true)
    t8, c8 = test_tour(cities; verbose=false, symmetric=false)
    cost = [TravelingSalesmanExact.euclidean_distance(c1, c2)
            for c1 in cities, c2 in cities]
    t9, c9 = test_tour(cost; verbose=false, symmetric=false)
    t10, c10 = test_tour(cost; verbose=false, symmetric=true)
    @test c7 ≈ c8
    @test c8 ≈ c9
    @test c9 ≈ c10
    @test c8 isa Float64
end

@testset "Medium random cities" begin
    # cities = [ 100*rand(2) for _ in 1:15]
    cities = Array{Float64,1}[[53.80996646037832, 19.19022341362766],
                              [66.31428678667224, 61.80858818555463],
                              [36.353148448445616, 41.255152847278474],
                              [90.27061139767463, 6.978822544781482],
                              [53.764677734646504, 29.81193167526588],
                              [99.44803233011115, 66.55866205554817],
                              [38.928236331570986, 18.22266760966855],
                              [21.194033394576728, 56.14389699364914],
                              [6.430489908372161, 92.08608470530129],
                              [67.01950679275805, 53.82196541323463],
                              [57.04078593130859, 88.74875672836768],
                              [40.91801899608445, 23.47673907020007],
                              [8.889246634653713, 44.183494522157886],
                              [82.70468776751652, 74.73476674725042],
                              [8.637366704185245, 87.23819026270408]]
    t7, c7 = test_tour(cities, GLPK.Optimizer; verbose=true, lazy_constraints=true,
                       heuristic_warmstart=false)
    t8, c8 = test_tour(cities; verbose=false, symmetric=false)
    cost = [TravelingSalesmanExact.euclidean_distance(c1, c2)
            for c1 in cities, c2 in cities]
    t9, c9 = test_tour(cost; verbose=false, symmetric=false)
    t10, c10 = test_tour(cost; verbose=false, symmetric=true)
    @test c7 ≈ c8
    @test c8 ≈ c9
    @test c9 ≈ c10
    @test c8 isa Float64
end

@testset "Exceptions" begin
    cost = rand(5, 4)
    @test_throws ArgumentError test_tour(cost)

    cost = rand(5, 5)
    TravelingSalesmanExact.reset_default_optimizer!()
    @test_throws ArgumentError test_tour(cost)
    set_default_optimizer!(HiGHS.Optimizer)
end

@testset "att48.tsp" begin
    cities = simple_parse_tsp(joinpath(@__DIR__, "..", "data", "att48.tsp"))

    @test cities == TravelingSalesmanExact.get_ATT48_cities()

    sym_tour, sym_cost = test_tour(cities, HiGHS.Optimizer;
                                   distance=TravelingSalesmanExact.ATT)

    @test sym_cost ≈ 10628

    asym_tour, asym_cost = test_tour(cities;
                                     distance=TravelingSalesmanExact.ATT,
                                     symmetric=false,)
    @test asym_cost ≈ 10628

    sym_tour, sym_cost = test_tour(cities;
                                   distance=TravelingSalesmanExact.ATT,
                                   verbose=true,
                                   slow=true,)
    @test sym_cost ≈ 10628
end
