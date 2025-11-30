using Plots
using LaTeXStrings

# ==========================================================================
# 1. QUADRATIC FIT SEARCH CORE FUNCTIONS
# ==========================================================================

function quadratic_fit_search_step(a::Float64, γ::Float64, b::Float64, y_a::Float64, y_γ::Float64, y_b::Float64)
    D = y_a * (γ - b) + y_γ * (b - a) + y_b * (a - γ)
    N_num = y_a * (γ^2 - b^2) + y_γ * (b^2 - a^2) + y_b * (a^2 - γ^2)
    
    if abs(D) < 1e-12
        x_est = (a + b) / 2.0
    else
        x_est = 0.5 * N_num / D
    end
    
    return x_est, D, N_num
end

function compute_parabola_coefficients(a::Float64, γ::Float64, b::Float64, y_a::Float64, y_γ::Float64, y_b::Float64, D::Float64, N_num::Float64)
    K = (a - γ) * (a - b) * (γ - b)
    
    p2 = abs(K) < 1e-12 ? 0.0 : D / K
    p1 = abs(K) < 1e-12 ? 0.0 : -N_num / K
    p0 = y_a - p2 * a^2 - p1 * a
    
    return p0, p1, p2
end

# ==========================================================================
# 2. VISUALIZATION FUNCTION FOR EDGE CASES
# ==========================================================================

function visualize_edge_case(f, f_expr::String, a_init, b_init; filename="edge_case")
    # Initial setup
    γ = (a_init + b_init) / 2.0
    y_a = f(a_init)
    y_γ = f(γ)
    y_b = f(b_init)
    
    # Compute first step of quadratic fit search
    x_est, D, N_num = quadratic_fit_search_step(a_init, γ, b_init, y_a, y_γ, y_b)
    
    # Check if x_est is valid (inside bracket)
    is_valid_step = !(abs(D) < 1e-12 || x_est <= a_init || x_est >= b_init)
    
    # Evaluate function at x_est if valid
    y_est = is_valid_step ? f(x_est) : NaN
    
    # Compute parabola coefficients
    p0, p1, p2 = compute_parabola_coefficients(a_init, γ, b_init, y_a, y_γ, y_b, D, N_num)
    P(x) = p2 * x^2 + p1 * x + p0
    
    # Find parabola vertex to expand visualization range appropriately
    x_vertex = p2 != 0 ? -p1 / (2 * p2) : (a_init + b_init) / 2.0
    
    # Expand x-range to include parabola vertex with generous margins
    interval_width = b_init - a_init
    margin = 0.5 * interval_width  # 50% margin on each side
    
    # Calculate initial bounds that include vertex
    x_min_candidate = min(a_init - margin, x_vertex - margin)
    x_max_candidate = max(b_init + margin, x_vertex + margin)
    
    # Handle domain restrictions based on the initial interval
    # For sqrt and ln functions that require positive x
    if a_init >= 0
        x_min = max(x_min_candidate, 1e-6)  # Small positive value for sqrt/ln
    else
        x_min = x_min_candidate
    end
    x_max = x_max_candidate
    
    x_range = range(x_min, x_max, length=500)
    
    # Calculate y-limits ensuring we capture both function and parabola
    y_f = f.(x_range)
    y_p = P.(x_range)
    y_all = vcat(y_f, y_p)
    y_min, y_max = minimum(y_all), maximum(y_all)
    y_padding = (y_max - y_min) * 0.15  # Increased padding to avoid legend overlap
    y_lims = (y_min - y_padding, y_max + y_padding)
    
    # Plot setup (no title, as per requirements)
    default(size=(800, 600), dpi=300, framestyle=:box)
    p = plot(x_range, f.(x_range), 
             linewidth=3, 
             label=L"f(x) = %$f_expr", 
             xlabel=L"x",
             ylabel=L"f(x)",
             ylims=y_lims,
             legend=(0.77, 0.95))
    
    # Plot the interpolating parabola
    plot!(p, x_range, P.(x_range), 
          linewidth=2, 
          linestyle=:dash,
          color=:darkorange,
          label=L"P(x)\ (Quadratic\ Fit)")
    
    # Visualize the interval [a, b] with a shaded region
    vline!(p, [a_init], linewidth=2, color=:blue, linestyle=:solid, label=L"[a, b]", alpha=0.7)
    vline!(p, [b_init], linewidth=2, color=:blue, linestyle=:solid, label="", alpha=0.7)
    plot!(p, [a_init, b_init], [y_lims[1], y_lims[1]], linewidth=0, 
          fillrange=[y_lims[2], y_lims[2]], alpha=0.15, color=:blue, label="")
    
    # Plot the three interpolation points (a, γ, b)
    scatter!(p, [a_init, γ, b_init], [y_a, y_γ, y_b],
             markersize=8,
             color=:darkorange,
             markerstrokecolor=:black,
             label=L"a, \gamma, b")
    
    # Plot the proposed minimum x_est (only if valid)
    if is_valid_step
        scatter!(p, [x_est], [y_est],
                 markershape=:circle, 
                 markersize=8,        
                 color=:red,
                 markerstrokecolor=:black,
                 label=L"\bar{x}")
        # Mark the y_est line
        plot!(p, [x_est, x_est], [y_lims[1], y_est], linestyle=:dot, color=:red, linewidth=1, label=false)
    else
        # For invalid case, show x_est as red dot with dotted line (same style as valid case)
        y_x_est = f(x_est)
        scatter!(p, [x_est], [y_x_est],
                 markershape=:circle, 
                 markersize=8,        
                 color=:red,
                 markerstrokecolor=:black,
                 label=L"\bar{x}")
        # Mark the y_est line with dotted style
        plot!(p, [x_est, x_est], [y_lims[1], y_x_est], linestyle=:dot, color=:red, linewidth=1, label=false)
    end
    
    # Save as PDF in edge_cases_examples folder
    savefig(p, joinpath("edge_cases_examples", "$(filename).pdf"))
    
    return p
end

# ==========================================================================
# 3. EDGE CASE EXAMPLES
# ==========================================================================

println("Generating Quadratic Fit Search edge case visualizations...\n")

# Edge Case 1: f(x) = sqrt(x) on [0,2]
# This leads to a concave fitted parabola
println("Edge Case 1: Concave parabola (f(x) = √x on [0,2])")
f1(x) = sqrt(x)
f1_expr = "\\sqrt{x}"
a1 = 0.0
b1 = 2.0
visualize_edge_case(f1, f1_expr, a1, b1, filename="qfs_edge_case_1_concave")
println("  ✓ Saved: edge_cases_examples/qfs_edge_case_1_concave.pdf\n")

# Edge Case 2: f(x) = -ln(x) on [1,3]
# This leads to a convex parabola with vertex outside [a,b],
# causing the algorithm to terminate
println("Edge Case 2: Vertex outside interval (f(x) = -ln(x) on [1,3])")
f2(x) = -log(x)
f2_expr = "-\\ln(x)"
a2 = 1.0
b2 = 3.0
visualize_edge_case(f2, f2_expr, a2, b2, filename="qfs_edge_case_2_vertex_outside")
println("  ✓ Saved: edge_cases_examples/qfs_edge_case_2_vertex_outside.pdf\n")

println("All edge case visualizations complete!")
println("Generated files in 'edge_cases_examples/' folder:")
println("  - qfs_edge_case_1_concave.pdf")
println("  - qfs_edge_case_2_vertex_outside.pdf")
