using LinearAlgebra

abstract type AbstractOptimizer end

# State specifically modified for L-BFGS (holds history instead of a dense matrix)
mutable struct OptimizationState
    x::Vector{Float64}
    gradient::Vector{Float64}
    history::Vector{Tuple{Vector{Float64}, Vector{Float64}, Float64}} # Stores (s, y, rho)
end

struct LBFGSMethod <: AbstractOptimizer
    m::Int # Memory limit
end

# Direction computation using Two-Loop Recursion
function compute_direction(method::LBFGSMethod, state::OptimizationState)
    q = copy(state.gradient)
    history = state.history
    k = length(history)
    
    alphas = zeros(k)
    
    # Backward pass
    for i in k:-1:1
        s, y, rho = history[i]
        alphas[i] = rho * dot(s, q)
        q = q - alphas[i] * y
    end
    
    # Initial matrix scaling (M3 strategy: gamma * I)
    if k > 0
        s_last, y_last, _ = history[end]
        gamma = dot(s_last, y_last) / dot(y_last, y_last)
        r = gamma * q
    else
        r = q
    end
    
    # Forward pass
    for i in 1:k
        s, y, rho = history[i]
        beta = rho * dot(y, r)
        r = r + s * (alphas[i] - beta)
    end
    
    return -r
end

# Update of the limited memory history
function update_approximation!(method::LBFGSMethod, state::OptimizationState, s, y)
    ys = dot(y, s)
    
    if ys > 1e-10
        rho = 1.0 / ys
        push!(state.history, (s, y, rho))
        
        # Enforce the rolling window limit
        if length(state.history) > method.m
            popfirst!(state.history)
        end
    end
end