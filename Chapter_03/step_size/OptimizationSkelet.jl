module Optimization

using LinearAlgebra
using ForwardDiff
using Printf

# ==============================================================================
# 1. Abstract Types & Hierarchy
# ==============================================================================
"""
Abstract parent type for all optimization methods (e.g., GradientDescent, Newton).
"""
abstract type AbstractOptimizer end

"""
Abstract parent type for all line search strategies (e.g., Backtracking, GoldenSection).
"""
abstract type AbstractLineSearch end

# ==============================================================================
# 2. Optimization State
# ==============================================================================
"""
    OptimizationState{T}

Keeps track of the current state of the optimization process.
- `x`: Current design point (vector).
- `f_x`: Value of the objective function at `x`.
- `g_x`: Gradient vector at `x`.
"""
mutable struct OptimizationState{T}
    x::Vector{T}
    f_x::T
    g_x::Vector{T}
end

# Helper constructor to initialize state from x0
function OptimizationState(x0::Vector{T}, f) where T
    fx = f(x0)
    gx = ForwardDiff.gradient(f, x0)
    return OptimizationState(x0, fx, gx)
end

# ==============================================================================
# 3. Core Utilities
# ==============================================================================

"""
    update_state!(state, f)

Re-evaluates the function value and gradient at the current `state.x`.
Uses ForwardDiff for automatic differentiation.
"""
function update_state!(state::OptimizationState, f)
    state.f_x = f(state.x)
    state.g_x = ForwardDiff.gradient(f, state.x)
    return state
end

"""
    converged(state; tol)

Checks if the norm of the gradient is below the tolerance.
"""
function converged(state::OptimizationState; tol=1e-6)
    return norm(state.g_x) < tol
end

# ==============================================================================
# 4. The General Iterative Scheme (Skeleton)
# ==============================================================================

"""
    optimize!(state, method, linesearch, f)

The main optimization loop using multiple dispatch.
Actual behavior depends on the types of `method` and `linesearch`.
"""
function optimize!(state::OptimizationState, method::AbstractOptimizer, 
                   linesearch::AbstractLineSearch, f; max_iter=1000)
    
    iter = 0
    println("Starting optimization...")
    
    while !converged(state) && iter < max_iter
        iter += 1
        
        # Step 2: Direction Selection
        # (Implementation will be provided in specific method files)
        d = compute_direction(method, state)

        # Step 3: Line Search
        # (Implementation will be provided in specific linesearch files)
        alpha = perform_linesearch(linesearch, f, state.x, d)

        # Step 4: Update
        state.x .+= alpha .* d
        update_state!(state, f)
        
        # Optional: Logging
        @printf("Iter %d: f(x) = %.6f, |g| = %.6f\n", iter, state.f_x, norm(state.g_x))
    end
    
    if iter == max_iter
        println("Warning: Maximum iterations reached.")
    else
        println("Converged in $iter iterations.")
    end
    
    return state.x
end

# ==============================================================================
# 5. Interface Definitions (Placeholders)
# ==============================================================================
# These functions need to be extended for specific types later.

function compute_direction(method::AbstractOptimizer, state::OptimizationState)
    error("Method `compute_direction` not implemented for $(typeof(method)).")
end

function perform_linesearch(ls::AbstractLineSearch, f, x, d)
    error("Method `perform_linesearch` not implemented for $(typeof(ls)).")
end

# Export symbols so they are available when using the module
export AbstractOptimizer, AbstractLineSearch, OptimizationState, optimize!
export compute_direction, perform_linesearch

end