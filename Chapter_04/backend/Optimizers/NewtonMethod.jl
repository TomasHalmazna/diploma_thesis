# backend/Optimizers/NewtonMethod.jl

# The struct holds the exact Hessian function
struct NewtonMethod <: AbstractOptimizer
    Hf::Function 
end

function compute_direction(method::NewtonMethod, state::OptimizationState)
    # Evaluate exact Hessian at current point
    H = method.Hf(state.x)
    
    # Solve the linear system H * d = -g instead of directly computing the inverse.
    # This is numerically much more stable and efficient.
    d = -(H \ state.gradient)
    
    return d
end