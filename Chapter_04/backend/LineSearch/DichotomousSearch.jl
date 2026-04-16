# backend/LineSearch/DichotomousSearch.jl

struct DichotomousSearch <: AbstractLineSearch
    tol::Float64
    delta::Float64 # Distinguishability constant (renamed from epsilon)
    auto_bracket::Bool
    manual_interval::Tuple{Float64, Float64}
end

DichotomousSearch(; tol=1e-4, delta=1e-5, auto_bracket=true, manual_interval=(0.0, 1.0)) = 
    DichotomousSearch(tol, delta, auto_bracket, manual_interval)

function compute_step_size(ls::DichotomousSearch, f, ∇f, state::OptimizationState, d)
    h(alpha) = f(state.x + alpha * d)
    
    # Call the globally available bracketing function
    a, b = ls.auto_bracket ? bracket_minimum(h) : ls.manual_interval
    
    while (b - a) > ls.tol
        mid = (a + b) / 2.0
        
        # Use delta for the distinguishability constant
        x_minus = mid - ls.delta
        x_plus = mid + ls.delta
        
        if h(x_minus) < h(x_plus)
            b = x_plus
        else
            a = x_minus
        end
    end
    
    return (a + b) / 2.0
end