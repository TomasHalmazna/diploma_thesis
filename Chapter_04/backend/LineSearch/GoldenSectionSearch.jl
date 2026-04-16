# backend/LineSearch/GoldenSectionSearch.jl

struct GoldenSectionSearch <: AbstractLineSearch
    tol::Float64
    auto_bracket::Bool
    manual_interval::Tuple{Float64, Float64}
end

GoldenSectionSearch(; tol=1e-5, auto_bracket=true, manual_interval=(0.0, 1.0)) = 
    GoldenSectionSearch(tol, auto_bracket, manual_interval)

function compute_step_size(ls::GoldenSectionSearch, f, ∇f, state::OptimizationState, d)
    h(alpha) = f(state.x + alpha * d)
    
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