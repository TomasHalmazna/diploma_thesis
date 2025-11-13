"""
Unit tests for the Golden-Section Search (GSS) algorithm
"""

# Include the GSS implementation
include("golden_section_search.jl")

# Simple test framework
function run_test(test_fn::Function, name::String)
    try
        test_fn()
        println("✓ $name")
        return true
    catch e
        println("✗ $name")
        println("  Error: $e")
        return false
    end
end

function assert_approx(val::Float64, expected::Float64, tol::Float64=1e-6)
    if abs(val - expected) > tol
        throw(AssertionError("Expected ≈ $expected, got $val (difference: $(abs(val - expected)))"))
    end
end

# ============================================================================
# Test Cases
# ============================================================================

tests_passed = 0
tests_total = 0

# Test 1: Simple quadratic
tests_total += 1
tests_passed += run_test("Simple quadratic: (x - 0.3)²") do
    f(x) = (x - 0.3)^2
    res = golden_section_search(f, 0.0, 1.0; tol=1e-8)
    assert_approx(res.xmin, 0.3, 0.001)
    assert_approx(res.fmin, 0.0, 1e-6)
end

# Test 2: Shifted quadratic
tests_total += 1
tests_passed += run_test("Shifted quadratic: (x + 1)²") do
    f(x) = (x + 1)^2
    res = golden_section_search(f, -5.0, 5.0; tol=1e-8)
    assert_approx(res.xmin, -1.0, 0.001)
    assert_approx(res.fmin, 0.0, 1e-6)
end

# Test 3: Quartic function
tests_total += 1
tests_passed += run_test("Quartic: (x - 2)⁴") do
    f(x) = (x - 2)^4
    res = golden_section_search(f, 0.0, 4.0; tol=1e-8)
    assert_approx(res.xmin, 2.0, 0.001)
    assert_approx(res.fmin, 0.0, 1e-6)
end

# Test 4: Cosine function (has minimum at 0 and 2π in [0, 2π])
tests_total += 1
tests_passed += run_test("Cosine: cos(x) on [0, π]" ) do
    f_cos(x) = cos(x)
    res = golden_section_search(f_cos, 0.0, Float64(π); tol=1e-8)
    assert_approx(res.xmin, Float64(π), 0.01)  # Minimum is at x = π
    assert_approx(res.fmin, -1.0, 1e-6)
end

# Test 5: Parabola with narrow interval
tests_total += 1
tests_passed += run_test("Narrow interval: (x - 0.5)² on [0.4, 0.6]") do
    f(x) = (x - 0.5)^2
    res = golden_section_search(f, 0.4, 0.6; tol=1e-8)
    assert_approx(res.xmin, 0.5, 1e-6)
end

# Test 6: Absolute value function
tests_total += 1
tests_passed += run_test("Absolute value: |x| on [-1, 1]") do
    f(x) = abs(x)
    res = golden_section_search(f, -1.0, 1.0; tol=1e-8)
    assert_approx(res.fmin, 0.0, 1e-6)
    # xmin can be anywhere near 0 due to flat minimum
end

# Test 7: Max evaluations constraint
tests_total += 1
tests_passed += run_test("Max evaluations constraint: N=10" ) do
    f_quad(x) = (x - 0.5)^2
    res = golden_section_search(f_quad, 0.0, 1.0; N=10)
    # Should stop at N=10 or before reaching tolerance (may go to N+1 for final eval)
    @assert res.evaluations <= 11 "Expected <= 11 evaluations, got $(res.evaluations)"
end

# Test 8: Tolerance constraint
tests_total += 1
tests_passed += run_test("Tolerance constraint: tol=1e-2") do
    f(x) = (x - 0.3)^2
    res = golden_section_search(f, 0.0, 1.0; tol=1e-2)
    # Final interval length should be close to tolerance
    interval_length = res.b - res.a
    @assert interval_length <= 0.01 "Interval length $(interval_length) exceeds tolerance 0.01"
end

# Test 9: Error handling - invalid interval
tests_total += 1
tests_passed += run_test("Error handling: invalid interval (a >= b)") do
    f(x) = x^2
    try
        golden_section_search(f, 1.0, 0.0)
        throw(AssertionError("Should have thrown an error for invalid interval"))
    catch e
        if isa(e, ArgumentError) && contains(string(e), "a < b")
            # Expected error
        else
            rethrow(e)
        end
    end
end

# Test 10: Sinusoidal function
tests_total += 1
tests_passed += run_test("Sinusoidal: -sin(x) on [0, 2π]") do
    f(x) = -sin(x)  # Minimum occurs where sin is maximum
    res = golden_section_search(f, 0.0, 2π; tol=1e-6)
    # Minimum of -sin(x) is at x ≈ π/2 or x ≈ 5π/2
    # The algorithm will find one of them depending on the starting interval
    @assert res.fmin < -0.99 "Expected minimum ≈ -1, got $(res.fmin)"
end

# ============================================================================
# Summary
# ============================================================================

println("\n" * "="^50)
println("Test Results: $tests_passed / $tests_total passed")
println("="^50)

if tests_passed == tests_total
    println("All tests passed! ✓")
else
    println("Some tests failed. ✗")
end
