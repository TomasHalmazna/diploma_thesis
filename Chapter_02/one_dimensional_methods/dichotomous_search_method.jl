"""
    dichotomous_search(f, a, b, ε[, δ]; N=1000)

Implements the dichotomous search method for finding the minimum of a unimodal function
on interval [a,b].

Parameters:
- `f`: The objective function to minimize
- `a`: Left endpoint of the interval
- `b`: Right endpoint of the interval
- `ε`: Tolerance for the interval length
- `δ`: Small positive number for generating two interior points. If not provided,
       defaults to min(ε/4, (b-a)/1000). Must satisfy:
       δ ≥ eps() * max(1, abs(b-a)) and δ ∈ (0, (b-a)/2), where eps() is machine epsilon.
- `N`: Maximum number of iterations (default: 1000)

Returns:
- `x_min`: Approximate location of the minimum
- `f_min`: Function value at x_min
- `iterations`: Number of iterations performed
- `history`: Vector of tuples containing (a, b, x₋, x₊, f₋, f₊) for each iteration
"""
function dichotomous_search(f, a, b, ε, δ=nothing; N=1000)
    # Check if endpoints give finite values
    if !isfinite(f(a)) || !isfinite(f(b))
        error("Function evaluation resulted in non-finite value at endpoint(s)")
    end
    
    # Set default value for δ if not provided
    if isnothing(δ)
        δ = min(ε/4, (b-a)/1000)
    end
    
    # Check if δ is in the valid range
    if δ <= 0 || δ >= (b-a)/2
        error("δ must be in the interval (0, (b-a)/2)")
    end
    
    # Check if δ is large enough to avoid numerical issues
    scale = max(1, abs(b-a))
    if δ < eps() * scale
        error("δ must be at least eps() * max(1, |b-a|) to avoid numerical issues")
    end
    
    history = []
    iterations = 0
    
    while (b - a) > ε && iterations < N
        # Calculate midpoint
        c = (a + b) / 2
        
        # Generate two interior points
        x₋ = c - δ
        x₊ = c + δ
        
        # Evaluate function at both points
        f₋ = f(x₋)
        f₊ = f(x₊)
        
        # Check for non-finite function values
        if !isfinite(f₋) || !isfinite(f₊)
            error("Function evaluation resulted in non-finite value at x₋ = $x₋ or x₊ = $x₊")
        end
        
        # Store current state in history
        push!(history, (a, b, x₋, x₊, f₋, f₊))
        
        # Update interval based on function values
        if f₋ < f₊
            b = x₊
        else
            a = x₋
        end
        
        iterations += 1
    end
    
    # Calculate final solution
    x_min = (a + b) / 2
    f_min = f(x_min)
    
    return x_min, f_min, iterations, history
end

# Example usage
function example()
    # Example function: f(x) = x² + 2x + 1
    f(x) = x^2 + 2x + 1
    
    # Parameters
    a, b = -5.0, 5.0  # Initial interval
    ε = 1e-4          # Tolerance for interval length
    # δ will be automatically set to min(ε/4, (b-a)/1000)
    
    # Run the algorithm
    x_min, f_min, iterations, history = dichotomous_search(f, a, b, ε)
    
    println("Results:")
    println("x_min = ", x_min)
    println("f_min = ", f_min)
    println("Number of iterations: ", iterations)
    println("Final interval length: ", abs(history[end][2] - history[end][1]))
end

# Run the example
example()
