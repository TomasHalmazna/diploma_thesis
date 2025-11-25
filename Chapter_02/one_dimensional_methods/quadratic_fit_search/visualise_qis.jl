using Plots
using LaTeXStrings

# ==========================================================================
# 1. QUADRATIC FIT SEARCH CORE ALGORITHM
# ==========================================================================

"""
    quadratic_fit_search_step(f, a, γ, b, y_a, y_γ, y_b)

Calculates the minimum (x_star) of the quadratic polynomial P(x) interpolating the points
(a, y_a), (γ, y_γ), and (b, y_b).

Returns: (x_star, D, N_num), where D is the denominator and N_num is the numerator.
"""
function quadratic_fit_search_step(a::Float64, γ::Float64, b::Float64, y_a::Float64, y_γ::Float64, y_b::Float64)
    # Denominator (D) and Numerator (N_num) of the x* formula:
    D = y_a * (γ - b) + y_γ * (b - a) + y_b * (a - γ)
    N_num = y_a * (γ^2 - b^2) + y_γ * (b^2 - a^2) + y_b * (a^2 - γ^2)
    
    # Handle degenerate parabola (D near zero)
    if abs(D) < 1e-12
        x_star = (a + b) / 2.0 # Return midpoint as fallback
    else
        x_star = 0.5 * N_num / D
    end
    
    return x_star, D, N_num
end


"""
    quadratic_fit_history(f, a::Float64, b::Float64; N::Int=10, tol::Float64=1e-8)

Helper function to run QIS and record the state of the search for visualization.

Returns a list of tuples containing:
(a, γ, b, y_a, y_γ, y_b, x*, y*, p0, p1, p2, is_valid_step)
where p0, p1, p2 are coefficients of the interpolating parabola P(x) = p2*x^2 + p1*x + p0.
"""
function quadratic_fit_history(f, a::Float64, b::Float64; N::Int=10, tol::Float64=1e-8)
    γ = (a + b) / 2.0
    y_a = f(a)
    y_γ = f(γ)
    y_b = f(b)
    
    # Store: (a, γ, b, y_a, y_γ, y_b, x*, y*, p0, p1, p2, is_valid_step)
    history = []
    
    for k = 1:N-3
        # Check for convergence based on interval length
        if (b - a) < tol
             break
        end

        # --- 1. Compute interpolation point x* ---
        x_star, D, N_num = quadratic_fit_search_step(a, γ, b, y_a, y_γ, y_b)
        
        is_valid_step = true

        # Check for break condition (minimum outside bracket or invalid x*)
        if abs(D) < 1e-12 || x_star <= a || x_star >= b
            is_valid_step = false
        end
        
        y_star = f(x_star)

        # --- 2. Compute Parabola Coefficients P(x) = p2*x^2 + p1*x + p0 for Plotting ---
        K = (a-γ) * (a-b) * (γ-b)
        
        # Calculate coefficients carefully, handling the D=0 case for plotting the parabola
        p2 = abs(K) < 1e-12 ? 0.0 : D / K
        p1 = abs(K) < 1e-12 ? 0.0 : -N_num / K
        p0 = y_a - p2 * a^2 - p1 * a

        # Store current state before updating a, γ, b
        push!(history, (a, γ, b, y_a, y_γ, y_b, x_star, y_star, p0, p1, p2, is_valid_step))
        
        # --- 3. Update the interval ---
        if !is_valid_step
             break
        end

        if x_star > γ
            if y_star >= y_γ
                b = x_star
                y_b = y_star
            else
                a = γ
                y_a = y_γ
                γ = x_star
                y_γ = y_star
            end
        else
            if y_star >= y_γ
                a = x_star
                y_a = y_star
            else
                b = γ
                y_b = y_γ
                γ = x_star
                y_γ = y_star
            end
        end
    end
    return history
end


# ==========================================================================
# 2. VISUALIZATION FUNCTION
# ==========================================================================

"""
    visualize_quadratic_search(f, a, b, N; filename="quadratic_fit_search", fps=1)

Create an animation showing the progress of the Quadratic Interpolation Search method.
Saves both vector graphics (PDF) of each frame and the final GIF animation.
"""
function visualize_quadratic_search(f, a_init, b_init, N; filename="quadratic_fit_search", fps=1)
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
        a_i, γ_i, b_i, y_a, y_γ, y_b, x_star, y_star, p0, p1, p2, is_valid_step = history[i]
        
        # The fitted quadratic polynomial
        P(x) = p2 * x^2 + p1 * x + p0
        
        # Create the main plot
        p = plot(x_range_init, f.(x_range_init), 
                 linewidth=3, 
                 label=L"f(x)",
                 title=L"Quadratic\ Fit\ Search:\ Iteration\ %$i",
                 xlabel=L"x",
                 ylabel=L"f(x)",
                 ylims=y_lims,
                 legend=:topright)
        
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
        
        # Plot the proposed minimum x*
        if is_valid_step
             scatter!(p, [x_star], [y_star],
                      markershape=:star5,
                      markersize=10,
                      color=:red,
                      markerstrokecolor=:black,
                      label=L"x^\star")
             # Mark the y* line
             plot!([x_star, x_star], [y_lims[1], y_star], linestyle=:dot, color=:red, linewidth=1, label=false)

        else
             annotate!(a_init, y_lims[2] - y_padding/1.5, 
                       text(L"Algorithm\ Terminated:\ x^\star\ was\ outside\ [a,b]",
                            :left, 10, :red))
        end
        
        # Plot current search interval
        plot!([a_i, b_i], [y_lims[1] + y_padding/4, y_lims[1] + y_padding/4],
              linewidth=4,
              color=:steelblue,
              label=L"Search\ Interval\ [a, b]")
        
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

# A suitable unimodal function where QIS works well
# f(x) = 0.5x^2 - sin(x) has a minimum near x ≈ 0.824
# f_example(x) = 0.5 * x^2 - sin(x)

# New example function resembling the image (a cubic polynomial)
# It has a local minimum around x=0.58 and x=1.42
#f_new_example(x) = (x-1.5)^3 + 3.0*(x-1.5)^2 + (x-1.5)

f_new_example(x) = 5*exp(x)*sin(x)

# Initial interval for the new function
a_init_new = -3.0
b_init_new = 0.0

# Max number of iterations for the visualization
N_max = 20 

println("Generating Quadratic Fit Search visualizations for the function (N=$N_max)...")

visualize_quadratic_search(f_new_example, a_init_new, b_init_new, N_max, filename="qfs_example", fps=1)

println("All QIS visualizations complete!")
println("Generated files:")
println("  - qfs_example.gif")
println("  - PDF frames in 'qfs_example_frames/'")