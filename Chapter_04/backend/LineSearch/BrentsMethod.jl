# backend/LineSearch/BrentsMethod.jl

struct BrentsMethod <: AbstractLineSearch
    tol::Float64
    max_iter::Int
    auto_bracket::Bool
    manual_interval::Tuple{Float64, Float64}
end

BrentsMethod(; tol=1e-5, max_iter=100, auto_bracket=true, manual_interval=(0.0, 1.0)) = 
    BrentsMethod(tol, max_iter, auto_bracket, manual_interval)

function compute_step_size(ls::BrentsMethod, f, ∇f, state::OptimizationState, d)
    h(alpha) = f(state.x + alpha * d)
    
    # Initialization
    a, b = ls.auto_bracket ? bracket_minimum(h) : ls.manual_interval
    
    CGOLD = 0.3819660 # Golden ratio constant: (3 - sqrt(5)) / 2
    
    x = w = v = a + CGOLD * (b - a)
    f_x = f_w = f_v = h(x)
    
    d_step = e = 0.0
    
    for _ in 1:ls.max_iter
        mid = 0.5 * (a + b)
        tol1 = ls.tol * abs(x) + 1e-10
        tol2 = 2.0 * tol1
        
        # Stopping criterion: Check if the interval is sufficiently small
        if abs(x - mid) <= (tol2 - 0.5 * (b - a))
            return x
        end
        
        if abs(e) > tol1
            # Attempt Parabolic Fit
            r = (x - w) * (f_x - f_v)
            q = (x - v) * (f_x - f_w)
            p = (x - v) * q - (x - w) * r
            
            # Calculate denominator (Note: the minus sign from the analytical 
            # formula is handled below via the sign manipulation of p)
            q = 2.0 * (q - r)
            
            if q > 0.0
                p = -p
            end
            q = abs(q)
            
            etemp = e
            e = d_step
            
            # Check if parabolic fit is acceptable (within bounds and halving step size)
            if abs(p) >= abs(0.5 * q * etemp) || p <= q * (a - x) || p >= q * (b - x)
                # Reject parabolic fit, fall back to Golden Section
                e = (x >= mid ? a - x : b - x)
                d_step = CGOLD * e
            else
                # Accept parabolic fit
                d_step = p / q
                u = x + d_step
                # Don't evaluate too close to the boundaries a or b
                if u - a < tol2 || b - u < tol2
                    d_step = sign(mid - x) * tol1
                end
            end
        else
            # Golden Section step
            e = (x >= mid ? a - x : b - x)
            d_step = CGOLD * e
        end
        
        # Make sure the step is at least tol1
        u = x + (abs(d_step) >= tol1 ? d_step : sign(d_step) * tol1)
        f_u = h(u)
        
        # Housekeeping: Update brackets and history points (x, w, v)
        if f_u <= f_x
            if u >= x
                a = x
            else
                b = x
            end
            v = w; f_v = f_w
            w = x; f_w = f_x
            x = u; f_x = f_u
        else
            if u < x
                a = u
            else
                b = u
            end
            
            if f_u <= f_w || w == x
                v = w; f_v = f_w
                w = u; f_w = f_u
            elseif f_u <= f_v || v == x || v == w
                v = u; f_v = f_u
            end
        end
    end
    
    return x
end