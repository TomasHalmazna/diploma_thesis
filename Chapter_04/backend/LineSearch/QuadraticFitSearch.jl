# backend/LineSearch/QuadraticFitSearch.jl

struct QuadraticFitSearch <: AbstractLineSearch
    tol::Float64
    max_iter::Int
    auto_bracket::Bool
    manual_interval::Tuple{Float64, Float64}
end

QuadraticFitSearch(; tol=1e-5, max_iter=100, auto_bracket=true, manual_interval=(0.0, 1.0)) = 
    QuadraticFitSearch(tol, max_iter, auto_bracket, manual_interval)

function compute_step_size(ls::QuadraticFitSearch, f, ∇f, state::OptimizationState, d)
    h(alpha) = f(state.x + alpha * d)
    
    # Initialize three points
    a, c = ls.auto_bracket ? bracket_minimum(h) : ls.manual_interval
    b = (a + c) / 2.0
    
    f_a, f_b, f_c = h(a), h(b), h(c)
    
    for _ in 1:ls.max_iter
        # Numerator and denominator for the minimum of the fitted parabola
        num = (b - a)^2 * (f_b - f_c) - (b - c)^2 * (f_b - f_a)
        den = (b - a) * (f_b - f_c) - (b - c) * (f_b - f_a)
        
        # Avoid division by zero if points become collinear
        if abs(den) < 1e-14 
            break 
        end
        
        # New estimate for the minimum
        x_new = b - 0.5 * (num / den)
        f_new = h(x_new)
        
        # Stopping criterion
        if abs(x_new - b) < ls.tol
            return x_new
        end
        
        # Update the three points holding the minimum
        if x_new > b
            if f_new > f_b
                c = x_new; f_c = f_new
            else
                a = b; f_a = f_b
                b = x_new; f_b = f_new
            end
        else
            if f_new > f_b
                a = x_new; f_a = f_new
            else
                c = b; f_c = f_b
                b = x_new; f_b = f_new
            end
        end
    end
    
    return b
end