using Plots

# Load methods
include("steepest_descent.jl")
include(joinpath(@__DIR__, "..", "..", "Chapter_02", "one_dimensional_methods", "golden_section_search_method", "golden_section_search.jl"))

# Problem definition: Rosenbrock function
f(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
function ∇f(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end

# Run Steepest Descent
x0 = [0.0, 0.0]
x_opt, x_history = run_steepest_descent(f, ∇f, x0)

# === Visualization ===
plot_iters = min(20, length(x_history))
X_hist = [pt[1] for pt in x_history[1:plot_iters]]
Y_hist = [pt[2] for pt in x_history[1:plot_iters]]

x_range = range(-2.0, 2.0, length=400)
y_range = range(-1.5, 3.0, length=400)
Z = [f([xi, yi]) for yi in y_range, xi in x_range]

p = contour(x_range, y_range, Z, levels=10 .^ range(-1, 3.5, length=40), 
            color=:viridis, xlabel="x₁", ylabel="x₂", colorbar=false, 
            framestyle=:box, dpi=300, aspect_ratio=:equal,
            xlim=(-0.5, 1.5), ylim=(-0.5, 1.5), legend=:topleft)

plot!(p, X_hist, Y_hist, color=:red, linewidth=2.0, label="Steepest Descent (first 20 steps)")
scatter!(p, [X_hist[1]], [Y_hist[1]], color=:blue, markersize=6, label="Start")
scatter!(p, [1.0], [1.0], color=:gold, shape=:star5, markersize=10, label="Global Minimum")

# Save the plot
savefig(p, "rosenbrock_zigzag.pdf")
println("Successfully saved the plot as 'rosenbrock_zigzag.pdf'")