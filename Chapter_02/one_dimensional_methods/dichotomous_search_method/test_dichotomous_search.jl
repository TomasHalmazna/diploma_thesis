"""
Unit tests for the Dichotomous Search optimization method.
Includes tests for correctness, edge cases,  error handling, numerical stability, and different δ values.
"""

using Test

include("dichotomous_search_method.jl")

@testset "Dichotomous Search Tests" begin
    # Test 1: Quadratic function (minimum at x = -1)
    @testset "Quadratic function" begin
        f(x) = x^2 + 2x + 1
        x_min, f_min, iterations, _ = dichotomous_search(f, -5.0, 5.0, 1e-6)
        @test isapprox(x_min, -1.0, atol=1e-6)
        @test isapprox(f_min, 0.0, atol=1e-6)
    end

    # Test 2: Fourth-degree polynomial (minimum at x = 0)
    @testset "Fourth-degree polynomial" begin
        f(x) = x^4
        x_min, f_min, iterations, _ = dichotomous_search(f, -2.0, 2.0, 1e-6)
        @test isapprox(x_min, 0.0, atol=1e-6)
        @test isapprox(f_min, 0.0, atol=1e-6)
    end

    # Test 3: Exponential function (minimum at x = 0)
    @testset "Exponential function" begin
        f(x) = exp(x) - x
        x_min, f_min, iterations, _ = dichotomous_search(f, -2.0, 2.0, 1e-6)
        @test isapprox(x_min, 0.0, atol=1e-6)
    end

    # Test 4: Edge cases and error handling
    @testset "Edge cases" begin
        f(x) = x^2
        # Test invalid interval
        @test_throws ErrorException dichotomous_search(f, 5.0, -5.0, 1e-6)
        # Test too large δ
        @test_throws ErrorException dichotomous_search(f, -5.0, 5.0, 1e-6, 6.0)
        # Test non-finite function values
        g(x) = log(0.0)  # This will return -Inf for any input
        @test_throws ErrorException dichotomous_search(g, -1.0, 1.0, 1e-6)
    end

    # Test 5: Different δ values
    @testset "Different δ values" begin
        f(x) = x^2
        # Test with default δ
        x_min1, f_min1, _, _ = dichotomous_search(f, -1.0, 1.0, 1e-6)
        # Test with custom δ
        x_min2, f_min2, _, _ = dichotomous_search(f, -1.0, 1.0, 1e-6, 1e-4)
        # Both should give similar results
        @test isapprox(x_min1, 0.0, atol=1e-6)
        @test isapprox(x_min2, 0.0, atol=1e-6)
    end

    # Test 6: Numerical stability
    @testset "Numerical stability" begin
        f(x) = x^2
        # Test with very small interval
        @test_throws ErrorException dichotomous_search(f, 0.0, 1e-15, 1e-16, 1e-20)
    end
end