using TravelingSalesmanExact
using Test

function test_tour(tour, L)
    @test length(tour) == L
    @test isperm(tour)
    @test tour isa Vector{Int}
end

@testset "att48.tsp" begin
    cities = simple_parse_tsp(joinpath(@__DIR__, "att48.tsp"))
    sym_tour, sym_cost = get_optimal_tour(cities; distance = TravelingSalesmanExact.ATT, verbose = true)
    @test sym_cost ≈ 10628
    test_tour(sym_tour, 48)

    asym_tour, asym_cost = get_optimal_tour(cities; distance = TravelingSalesmanExact.ATT, symmetric = false)
    @test asym_cost ≈ 10628 
    test_tour(asym_tour, 48)
end

@testset "Small random" begin
    # chosen via rand(5,5)
    cost = 10*[0.474886 0.350983 0.262651 0.138455 0.904042; 0.683586 0.922968 0.278874 0.408406 0.0224372; 0.513651 0.778167 0.140392 0.981211 0.891122; 0.20529 0.976361 0.784706 0.98504 0.385203; 0.489131 0.783738 0.538762 0.998821 0.0324331]
    t1, c1 = get_optimal_tour(cost; verbose = true)
    t2, c2 = get_optimal_tour(cost; verbose = false)
    t3, c3 = get_optimal_tour(cost; verbose = false, symmetric = true)
    @test c1 ≈ c2
    @test !(c2 ≈ c3) # incorrect `symmetric` should give the wrong answer

    cost_sym = cost + transpose(cost)
    t4, c4 = get_optimal_tour(cost_sym; verbose = false)
    t5, c5 = get_optimal_tour(cost_sym; symmetric = true, verbose = false)
    t6, c6 = get_optimal_tour(cost_sym; symmetric = false, verbose = false)
    @test c4 ≈ c5    
    @test c5 ≈ c6

    # cities = [ 100*rand(2) for _ in 1:5]
    cities = Array{Float64,1}[[48.8885, 41.0517], [35.6635, 12.1844], [95.6122, 15.9847], [67.5772, 9.54407], [16.6325, 51.9001]]
    t7, c7 = get_optimal_tour(cities; verbose = false)
    t8, c8 = @inferred get_optimal_tour(cities; verbose = false, symmetric = false)
    cost = [ TravelingSalesmanExact.euclidean_distance(c1, c2) for c1 in cities, c2 in cities ]
    t9, c9 = get_optimal_tour(cost; verbose = false, symmetric = false)
    t10, c10 = get_optimal_tour(cost; verbose = false, symmetric = true)
    @test c7 ≈ c8
    @test c8 ≈ c9
    @test c9 ≈ c10
    @test c8 isa Float64

    test_tour(t1, 5)
    test_tour(t2, 5)
    test_tour(t3, 5)
    test_tour(t4, 5)
    test_tour(t5, 5)
    test_tour(t6, 5)
    test_tour(t7, 5)
    test_tour(t8, 5)
    test_tour(t9, 5)
end

@testset "Exceptions" begin
    cost = rand(5,4)
    @test_throws ArgumentError get_optimal_tour(cost)
end