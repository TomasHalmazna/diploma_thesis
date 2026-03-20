using LinearAlgebra

# Load the golden section search implementation
include(joinpath(@__DIR__, "..", "..", "Chapter_02", "one_dimensional_methods", "golden_section_search_method", "golden_section_search.jl"))


function run_steepest_descent(f, ∇f, x0; max_iter=2000, tol=1e-4)
    x = copy(x0)
    x_history = [copy(x)]
    
    for i in 1:max_iter
        g = ∇f(x)
        if norm(g) < tol
            break
        end
        
        # Normalized direction for Steepest Descent
        d = -g / norm(g)
        
        # 1D function for exact line search
        h(α) = f(x + α * d)
        
        # Exact line search
        res = golden_section_search(h, 0.0, 3.0; tol=1e-8)
        alpha = res.xmin 
        
        x = x + alpha * d
        push!(x_history, copy(x))
    end
    
    return x, x_history
end