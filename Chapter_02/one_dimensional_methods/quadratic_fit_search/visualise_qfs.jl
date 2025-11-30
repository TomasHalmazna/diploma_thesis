using Plots
using LaTeXStrings

# ==========================================================================
# 1. QUADRATIC FIT SEARCH CORE ALGORITHM
# ==========================================================================

"""
    quadratic_fit_search_step(f, a, γ, b, y_a, y_γ, y_b)

Calculates the minimum (x_est) of the quadratic polynomial P(x) interpolating the points
(a, y_a), (γ, y_γ), and (b, y_b).

Returns: (x_est, D, N_num), where D is the denominator and N_num is the numerator.
"""
function quadratic_fit_search_step(a::Float64, γ::Float64, b::Float64, y_a::Float64, y_γ::Float64, y_b::Float64)
    # Denominator (D) and Numerator (N_num) of the x_est formula:
    D = y_a * (γ - b) + y_γ * (b - a) + y_b * (a - γ)
    N_num = y_a * (γ^2 - b^2) + y_γ * (b^2 - a^2) + y_b * (a^2 - γ^2)
    
    # Handle degenerate parabola (D near zero)
    if abs(D) < 1e-12
        x_est = (a + b) / 2.0 # Return midpoint as fallback
    else
        x_est = 0.5 * N_num / D
    end
    
    return x_est, D, N_num
end


"""
    quadratic_fit_history(f, a::Float64, b::Float64; N::Int=10, tol::Float64=1e-8)

Helper function to run QIS and record the state of the search for visualization.
The search is limited such that the total number of function evaluations does not exceed N.
Since 3 evaluations occur before the loop, the loop runs for at most N-3 iterations.

Returns a list of tuples containing:
(a, γ, b, y_a, y_γ, y_b, x_est, y_est, p0, p1, p2, is_valid_step)
where p0, p1, p2 are coefficients of the interpolating parabola P(x) = p2*x^2 + p1*x + p0.
"""
function quadratic_fit_history(f, a::Float64, b::Float64; N::Int=10, tol::Float64=1e-8)
    # 3 function evaluations are used here: f(a), f(γ), f(b)
    γ = (a + b) / 2.0
    y_a = f(a)
    y_γ = f(γ)
    y_b = f(b)
    
    # Store: (a, γ, b, y_a, y_γ, y_b, x_est, y_est, p0, p1, p2, is_valid_step)
    history = []
    
    # Run for a maximum of N-3 iterations (since 3 evaluations already occurred)
    max_iterations = N > 3 ? N - 3 : 0
    for k = 1:max_iterations
        # Check for convergence based on interval length
        if (b - a) < tol
             break
        end

        # --- 1. Compute interpolation point x_est ---
        x_est, D, N_num = quadratic_fit_search_step(a, γ, b, y_a, y_γ, y_b)
        
        is_valid_step = true

        # Check for break condition (minimum outside bracket or invalid x_est)
        if abs(D) < 1e-12 || x_est <= a || x_est >= b
            is_valid_step = false
        end
        
        # --- 2. Evaluate f(x_est) ---
        y_est = f(x_est)

        # --- 3. Compute Parabola Coefficients P(x) = p2*x^2 + p1*x + p0 for Plotting ---
        K = (a-γ) * (a-b) * (γ-b)
        
        # Calculate coefficients carefully, handling the D=0 case for plotting the parabola
        p2 = abs(K) < 1e-12 ? 0.0 : D / K
        p1 = abs(K) < 1e-12 ? 0.0 : -N_num / K
        p0 = y_a - p2 * a^2 - p1 * a

        # Store current state before updating a, γ, b
        push!(history, (a, γ, b, y_a, y_γ, y_b, x_est, y_est, p0, p1, p2, is_valid_step))
        
        # --- 4. Update the interval ---
        if !is_valid_step
             break
        end

        if x_est > γ
            if y_est >= y_γ
                b = x_est
                y_b = y_est
            else
                a = γ
                y_a = y_γ
                γ = x_est
                y_γ = y_est
            end
        else
            if y_est >= y_γ
                a = x_est
                y_a = y_est
            else
                b = γ
                y_b = y_γ
                γ = x_est
                y_γ = y_est
            end
        end
    end
    return history
