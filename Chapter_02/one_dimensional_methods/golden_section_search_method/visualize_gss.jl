"""
Visualization of the Golden-Section Search (GSS) algorithm
Shows the iterative interval reduction and function evaluations
"""

using Plots
using LaTeXStrings

# Include the GSS implementation
include("golden_section_search.jl")

# ============================================================================
# Visualization 1: Convergence Progress
# ============================================================================

function plot_convergence()
    """Plot showing how the interval shrinks over iterations"""
    
    # Define a function
    f(x) = (x - 0.3)^2 + 0.1
    
    # Manually track interval history (modified version of GSS)
    τ = (1 + sqrt(5)) / 2.0
    a, b = 0.0, 1.0
    x_minus = a + (b - a) / τ^2
    x_plus = a + (b - a) / τ
    fx_minus = f(x_minus)
    fx_plus = f(x_plus)
    
    history = [(a, b)]
    
    for i in 1:15
        if fx_minus >= fx_plus
            a = x_minus
            x_minus = x_plus
            fx_minus = fx_plus
            x_plus = a + (b - a) / τ
            fx_plus = f(x_plus)
        else
            b = x_plus
            x_plus = x_minus
            fx_plus = fx_minus
            x_minus = a + (b - a) / τ^2
            fx_minus = f(x_minus)
        end
        push!(history, (a, b))
    end
    
    # Create plot showing interval reduction
    p = plot(
        title="GSS Convergence: Interval Reduction",
        xlabel="Iteration",
        ylabel="Interval Length",
        legend=false,
        size=(800, 400),
        yscale=:log10
    )
    
    intervals = [h[2] - h[1] for h in history]
    plot!(p, 1:length(intervals), intervals, 
        marker=:circle, 
        markerstrokewidth=0,
        markersize=5,
        linewidth=2,
        color=:steelblue,
        label="Interval Length"
    )
    
    # Add theoretical reduction rate line
    x_theory = 1:length(intervals)
    theory = intervals[1] .* (1/τ) .^ (x_theory .- 1)
    plot!(p, x_theory, theory, 
        linestyle=:dash, 
        color=:red, 
        linewidth=2,
        alpha=0.7
    )
    
    savefig(p, "gss_convergence.png")
    println("Saved: gss_convergence.png")
end

# ============================================================================
# Visualization 2: Function Evaluations with Interval
# ============================================================================

function plot_function_with_iterations()
    """Plot showing function and the interval reduction steps"""
    
    f(x) = (x - 0.3)^2 + 0.1
    
    τ = (1 + sqrt(5)) / 2.0
    a, b = 0.0, 1.0
    
    # Run GSS with tracking
    x_minus = a + (b - a) / τ^2
    x_plus = a + (b - a) / τ
    fx_minus = f(x_minus)
    fx_plus = f(x_plus)
    
    iterations = [(a, b, x_minus, x_plus, fx_minus, fx_plus)]
    
    for i in 1:8
        if fx_minus >= fx_plus
            a = x_minus
            x_minus = x_plus
            fx_minus = fx_plus
            x_plus = a + (b - a) / τ
            fx_plus = f(x_plus)
        else
            b = x_plus
            x_plus = x_minus
            fx_plus = fx_minus
            x_minus = a + (b - a) / τ^2
            fx_minus = f(x_minus)
        end
        push!(iterations, (a, b, x_minus, x_plus, fx_minus, fx_plus))
    end
    
    # Create subplots for different iterations
    ps = []
    for (idx, (a, b, x_m, x_p, f_m, f_p)) in enumerate(iterations[1:min(4, end)])
        x_range = range(0, 1, length=500)
        y_vals = f.(x_range)
        
        p = plot(
            x_range, y_vals,
            title="Iteration $idx: [$(round(a, digits=4)), $(round(b, digits=4))]",
            xlabel="x",
            ylabel="f(x)",
            legend=false,
            size=(400, 300),
            color=:steelblue,
            linewidth=2
        )
        
        # Mark evaluated points
        scatter!(p, [x_m, x_p], [f_m, f_p], 
            marker=:circle, 
            markersize=8, 
            color=:red,
            label="Evaluated"
        )
        
        # Shade current interval
        vspan!(p, [a], [b], alpha=0.1, color=:green, label="Current interval")
        
        push!(ps, p)
    end
    
    p_combined = plot(ps..., layout=(2, 2))
    savefig(p_combined, "gss_iterations.png")
    println("Saved: gss_iterations.png")
end

# ============================================================================
# Visualization 3: Comparison with Different Test Functions
# ============================================================================

function plot_convergence_comparison()
    """Compare GSS convergence on different functions"""
    
    test_functions = [
        ("Quadratic: (x-0.3)²", x -> (x - 0.3)^2, 0.0, 1.0, 0.3),
        ("Quartic: (x-2)⁴", x -> (x - 2)^4, 0.0, 4.0, 2.0),
        ("Cosine: cos(x)", x -> cos(x), 0.0, π, π),
        ("Absolute: |x-0.5|", x -> abs(x - 0.5), 0.0, 1.0, 0.5)
    ]
    
    p = plot(
        title="GSS Convergence Comparison",
        xlabel="Iteration",
        ylabel="Interval Length",
        legend=:topright,
        size=(900, 500),
        yscale=:log10
    )
    
    colors = [:steelblue, :coral, :green, :purple]
    
    for (idx, (name, f, a, b, true_min)) in enumerate(test_functions)
        τ = (1 + sqrt(5)) / 2.0
        a_curr, b_curr = a, b
        x_minus = a_curr + (b_curr - a_curr) / τ^2
        x_plus = a_curr + (b_curr - a_curr) / τ
        fx_minus = f(x_minus)
        fx_plus = f(x_plus)
        
        intervals = [b_curr - a_curr]
        
        for i in 1:20
            if fx_minus >= fx_plus
                a_curr = x_minus
                x_minus = x_plus
                fx_minus = fx_plus
                x_plus = a_curr + (b_curr - a_curr) / τ
                fx_plus = f(x_plus)
            else
                b_curr = x_plus
                x_plus = x_minus
                fx_plus = fx_minus
                x_minus = a_curr + (b_curr - a_curr) / τ^2
                fx_minus = f(x_minus)
            end
            push!(intervals, b_curr - a_curr)
        end
        
        plot!(p, 1:length(intervals), intervals,
            marker=:circle,
            markersize=4,
            markerstrokewidth=0,
            linewidth=2,
            color=colors[idx],
            label=name
        )
    end
    
    savefig(p, "gss_comparison.png")
    println("Saved: gss_comparison.png")
end

# ============================================================================
# Run all visualizations
# ============================================================================

println("Generating GSS visualizations...")
println()

plot_convergence()
plot_function_with_iterations()
plot_convergence_comparison()

println()
println("All visualizations complete!")
println("Generated files:")
println("  - gss_convergence.png")
println("  - gss_iterations.png")
println("  - gss_comparison.png")
