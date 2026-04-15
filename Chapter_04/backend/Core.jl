# backend/Core.jl
using LinearAlgebra

# --- ABSTRACT TYPES ---
# These act as "interfaces" ensuring our application remains modular
abstract type AbstractOptimizer end
abstract type AbstractLineSearch end

# --- OPTIMIZATION STATE ---
# A mutable struct holding the current state of the optimization process
mutable struct OptimizationState
    x::Vector{Float64}
    gradient::Vector{Float64}
end

# --- GENERAL ITERATIVE SCHEMA ---
function run_optimization(f, ∇f, x0::Vector{Float64}, method::AbstractOptimizer, linesearch::AbstractLineSearch; max_iter=1000, tol=1e-5)
    # Initialize the state
    state = OptimizationState(copy(x0), ∇f(x0))
    
    # Track the full n-dimensional trajectory.
    # The copy() function is absolutely critical here! Otherwise, we would 
    # just store references to the same mutating vector.
    history = [copy(state.x)]
    
    for _ in 1:max_iter
        # Stopping criterion
        if norm(state.gradient) < tol
            break
        end
        
        # 1. Compute descent direction (Dispatched based on method type)
        d = compute_direction(method, state)
        
        # 2. Perform line search to find step size (Dispatched based on linesearch type)
        alpha = compute_step_size(linesearch, f, ∇f, state, d)
        
        # 3. Update position and compute new gradient
        x_next = state.x + alpha * d
        g_next = ∇f(x_next)
        
        # 4. Prepare displacement vectors for potential memory updates
        s = x_next - state.x
        y = g_next - state.gradient
        
        # Update internal approximation matrices/history if required by the method
        update_state!(method, state, s, y)
        
        # 5. Overwrite state for the next iteration
        state.x = x_next
        state.gradient = g_next
        
        # Store the current point in history
        push!(history, copy(state.x))
    end
    
    return history
end

# Default fallback: If a method doesn't require updating a Hessian approximation, do nothing.
update_state!(method::AbstractOptimizer, state::OptimizationState, s, y) = nothing