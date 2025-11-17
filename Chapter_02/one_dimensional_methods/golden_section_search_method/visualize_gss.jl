using Plots
using LaTeXStrings

include("golden_section_search.jl")

# Helper: compute GSS history for visualization
function golden_section_history(f, a::Float64, b::Float64; tol=1e-8, N=nothing)
    τ = (1 + sqrt(5)) / 2.0
    x_minus = a + (b - a) / τ^2
    x_plus  = a + (b - a) / τ
    fx_minus = f(x_minus)
    fx_plus  = f(x_plus)

    history = [(a, b, x_minus, x_plus, fx_minus, fx_plus)]
    evals = 2
    while (b - a) > tol && (N === nothing || evals < N)
        if fx_minus >= fx_plus
            a = x_minus
            x_minus = x_plus
            fx_minus = fx_plus
            x_plus = a + (b - a) / τ
            fx_plus = f(x_plus)
            evals += 1
        else
            b = x_plus
            x_plus = x_minus
            fx_plus = fx_minus
            x_minus = a + (b - a) / τ^2
            fx_minus = f(x_minus)
            evals += 1
        end
        push!(history, (a, b, x_minus, x_plus, fx_minus, fx_plus))
    end
    return history
end

"""
    visualize_search(f, a, b, ε; filename="golden_section_search", fps=1)

Create an animation showing the progress of the Golden Section Search method.
Saves both vector graphics (PDF) of each frame and the final GIF animation.

Parameters:
- `f`: The objective function to minimize
- `a`: Left endpoint of the interval
- `b`: Right endpoint of the interval
- `ε`: Tolerance for the interval length
- `filename`: Base name for output files (default: "golden_section_search")
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

function visualize_search(f, a, b, ε; filename="golden_section_search", fps=1)
    # Collect history using the GSS helper
    history = golden_section_history(f, a, b; tol=ε)
    
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
                title=L"Golden\ Section\ Search:\ Iteration\ %$i",
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


# ==========================================================================
# Additional visualizations (use actual GSS history)
# ==========================================================================

function plot_convergence()
    """Plot showing interval shrinkage using `golden_section_history`"""
    f(x) = (x - 0.3)^2 + 0.1
    a, b = 0.0, 1.0
    history = golden_section_history(f, a, b; tol=1e-6, N=15)

    intervals = [h[2] - h[1] for h in history]
    p = plot(
        title="GSS Convergence: Interval Reduction",
        xlabel="Iteration",
        ylabel="Interval Length",
        legend=false,
        size=(800, 400),
        yscale=:log10,
    )
    plot!(p, 1:length(intervals), intervals,
        marker=:circle,
        markerstrokewidth=0,
        markersize=5,
        linewidth=2,
        color=:steelblue,
    )

    # theoretical reduction rate
    τ = (1 + sqrt(5))/2.0
    x_theory = 1:length(intervals)
    theory = intervals[1] .* (1/τ) .^ (x_theory .- 1)
    plot!(p, x_theory, theory, linestyle=:dash, color=:red, linewidth=2, alpha=0.7)

    savefig(p, "gss_convergence.png")
    println("Saved: gss_convergence.png")
end


function plot_function_with_iterations()
    """Plot function and GSS intervals for first few iterations"""
    f(x) = (x - 0.3)^2 + 0.1
    a, b = 0.0, 1.0
    history = golden_section_history(f, a, b; tol=1e-6, N=8)

    ps = []
    for (idx, (a_i, b_i, x_m, x_p, f_m, f_p)) in enumerate(history[1:min(4, end)])
        x_range = range(0, 1, length=500)
        y_vals = f.(x_range)

        p = plot(x_range, y_vals, title="Iteration $idx: [$(round(a_i,digits=4)), $(round(b_i,digits=4))]",
            xlabel="x", ylabel="f(x)", legend=false, size=(400,300), color=:steelblue, linewidth=2)
        scatter!(p, [x_m, x_p], [f_m, f_p], marker=:circle, markersize=8, color=:red)
        vspan!(p, [a_i], [b_i], alpha=0.1, color=:green)
        push!(ps, p)
    end

    p_combined = plot(ps..., layout=(2,2))
    savefig(p_combined, "gss_iterations.png")
    println("Saved: gss_iterations.png")
end


function plot_convergence_comparison()
    """Compare convergence on several test functions (using golden_section_history)"""
    test_functions = [
        ("Quadratic", x -> (x - 0.3)^2, 0.0, 1.0),
        ("Quartic", x -> (x - 2)^4, 0.0, 4.0),
        ("Cosine", x -> cos(x), 0.0, Float64(π)),
        ("Absolute", x -> abs(x - 0.5), 0.0, 1.0)
    ]

    p = plot(title="GSS Convergence Comparison", xlabel="Iteration", ylabel="Interval Length",
        legend=:topright, size=(900,500), yscale=:log10)

    colors = [:steelblue, :coral, :green, :purple]
    for (i, (name, f, a, b)) in enumerate(test_functions)
        hist = golden_section_history(f, a, b; tol=1e-6, N=20)
        intervals = [h[2] - h[1] for h in hist]
        plot!(p, 1:length(intervals), intervals, marker=:circle, markersize=4, markerstrokewidth=0, linewidth=2, color=colors[i], label=name)
    end

    savefig(p, "gss_comparison.png")
    println("Saved: gss_comparison.png")
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
println("Generating GSS visualizations...")
println()

#plot_convergence()
#plot_function_with_iterations()
#plot_convergence_comparison()

#f_test(x) = (x-0.3)^2 + 0.1
#visualize_search(f_test, 0.0, 1.0, 1e-6; filename="gss_test", fps=1)

generate_example_visualizations()

#println()
println("All visualizations complete!")
println("Generated files:")
#println("  - gss_convergence.png")
#println("  - gss_iterations.png")
#println("  - gss_comparison.png")
#println("  - gss_test.gif and PDF frames in 'frames/'")
println("  - gifs and PDF frames in 'frames/'")