# backend/Optimizers/ConjugateGradient.jl

mutable struct ConjugateGradient <: AbstractOptimizer
    variant::Symbol # Expected values: :FR, :PR, :PR_plus
    d_prev::Union{Nothing, Vector{Float64}}
    g_prev::Union{Nothing, Vector{Float64}}
    
    # Constructor sets the variant and initializes empty history
    ConjugateGradient(variant::Symbol=:PR_plus) = new(variant, nothing, nothing)
end

function compute_direction(method::ConjugateGradient, state::OptimizationState)
    g_k = state.gradient
    
    if method.d_prev === nothing
        d_k = -g_k # Steepest descent for the first step
    else
        # Compute scalar denominators
        g_prev_sq = dot(method.g_prev, method.g_prev)
        
        # Calculate beta based on the selected variant
        if method.variant == :FR
            beta = dot(g_k, g_k) / g_prev_sq
            
        elseif method.variant == :PR
            beta = dot(g_k - method.g_prev, g_k) / g_prev_sq
            
        elseif method.variant == :PR_plus
            beta_PR = dot(g_k - method.g_prev, g_k) / g_prev_sq
            beta = max(0.0, beta_PR)
            
        else
            error("Unknown CG variant: $(method.variant)")
        end
        
        d_k = -g_k + beta * method.d_prev
    end
    
    # Update history for the next iteration
    method.d_prev = d_k
    method.g_prev = g_k
    
    return d_k
end