# backend/Optimizers/SteepestDescent.jl

# Define the Steepest Descent method type
struct SteepestDescent <: AbstractOptimizer end

# Specific implementation of the direction computation for Steepest Descent
function compute_direction(method::SteepestDescent, state::OptimizationState)
    # The search direction is simply the negative gradient
    return -state.gradient
end