using LinearAlgebra
using Plots

# 2D function: Inverted Gaussian bell
f(x) = 1.0 - exp(-(x[1]^2 + x[2]^2))

# Analytical gradient
function ∇f(x)
    E = exp(-(x[1]^2 + x[2]^2))
    return 2.0 * E * x
end

# Analytical Hessian
function H(x)
    E = exp(-(x[1]^2 + x[2]^2))
    return 2.0 * E * [1.0 0.0; 0.0 1.0] - 4.0 * E * (x * x')
end

# Pure Newton method without line search
function run_pure_newton(x0; max_iter=10, tol=1e-5)
    x = copy(x0)
    x_history = [copy(x)]
    
    for i in 1:max_iter
        g = ∇f(x)
        if norm(g) < tol
            break
        end
        
        H_k = H(x)
        d = nothing
        try
            d = -(H_k \ g)
        catch
            # Hessian became singular - divergence reached
            println("Iteration $i: Hessian is singular. Divergence reached.")
            break
        end
        
        # Pure step (alpha = 1.0)
        x = x + d
        push!(x_history, copy(x))
    end
    
    return x_history
end

# EXPERIMENTS

# 1. Good initialization (within convergence region)
x0_good = [-0.3, 0.3]
history_good = run_pure_newton(x0_good, max_iter=5)

# 2. Bad initialization (beyond inflection point, Hessian is not positive definite)
x0_bad = [0.8, 0.8]
history_bad = run_pure_newton(x0_bad, max_iter=5)

# VISUALIZATION
x_range = range(-3.0, 3.0, length=400)
y_range = range(-3.0, 3.0, length=400)
Z = [f([xi, yi]) for yi in y_range, xi in x_range]

p = contour(x_range, y_range, Z, levels=20, 
            color=:Blues, xlabel="x", ylabel="y", colorbar=false, 
            framestyle=:box, dpi=300, aspect_ratio=:equal,
            xlim=(-3.0, 3.0), ylim=(-3.0, 3.0), legend=:topleft)

# Successful trajectory
X_good = [pt[1] for pt in history_good]
Y_good = [pt[2] for pt in history_good]
plot!(p, X_good, Y_good, color=:green, linewidth=2.5, marker=:circle, markersize=5, label="Good initialization (Converges)")

for (i, pt) in enumerate(history_good)
    if i <= 3
        annotate!(p, pt[1] - 0.4, pt[2] - 0.1, text("x$(i-1)", 10, :green, :left))
    end
end

# Diverging trajectory
X_bad = [pt[1] for pt in history_bad]
Y_bad = [pt[2] for pt in history_bad]
plot!(p, X_bad, Y_bad, color=:red, linewidth=2.5, marker=:circle, markersize=5, linestyle=:dash, label="Bad initialization (Diverges)")

for (i, pt) in enumerate(history_bad)
    if i <= 3
        annotate!(p, pt[1] + 0.15, pt[2], text("x$(i-1)", 10, :red, :left))
    end
end

# Global minimum
scatter!(p, [0.0], [0.0], color=:gold, shape=:star5, markersize=12, label="Global Minimum")

savefig(p, "newton_divergence.pdf")
println("Successfully saved the plot as 'newton_divergence.pdf'")