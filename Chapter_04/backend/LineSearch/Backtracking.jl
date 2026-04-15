# backend/LineSearch/Backtracking.jl

# Define the Backtracking line search type containing its specific parameters
struct Backtracking <: AbstractLineSearch
    p::Float64    # Contraction factor (typically 0.5)
    beta::Float64 # Sufficient decrease parameter (typically 1e-4)
end

# Default constructor
Backtracking() = Backtracking(0.5, 1e-4)

# Specific implementation of the step size computation using the Armijo condition
function compute_step_size(ls::Backtracking, f, ∇f, state::OptimizationState, d)
    alpha = 1.0
    y_val = f(state.x)
    g = state.gradient
    
    # Backtrack until the sufficient decrease condition is met
    while f(state.x + alpha * d) > y_val + ls.beta * alpha * dot(g, d)
        alpha *= ls.p
    end
    
    return alpha
end