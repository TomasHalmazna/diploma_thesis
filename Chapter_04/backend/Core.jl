# backend/Core.jl
using LinearAlgebra

# --- ABSTRACT TYPES ---
abstract type AbstractOptimizer end
abstract type AbstractLineSearch end

# --- OPTIMIZATION STATE ---
mutable struct OptimizationState
    x::Vector{Float64}
    gradient::Vector{Float64}
    inverse_hessian::Matrix{Float64}
    history::Vector{Any} # array of Tuples (s, y, rho) for methods that need to store history (like LBFGS)
end

# --- DIVERGENCE TRACKING ---
mutable struct DivergenceInfo
    diverged::Bool
    reason::String
    iteration::Int
    grad_norm::Float64
    f_value::Float64
end

function DivergenceInfo()
    return DivergenceInfo(false, "Success", 0, 0.0, 0.0)
end

# --- NUMERICAL SAFETY THRESHOLDS ---
const GRAD_NORM_THRESHOLD = 1e8  # Gradient norm explosion
const F_VALUE_THRESHOLD = 1e20   # Function value explosion
const MIN_STEP_SIZE = 1e-16      # Step size too small (line search failure)

# --- DIVERGENCE CHECK FUNCTION ---
function check_divergence(x, g, f_val, alpha, iteration)
    grad_norm = norm(g)
    
    # NaN/Inf in gradient
    if any(isnan.(g)) || any(isinf.(g))
        return DivergenceInfo(true, "Gradient contains NaN or Inf", iteration, grad_norm, f_val)
    end
    
    # NaN/Inf in function value
    if isnan(f_val) || isinf(f_val)
        return DivergenceInfo(true, "Function value is NaN or Inf", iteration, grad_norm, f_val)
    end
    
    # NaN/Inf in position
    if any(isnan.(x)) || any(isinf.(x))
        return DivergenceInfo(true, "Position contains NaN or Inf", iteration, grad_norm, f_val)
    end
    
    # Gradient explosion
    if grad_norm > GRAD_NORM_THRESHOLD
        return DivergenceInfo(true, "Gradient norm explosion (||∇f||=$(round(grad_norm, sigdigits=3)))", iteration, grad_norm, f_val)
    end
    
    # Function value explosion
    if abs(f_val) > F_VALUE_THRESHOLD && !isinf(f_val)
        return DivergenceInfo(true, "Function value explosion (f=$(round(f_val, sigdigits=3)))", iteration, grad_norm, f_val)
    end
    
    # Step size collapse (line search failure)
    if alpha < MIN_STEP_SIZE && alpha > 0
        return DivergenceInfo(true, "Step size collapse (α=$(round(alpha, sigdigits=3)))", iteration, grad_norm, f_val)
    end
    
    # Step size is zero or negative
    if alpha <= 0
        return DivergenceInfo(true, "Invalid step size (α=$alpha)", iteration, grad_norm, f_val)
    end
    
    return DivergenceInfo()
end

# --- GENERAL ITERATIVE SCHEMA ---
function run_optimization(f, ∇f, x0::Vector{Float64}, method::AbstractOptimizer, linesearch::AbstractLineSearch; max_iter=1000, tol=1e-5)
    n = length(x0)
    
    # Initialize the state
    x_init = copy(x0)
    g_init = ∇f(x_init)
    state = OptimizationState(x_init, g_init, Matrix{Float64}(I, n, n), [])
    
    history_pts = [copy(state.x)]
    div_info = DivergenceInfo()

    for iter in 1:max_iter
        # Check convergence
        grad_norm = norm(state.gradient)
        if grad_norm < tol
            break
        end
        
        # 1. Compute descent direction 
        d = compute_direction(method, state)
        
        # Check if direction is valid
        if any(isnan.(d)) || any(isinf.(d))
            div_info = DivergenceInfo(true, "Descent direction contains NaN or Inf", iter, grad_norm, f(state.x))
            break
        end
        
        # 2. Perform line search
        alpha = compute_step_size(linesearch, f, ∇f, state, d)
        
        # 3. Update position and compute new gradient
        x_next = state.x + alpha * d
        g_next = ∇f(x_next)
        f_next = f(x_next)
        
        # 4. Check for divergence
        div_check = check_divergence(x_next, g_next, f_next, alpha, iter)
        if div_check.diverged
            div_info = div_check
            push!(history_pts, copy(x_next))  # Include last point before divergence
            break
        end
        
        # 5. Prepare displacement vectors
        s = x_next - state.x
        y = g_next - state.gradient
        
        # Update internal approximation matrices (Multiple Dispatch)
        update_approximation!(method, state, s, y)
        
        # 6. Overwrite state
        state.x = x_next
        state.gradient = g_next
        push!(history_pts, copy(state.x))
    end
    
    return history_pts, div_info
end

# Default fallback for methods without memory updates
update_approximation!(method::AbstractOptimizer, state::OptimizationState, s, y) = nothing