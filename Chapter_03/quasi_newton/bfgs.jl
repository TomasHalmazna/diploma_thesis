using LinearAlgebra

abstract type AbstractOptimizer end

mutable struct OptimizationState
    x::Vector{Float64}
    gradient::Vector{Float64}
    inverse_hessian::Matrix{Float64}
end

struct BFGSMethod <: AbstractOptimizer end

# Direction computation
function compute_direction(method::BFGSMethod, state::OptimizationState)
    g = state.gradient
    W = state.inverse_hessian
    d = -(W * g)
    return d
end

# Update of the inverse Hessian using the BFGS formula
function update_approximation!(method::BFGSMethod, state::OptimizationState, s, y)
    W = state.inverse_hessian
    n = length(s)
    ys = dot(y, s)
    
    if ys > 1e-10
        rho = 1.0 / ys
        I_mat = Matrix{Float64}(I, n, n)
        V = I_mat - rho * (s * transpose(y))
        state.inverse_hessian = V * W * transpose(V) + rho * (s * transpose(s))
    end
end