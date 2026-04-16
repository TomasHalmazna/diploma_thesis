# backend/Optimizers/BFGS.jl

struct BFGSMethod <: AbstractOptimizer end

function compute_direction(method::BFGSMethod, state::OptimizationState)
    W = state.inverse_hessian
    return -(W * state.gradient)
end

function update_approximation!(method::BFGSMethod, state::OptimizationState, s, y)
    W = state.inverse_hessian
    n = length(s)
    ys = dot(y, s)
    
    # Strict curvature condition enforcement
    if ys > 1e-10
        rho = 1.0 / ys
        I_mat = Matrix{Float64}(I, n, n)
        
        V = I_mat - rho * (s * transpose(y))
        state.inverse_hessian = V * W * transpose(V) + rho * (s * transpose(s))
    end
end