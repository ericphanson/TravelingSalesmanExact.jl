using TSP_MIP
using Test

@testset "att48.tsp" begin
    cities = simple_parse_tsp("att48.tsp")
    result = get_optimal_tour(cities; distance = TSP_MIP.ATT)
    @test result.cost ≈ 10628
end
