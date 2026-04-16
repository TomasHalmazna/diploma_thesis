# backend/LineSearch/Bracketing.jl

# Helper function to bracket the minimum for 1D line search methods
function bracket_minimum(h, a=0.0, initial_step=1e-4, expansion=2.0, max_iter=50)
    f_a = h(a)
    b = a + initial_step
    f_b = h(b)
    
    # If the function goes up immediately, the minimum is between 0 and b
    if f_b > f_a 
        return 0.0, b 
    end
    
    # Otherwise, expand the interval until the function value increases
    c = b + expansion * (b - a)
    f_c = h(c)
    
    for _ in 1:max_iter
        if f_c > f_b 
            return a, c 
        end
        
        # Shift points
        a, f_a = b, f_b
        b, f_b = c, f_c
        c = b + expansion * (b - a)
        f_c = h(c)
    end
    
    return a, c
end