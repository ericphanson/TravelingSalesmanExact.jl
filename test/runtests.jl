using TravelingSalesmanExact, GLPK, Test
set_default_optimizer!(with_optimizer(GLPK.Optimizer))

function test_valid_tour(tour, L)
    @test length(tour) == L
    @test isperm(tour)
    @test tour isa Vector{Int}
end

function tour_cost(tour, cost::AbstractMatrix)
    n = length(tour)
    inc(a) = a == n ? one(a) : a + 1
    s = zero(eltype(cost))
    for (index, city) in enumerate(tour)
        nextcity = tour[inc(index)]
        s += cost[city, nextcity]
    end
    return s
end

function tour_cost(tour, cities :: AbstractVector; distance = TravelingSalesmanExact.euclidean_distance)
    n = length(cities)
    cost = [ distance(cities[i], cities[j]) for i = 1:n, j=1:n ]
    return tour_cost(tour, cost)
end

function test_tour(input, opt = TravelingSalesmanExact.get_default_optimizer(); kwargs...)
    t, c = get_optimal_tour(input, opt; kwargs...)
    test_valid_tour(t, size(input, 1))
    if :distance in keys(kwargs)
        @test c ≈ tour_cost(t, input; distance = kwargs[:distance])
    else
        @test c ≈ tour_cost(t, input)
    end
    return t, c
end


@testset "Small random asymmetric" begin
    # chosen via rand(5,5)
    cost = 10*[0.474886 0.350983 0.262651 0.138455 0.904042; 0.683586 0.922968 0.278874 0.408406 0.0224372; 0.513651 0.778167 0.140392 0.981211 0.891122; 0.20529 0.976361 0.784706 0.98504 0.385203; 0.489131 0.783738 0.538762 0.998821 0.0324331]
    t1, c1 = test_tour(cost; verbose = true)
    t2, c2 = test_tour(cost; verbose = false)
    @test c1 ≈ c2

    # incorrect `symmetric` should give the wrong answers
    t3, c3 = get_optimal_tour(cost; verbose = false, symmetric = true)
    test_valid_tour(t3, 5)
    @test !(c2 ≈ c3) 
    @test !(c3 ≈ tour_cost(t3, cost))
end

@testset "Small random symmetric" begin
    cost = 10*[0.474886 0.350983 0.262651 0.138455 0.904042; 0.683586 0.922968 0.278874 0.408406 0.0224372; 0.513651 0.778167 0.140392 0.981211 0.891122; 0.20529 0.976361 0.784706 0.98504 0.385203; 0.489131 0.783738 0.538762 0.998821 0.0324331]
    cost_sym = cost + transpose(cost)
    t4, c4 = test_tour(cost_sym; verbose = false)
    t5, c5 = test_tour(cost_sym; symmetric = true, verbose = false)
    t6, c6 = test_tour(cost_sym; symmetric = false, verbose = true)
    @test c4 ≈ c5    
    @test c5 ≈ c6
end

@testset "Small random cities" begin
    # cities = [ 100*rand(2) for _ in 1:5]
    cities = Array{Float64,1}[[48.8885, 41.0517], [35.6635, 12.1844], [95.6122, 15.9847], [67.5772, 9.54407], [16.6325, 51.9001]]
    t7, c7 = test_tour(cities; verbose = false)
    t8, c8 = @inferred test_tour(cities; verbose = false, symmetric = false)
    cost = [ TravelingSalesmanExact.euclidean_distance(c1, c2) for c1 in cities, c2 in cities ]
    t9, c9 = test_tour(cost; verbose = false, symmetric = false)
    t10, c10 = test_tour(cost; verbose = false, symmetric = true)
    @test c7 ≈ c8
    @test c8 ≈ c9
    @test c9 ≈ c10
    @test c8 isa Float64

end

@testset "Exceptions" begin
    cost = rand(5,4)
    @test_throws ArgumentError test_tour(cost)

    cost = rand(5,5)
    TravelingSalesmanExact.reset_default_optimizer!()
    @test_throws ArgumentError test_tour(cost)
    set_default_optimizer!(with_optimizer(GLPK.Optimizer))
end

@testset "att48.tsp" begin
    cities = simple_parse_tsp(joinpath(@__DIR__, "att48.tsp"))
    sym_tour, sym_cost = test_tour(cities; distance = TravelingSalesmanExact.ATT, verbose = true)
    @test sym_cost ≈ 10628

    asym_tour, asym_cost = test_tour(cities; distance = TravelingSalesmanExact.ATT, symmetric = false)
    @test asym_cost ≈ 10628 
end
