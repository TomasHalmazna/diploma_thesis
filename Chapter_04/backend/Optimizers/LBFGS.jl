# backend/Optimizers/LBFGS.jl

# Define the method type for L-BFGS with parameter m
struct LBFGSMethod <: AbstractOptimizer
    m::Int # Maximum number of stored vector pairs
end

# 1. Direction computation using Two-Loop Recursion
function compute_direction(method::LBFGSMethod, state::OptimizationState)
    q = copy(state.gradient)
    history = state.history # Array of Tuples: (s, y, rho)
    k = length(history)
     
    if k == 0
        return -q # Steepest descent if no history exists
    end
    
    alphas = zeros(k)
    
    # First loop (backward)
    for i in k:-1:1
        s, y, rho = history[i]
        alphas[i] = rho * dot(s, q)
        q = q - alphas[i] * y
    end
    
    # Scaling the initial matrix (gamma_k * I)
    s_last, y_last, _ = history[end]
    gamma = dot(s_last, y_last) / dot(y_last, y_last)
    r = gamma * q
    
    # Second loop (forward)
    for i in 1:k
        s, y, rho = history[i]
        beta = rho * dot(y, r)
        r = r + s * (alphas[i] - beta)
    end
    
    return -r # Descent direction d = -H * g
end

# 2. Update of the limited memory history
function update_approximation!(method::LBFGSMethod, state::OptimizationState, s, y)
    ys = dot(y, s)
    
    # Curvature condition
    if ys > 1e-10
        rho = 1.0 / ys
        
        # Add newest information
        push!(state.history, (s, y, rho))
        
        # Discard oldest information if memory limit m is exceeded
        if length(state.history) > method.m
            popfirst!(state.history)
        end
    end
end