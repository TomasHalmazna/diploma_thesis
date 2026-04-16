# backend/Core.jl
using LinearAlgebra

# --- ABSTRACT TYPES ---
abstract type AbstractOptimizer end
abstract type AbstractLineSearch end

# --- OPTIMIZATION STATE ---
mutable struct OptimizationState
    x::Vector{Float64}
    gradient::Vector{Float64}
    inverse_hessian::Matrix{Float64} # W_k matrix for quasi-Newton methods, not updated for memoryless methods
end

# --- GENERAL ITERATIVE SCHEMA ---
function run_optimization(f, ∇f, x0::Vector{Float64}, method::AbstractOptimizer, linesearch::AbstractLineSearch; max_iter=1000, tol=1e-5)
    n = length(x0)
    
    # Initialize the state. W_0 is initialized as the Identity matrix.
    state = OptimizationState(copy(x0), ∇f(x0), Matrix{Float64}(I, n, n))
    
    history = [copy(state.x)]
    
    for _ in 1:max_iter
        if norm(state.gradient) < tol
            break
        end
        
        # 1. Compute descent direction 
        d = compute_direction(method, state)
        
        # 2. Perform line search
        alpha = compute_step_size(linesearch, f, ∇f, state, d)
        
        # 3. Update position and compute new gradient
        x_next = state.x + alpha * d
        g_next = ∇f(x_next)
        
        # 4. Prepare displacement vectors
        s = x_next - state.x
        y = g_next - state.gradient
        
        # Update internal approximation matrices (Multiple Dispatch)
        update_approximation!(method, state, s, y)
        
        # 5. Overwrite state
        state.x = x_next
        state.gradient = g_next
        
        push!(history, copy(state.x))
    end
    
    return history
end

# Default fallback for methods without memory updates
update_approximation!(method::AbstractOptimizer, state::OptimizationState, s, y) = nothing