"""
    brents_method(f, a, b, ε; t=1e-8, N=100)

Implements Brent's method for finding the minimum of a unimodal function
on interval [a,b] without using derivatives.

Parameters:
- `f`: The objective function to minimize
- `a`: Left endpoint of the interval
- `b`: Right endpoint of the interval
- `ε`: Relative tolerance (proportional to |x|)
- `t`: Absolute tolerance (default: 1e-8)
- `N`: Maximum number of iterations (default: 100)

Returns:
- `x_min`: Approximate location of the minimum
- `f_min`: Function value at x_min
- `iterations`: Number of iterations performed
- `history`: Vector of tuples containing state for visualization
"""
function brents_method(f, a, b, ε; t=1e-8, N=100)
    # Golden ratio constant
    K = (3 - sqrt(5)) / 2
    
    # Initialize points
    x = w = v = a + K * (b - a)
    fx = fw = fv = f(x)
    
    # Initialize step sizes
    d = 0.0
    e = 0.0
    
    history = []
    iterations = 0
    
    # Main loop
    for i in 1:N
        m = 0.5 * (a + b)
        tol = ε * abs(x) + t
        t2 = 2 * tol
        
        # Save state to history BEFORE modification (for consistency with visualizer)
        # We store: (a, b, x, fx, u_trial, fu_trial)
        # Note: u_trial is set to NaN initially because we haven't computed it for this iter yet
        push!(history, (a, b, x, fx, NaN, NaN))
        
        # Check stopping criterion (based on Brent's ALGOL code)
        if abs(x - m) <= t2 - 0.5 * (b - a)
            break
        end
        
        iterations += 1
        p = q = r = 0.0
        d_new = 0.0
        u = 0.0
        iter_gss = true 
        
        # Attempt Parabolic Interpolation
        if abs(e) > tol
            r = (x - w) * (fx - fv)
            q = (x - v) * (fx - fw)
            p = (x - v) * q - (x - w) * r
            q = 2 * (q - r)
            
            if q > 0
                p = -p
            else
                q = -q
            end
            
            temp_e = e 
            e = d      
            
            if abs(p) < abs(0.5 * q * temp_e) && p > q * (a - x) && p < q * (b - x)
                d_new = p / q
                u = x + d_new
                
                if (u - a) < t2 || (b - u) < t2
                    d_new = (x < m) ? tol : -tol
                end
                
                iter_gss = false
            end
        end
        
        if iter_gss
            e = (x >= m) ? (a - x) : (b - x)
            d = K * e
        else
            d = d_new
        end
        
        if abs(d) >= tol
            u = x + d
        else
            u = x + ((d > 0) ? tol : -tol)
        end
        
        fu = f(u)
        
        # Update the last history entry with the actual trial point u
        # This allows visualizing where the method "poked" in this step
        last_idx = lastindex(history)
        history[last_idx] = (a, b, x, fx, u, fu)
        
        # Update brackets
        if fu <= fx
            if u < x
                b = x
            else
                a = x
            end
            v = w; fv = fw
            w = x; fw = fx
            x = u; fx = fu
        else
            if u < x
                a = u
            else
                b = u
            end
            
            if fu <= fw || w == x
                v = w; fv = fw
                w = u; fw = fu
            elseif fu <= fv || v == x || v == w
                v = u; fv = fu
            end
        end
    end
    
    return x, fx, iterations, history
end