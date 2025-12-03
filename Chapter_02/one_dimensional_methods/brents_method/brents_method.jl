"""
    brents_method(f, a, b, ε; t=1e-8, N=100)

Implements Brent's method.
Returns history as: (a, b, x, w, v, fx, u, fu, is_qfs)
"""
function brents_method(f, a, b, ε; t=1e-8, N=100)
    K = (3 - sqrt(5)) / 2
    
    x = w = v = a + K * (b - a)
    fx = fw = fv = f(x)
    
    d = 0.0
    e = 0.0
    
    history = []
    iterations = 0
    
    for i in 1:N
        m = 0.5 * (a + b)
        tol = ε * abs(x) + t
        t2 = 2 * tol
        
        # 1. Save state BEFORE calculation
        # Added 'false' at the end as placeholder for is_qfs
        push!(history, (a, b, x, w, v, fx, NaN, NaN, false))
        
        if abs(x - m) <= t2 - 0.5 * (b - a)
            break
        end
        
        iterations += 1
        p = q = r = 0.0
        d_new = 0.0
        iter_gss = true 
        
        if abs(e) > tol
            r = (x - w) * (fx - fv)
            q = (x - v) * (fx - fw)
            p = (x - v) * q - (x - w) * r
            q = 2 * (q - r)
            if q > 0; p = -p; else; q = -q; end
            temp_e = e; e = d      
            
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
        
        # 2. Update the LAST entry with actual u, fu AND method type
        # !iter_gss means QFS was used
        history[end] = (a, b, x, w, v, fx, u, fu, !iter_gss)
        
        # Update brackets
        if fu <= fx
            if u < x; b = x; else; a = x; end
            v = w; fv = fw
            w = x; fw = fx
            x = u; fx = fu
        else
            if u < x; a = u; else; b = u; end
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