using LinearAlgebra
using Plots

# Load the golden section search implementation
include(joinpath(@__DIR__, "..", "..", "Chapter_02", "one_dimensional_methods", "golden_section_search_method", "golden_section_search.jl"))

# Rosenbrock function and its gradient
f(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
function ∇f(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end

# Gradient descent with line search
# initial point
x_history = [[-1.0, -1.0]]
x = copy(x_history[1])

for i in 1:2000
    global x
    g = ∇f(x)
    if norm(g) < 1e-4
        break
    end
    
    d = -g / norm(g)
    h(α) = f(x + α * d)
    
    res = golden_section_search(h, 0.0, 3.0; tol=1e-8)
    alpha = res.xmin 
    
    x = x + alpha * d
    push!(x_history, x)
end

# === VISUALIZATION ===
plot_iters = min(15, length(x_history))
X_hist = [pt[1] for pt in x_history[1:plot_iters]]
Y_hist = [pt[2] for pt in x_history[1:plot_iters]]

x_range = range(-2.0, 2.0, length=400)
y_range = range(-1.5, 3.0, length=400)
Z = [f([xi, yi]) for yi in y_range, xi in x_range]

p = contour(x_range, y_range, Z, levels=10 .^ range(-1, 3.5, length=40), 
            color=:viridis, xlabel="x₁", ylabel="x₂", colorbar=false, 
            framestyle=:box, dpi=300, aspect_ratio=:equal,
            xlim=(-1.5, 1.5), ylim=(-1.5, 1.5))

# Plot path without markers for a clean look
plot!(p, X_hist, Y_hist, color=:red, linewidth=2.0, 
      label="Gradient Descent (first 15 steps)")

scatter!(p, [X_hist[1]], [Y_hist[1]], color=:blue, markersize=6, label="Start")
scatter!(p, [1.0], [1.0], color=:gold, shape=:star5, markersize=10, label="Global Minimum")

savefig(p, "rosenbrock_zigzag.pdf")