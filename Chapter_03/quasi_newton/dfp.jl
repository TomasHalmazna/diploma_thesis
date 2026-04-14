using LinearAlgebra

abstract type AbstractOptimizer end

mutable struct OptimizationState
    x::Vector{Float64}
    gradient::Vector{Float64}
    inverse_hessian::Matrix{Float64}
end

# Define the method type for DFP
struct DFPMethod <: AbstractOptimizer end

# 1. Direction computation
function compute_direction(method::DFPMethod, state::OptimizationState)
    g = state.gradient
    W = state.inverse_hessian
    
    # Descent direction: d = -W * g
    d = -(W * g)
    
    return d
end

# 2. Update of the inverse Hessian using the DFP formula
function update_approximation!(method::DFPMethod, state::OptimizationState, s, y)
    W = state.inverse_hessian
    
    # Calculate scalar denominators
    ys = dot(y, s)
    yWy = dot(y, W * y)
    
    # Enforce the curvature condition loosely to avoid division by zero
    if ys > 1e-10
        # Compute the DFP update components safely using transpose()
        term1 = (W * y * transpose(y) * W) / yWy
        term2 = (s * transpose(s)) / ys
        
        # Apply the update
        state.inverse_hessian = W - term1 + term2
    end
end