using Plots
using LaTeXStrings

include("dichotomous_search_method.jl")

"""
    visualize_search(f, a, b, ε; filename="dichotomous_search", fps=1)

Create an animation showing the progress of the dichotomous search method.
Saves both vector graphics (PDF) of each frame and the final GIF animation.

Parameters:
- `f`: The objective function to minimize
- `a`: Left endpoint of the interval
- `b`: Right endpoint of the interval
- `ε`: Tolerance for the interval length
- `filename`: Base name for output files (default: "dichotomous_search")
- `fps`: Frames per second in the animation (default: 1)

Returns:
- The animation object
"""

"""
To run this script, define a function `f(x)` and call `visualize_search(f, a, b, ε)`.
Example:

f(x) = x^2 + 2x + 1
visualize_search(f, -5.0, 5.0, 1e-4)
"""

function visualize_search(f, a, b, ε; filename="dichotomous_search", fps=1)
    # Run the optimization
    x_min, f_min, iterations, history = dichotomous_search(f, a, b, ε)
    
    # Create directory for PDF frames if it doesn't exist
    frames_dir = "frames"
    if !isdir(frames_dir)
        mkdir(frames_dir)
    end
    
    # Set default plot settings
    default(size=(800,600), dpi=300, framestyle=:box)
    
    # Determine y-axis limits
    x_range = range(a, b, length=200)
    y_values = f.(x_range)
    y_min, y_max = minimum(y_values), maximum(y_values)
    y_padding = (y_max - y_min) * 0.1
    
    # Create frames and save PDFs
    frames = []
    for i in 1:length(history)
        a_i, b_i, x₋, x₊, f₋, f₊ = history[i]
        
        # Create the main plot
        p = plot(x_range, f.(x_range), 
                linewidth=2, 
                label=L"f(x)",
                title=L"Dichotomous\ Search:\ Iteration\ %$i",
                xlabel=L"x",
                ylabel=L"f(x)",
                ylims=(y_min - y_padding, y_max + y_padding),
                legend=:topright)
        
        # Plot current interval
        plot!([a_i, b_i], [y_min - y_padding/2, y_min - y_padding/2], 
              linewidth=3, 
              color=:red,
              label=L"Search\ Interval")
        
        # Plot current midpoint (current estimate of minimum)
        x̄ = (a_i + b_i)/2
        f̄ = f(x̄)
        scatter!([x̄], [f̄],
                markersize=6,
                color=:red,
                label=L"\bar{x}")


        
        # Add iteration information
        interval_length = b_i - a_i
        annotate!(a, y_max + y_padding/2, 
                 text(L"Interval\ length:\ %$(round(interval_length, digits=6))", 
                      :left, 8))
        
        # Save current frame as PDF
        savefig(p, joinpath(frames_dir, "$(filename)_frame_$i.pdf"))
        
        # Store frame for animation
        push!(frames, p)
    end
    
    # Create and save the animation
    anim = Animation()
    for p in frames
        frame(anim, p)
    end
    gif(anim, "$(filename).gif", fps=fps)
    
    return anim
end

# Example usage with different test functions
function generate_example_visualizations()
    # Example 1: Quadratic function
    f₁(x) = x^2 + 2x + 1
    visualize_search(f₁, -5.0, 5.0, 1e-4, filename="quadratic")
    
    # Example 2: Fourth-degree polynomial
    f₂(x) = x^4
    visualize_search(f₂, -2.0, 2.0, 1e-4, filename="fourth_degree")
    
    # Example 3: Exponential function
    f₃(x) = exp(x) - x
    visualize_search(f₃, -2.0, 2.0, 1e-4, filename="exponential")
end

# Uncomment to generate example visualizations
generate_example_visualizations()