# backend/Optimizers/DFP.jl

struct DFPMethod <: AbstractOptimizer end

function compute_direction(method::DFPMethod, state::OptimizationState)
    W = state.inverse_hessian
    return -(W * state.gradient)
end

function update_approximation!(method::DFPMethod, state::OptimizationState, s, y)
    W = state.inverse_hessian
    
    ys = dot(y, s)
    yWy = dot(y, W * y)
    
    # Strict curvature condition enforcement
    if ys > 1e-10
        term1 = (W * y * transpose(y) * W) / yWy
        term2 = (s * transpose(s)) / ys
        
        state.inverse_hessian = W - term1 + term2
    end
end