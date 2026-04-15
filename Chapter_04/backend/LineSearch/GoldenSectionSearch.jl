# backend/LineSearch/GoldenSectionSearch.jl

# Struct now holds configuration for the line search behavior
struct GoldenSectionSearch <: AbstractLineSearch
    tol::Float64
    auto_bracket::Bool
    manual_interval::Tuple{Float64, Float64}
end

# Flexible constructor using keyword arguments
function GoldenSectionSearch(; tol=1e-5, auto_bracket=true, manual_interval=(0.0, 1.0))
    return GoldenSectionSearch(tol, auto_bracket, manual_interval)
end

# Helper function to bracket the minimum
function bracket_minimum(h, a=0.0, initial_step=1e-4, expansion=2.0, max_iter=50)
    f_a = h(a)
    b = a + initial_step
    f_b = h(b)
    
    if f_b > f_a return 0.0, b end
    
    c = b + expansion * (b - a)
    f_c = h(c)
    
    for _ in 1:max_iter
        if f_c > f_b return a, c end
        a, f_a = b, f_b
        b, f_b = c, f_c
        c = b + expansion * (b - a)
        f_c = h(c)
    end
    return a, c
end

function compute_step_size(ls::GoldenSectionSearch, f, ∇f, state::OptimizationState, d)
    h(alpha) = f(state.x + alpha * d)
    
    # Decide initial interval based on user configuration
    if ls.auto_bracket
        a, b = bracket_minimum(h)
    else
        a, b = ls.manual_interval
    end
    
    τ = (1.0 + sqrt(5.0)) / 2.0
    x_minus = a + (b - a) / τ^2
    x_plus  = a + (b - a) / τ
    
    fx_minus = h(x_minus)
    fx_plus  = h(x_plus)
    
    while (b - a) > ls.tol
        if fx_minus >= fx_plus
            a = x_minus
            x_minus = x_plus
            fx_minus = fx_plus
            x_plus = a + (b - a) / τ
            fx_plus = h(x_plus)
        else
            b = x_plus
            x_plus = x_minus
            fx_plus = fx_minus
            x_minus = a + (b - a) / τ^2
            fx_minus = h(x_minus)
        end
    end
    
    return (a + b) / 2.0
end