end


# ==========================================================================
# 2. VISUALIZATION FUNCTION
# ==========================================================================

"""
    visualize_quadratic_search(f, f_expr, a, b, N; filename="quadratic_fit_search", fps=1)

Create an animation showing the progress of the Quadratic Interpolation Search method.
The function expression `f_expr` is used in the plot legend.
"""
function visualize_quadratic_search(f, f_expr::String, a_init, b_init, N; filename="quadratic_fit_search", fps=1)
    # Collect history
    history = quadratic_fit_history(f, a_init, b_init; N=N)
    
    # Create directory for PDF frames
    frames_dir = "$(filename)_frames"
    if !isdir(frames_dir)
        mkdir(frames_dir)
    end
    
    # Set default plot settings
    default(size=(800,600), dpi=300, framestyle=:box)
    
    # Determine y-axis limits (use the initial full range)
    x_range_init = range(a_init, b_init, length=500)
    y_values = f.(x_range_init)
    y_min, y_max = minimum(y_values), maximum(y_values)
    y_padding = (y_max - y_min) * 0.1
    y_lims = (y_min - y_padding, y_max + y_padding)

    # Create frames and save PDFs
    frames = []
    
    for i in 1:length(history)
        a_i, γ_i, b_i, y_a, y_γ, y_b, x_est, y_est, p0, p1, p2, is_valid_step = history[i]
        
        # The fitted quadratic polynomial
        P(x) = p2 * x^2 + p1 * x + p0
        
        # Create the main plot
        p = plot(x_range_init, f.(x_range_init), 
                 linewidth=3, 
                 # Include function expression in the LaTeX label
                 label=L"f(x) = %$f_expr", 
                 title=L"Quadratic\ Fit\ Search:\ Iteration\ %$i",
                 xlabel=L"x",
                 ylabel=L"f(x)",
                 ylims=y_lims,
                 legend=(0.77, 0.95)) 
        
        # Plot the interpolating parabola
        plot!(x_range_init, P.(x_range_init), 
              linewidth=2, 
              linestyle=:dash,
              color=:darkorange,
              label=L"P(x)\ (Quadratic\ Fit)")

        # Plot the three interpolation points (a, γ, b)
        scatter!(p, [a_i, γ_i, b_i], [y_a, y_γ, y_b],
                 markersize=8,
                 color=:darkorange,
                 markerstrokecolor=:black,
                 label=L"a, \gamma, b")
        
        # Plot the proposed minimum \bar{x} 
        if is_valid_step
             scatter!(p, [x_est], [y_est],
                      markershape=:circle, 
                      markersize=8,        
                      color=:red,
                      markerstrokecolor=:black,
                      label=L"\bar{x}")
             # Mark the y_est line
             plot!([x_est, x_est], [y_lims[1], y_est], linestyle=:dot, color=:red, linewidth=1, label=false)

        else
             annotate!(a_init, y_lims[2] - y_padding/1.5, 
                       text(L"Algorithm\ Terminated:\ \bar{x}\ was\ outside\ [a,b]",
                            :left, 10, :red))
        end
        
        # Add iteration information
        interval_length = b_i - a_i
        annotate!(a_init, y_lims[2] - y_padding/3,
                  text(L"Current\ Interval\ Length:\ %$(round(interval_length, digits=6))",
                       :left, 10))
        
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
# 3. EXAMPLE USAGE
# ==========================================================================

f_example(x) = 5*exp(x)*sin(x)
# Function expression formatted for LaTeX display
f_expr = "5e^x \\sin(x)" 

# Initial interval for the new function
a_init = -3.0
b_init = 0.0

# Max number of iterations (function evaluations) for the visualization
# N=20 means 3 initial evaluations + 17 loop iterations
N_max = 20 

println("Generating Quadratic Fit Search visualizations for the function (N=$N_max)...")

visualize_quadratic_search(f_example, f_expr, a_init, b_init, N_max, filename="qfs_example", fps=1)

println("All QDS visualizations complete!")
println("Generated files:")
println("  - qfs_example.gif")
println("  - PDF frames in 'qfs_example_frames/'")