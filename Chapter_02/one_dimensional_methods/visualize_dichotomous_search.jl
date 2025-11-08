using Plots
using LaTeXStrings

include("dichotomous_search_method.jl")

"""
    visualize_search(f, a, b, ε; filename="dichotomous_search.gif", fps=2)

Create an animation showing the progress of the dichotomous search method.

Parameters:
- `f`: The objective function to minimize
- `a`: Left endpoint of the interval
- `b`: Right endpoint of the interval
- `ε`: Tolerance for the interval length
- `filename`: Name of the output GIF file (default: "dichotomous_search.gif")
- `fps`: Frames per second in the animation (default: 2)

Returns:
- The animation object
"""
function visualize_search(f, a, b, ε; filename="dichotomous_search.gif", fps=2)
    # Run the optimization
    x_min, f_min, iterations, history = dichotomous_search(f, a, b, ε)
    
    # Determine y-axis limits
    x_range = range(a, b, length=200)
    y_values = f.(x_range)
    y_min, y_max = minimum(y_values), maximum(y_values)
    y_padding = (y_max - y_min) * 0.1
    
    # Create animation
    anim = @animate for i in 1:length(history)
        a_i, b_i, x₋, x₊, f₋, f₊ = history[i]
        
        # Create the main plot
        p = plot(x_range, f.(x_range), 
                linewidth=2, 
                label="f(x)",
                title="Dichotomous Search: Iteration $i",
                xlabel="x",
                ylabel="f(x)",
                ylims=(y_min - y_padding, y_max + y_padding))
        
        # Plot current interval
        plot!([a_i, b_i], [y_min - y_padding/2, y_min - y_padding/2], 
              linewidth=3, 
              color=:red,
              label="Search Interval")
        
        # Plot test points
        scatter!([x₋, x₊], [f₋, f₊], 
                markersize=6,
                color=[:blue :green],
                label=["x₋" "x₊"])
        
        # Add vertical lines from test points to x-axis
        plot!([x₋, x₋], [y_min - y_padding/2, f₋], 
              linestyle=:dash, 
              color=:blue,
              label=nothing)
        plot!([x₊, x₊], [y_min - y_padding/2, f₊], 
              linestyle=:dash, 
              color=:green,
              label=nothing)
        
        # Add iteration information
        interval_length = b_i - a_i
        annotate!(a, y_max + y_padding/2, 
                 text("Interval length: $(round(interval_length, digits=6))", 
                      :left, 8))
    end
    
    # Save the animation
    gif(anim, filename, fps=fps)
    return anim
end

# Example usage with different test functions
function generate_example_visualizations()
    # Example 1: Quadratic function
    f₁(x) = x^2 + 2x + 1
    visualize_search(f₁, -5.0, 5.0, 1e-4, filename="quadratic.gif")
    
    # Example 2: Fourth-degree polynomial
    f₂(x) = x^4
    visualize_search(f₂, -2.0, 2.0, 1e-4, filename="fourth_degree.gif")
    
    # Example 3: Exponential function
    f₃(x) = exp(x) - x
    visualize_search(f₃, -2.0, 2.0, 1e-4, filename="exponential.gif")
end

# Uncomment to generate example visualizations
# generate_example_visualizations()