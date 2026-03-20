using LinearAlgebra

# abstract type for optimizers
abstract type AbstractOptimizer end

struct OptimizationState
    x::Vector{Float64}
    gradient::Vector{Float64}
end

# Conjugate Gradient optimizer with support for FR, PR, and PR+ variants
mutable struct ConjugateGradient <: AbstractOptimizer
    variant::Symbol
    d_prev::Union{Nothing, Vector{Float64}}
    g_prev::Union{Nothing, Vector{Float64}}
    
    # initial choice of variant is PR+ as it often performs better in practice
    ConjugateGradient(; variant=:PR_plus) = new(variant, nothing, nothing)
end

# Direction computation
function compute_direction(method::ConjugateGradient, state::OptimizationState)
    g_k = state.gradient
    
    if method.d_prev === nothing
        d_k = -g_k 
    else
        # Calculated beta based on the selected variant
        if method.variant == :FR
            beta = dot(g_k, g_k) / dot(method.g_prev, method.g_prev)
        elseif method.variant == :PR || method.variant == :PR_plus
            beta_PR = dot(g_k - method.g_prev, g_k) / dot(method.g_prev, method.g_prev)
            beta = method.variant == :PR_plus ? max(0.0, beta_PR) : beta_PR
        else
            error("Unknown CG variant: $(method.variant)")
        end
        
        d_k = -g_k + beta * method.d_prev
    end
    
    # Update previous direction and gradient for the next iteration
    method.d_prev = copy(d_k)
    method.g_prev = copy(g_k)
    
    return d_k
end

# run_conjugate_gradient function to perform optimization
function run_conjugate_gradient(f, ∇f, x0; variant=:PR_plus, max_iter=2000, tol=1e-4)
    x = copy(x0)
    x_history = [copy(x)]
    optimizer = ConjugateGradient(variant=variant)
    
    for i in 1:max_iter
        g = ∇f(x)
        if norm(g) < tol
            break
        end
        
        # update optimization state and compute direction
        state = OptimizationState(x, g)
        d = compute_direction(optimizer, state)
        
        # exact line search using golden section search
        h(α) = f(x + α * d)
        res = golden_section_search(h, 0.0, 3.0; tol=1e-8)
        alpha = res.xmin 
        
        # update point
        x = x + alpha * d
        push!(x_history, copy(x))
    end
    
    return x, x_history
end