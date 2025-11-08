"""
    dichotomous_search(f, a, b, ε, δ; N=1000)

Implements the dichotomous search method for finding the minimum of a unimodal function
on interval [a,b].

Parameters:
- `f`: The objective function to minimize
- `a`: Left endpoint of the interval
- `b`: Right endpoint of the interval
- `ε`: Tolerance for the interval length
- `δ`: Small positive number for generating two interior points (δ < ε/2)
- `N`: Maximum number of iterations (default: 1000)

Returns:
- `x_min`: Approximate location of the minimum
- `f_min`: Function value at x_min
- `iterations`: Number of iterations performed
- `history`: Vector of tuples containing (a, b, x₋, x₊, f₋, f₊) for each iteration
"""
function dichotomous_search(f, a, b, ε, δ; N=1000)
    if δ >= ε/2
        error("δ must be smaller than ε/2")
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
    δ = ε/4           # Small positive number (δ < ε/2)
    
    # Run the algorithm
    x_min, f_min, iterations, history = dichotomous_search(f, a, b, ε, δ)
    
    println("Results:")
    println("x_min = ", x_min)
    println("f_min = ", f_min)
    println("Number of iterations: ", iterations)
    println("Final interval length: ", abs(history[end][2] - history[end][1]))
end

# Uncomment to run the example
example()
