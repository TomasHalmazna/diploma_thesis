using LinearAlgebra
using Plots

# Import a function for backtracking line search
include(joinpath(@__DIR__, "..", "step_size", "backtracking.jl"))

# Rosenbrock function and its gradient and Hessian
f_rosen(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2

function ∇f_rosen(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end

function H_rosen(x)
    h11 = 2.0 - 400.0 * (x[2] - 3.0 * x[1]^2)
    h12 = -400.0 * x[1]
    h22 = 200.0
    return [h11 h12; h12 h22]
end

# --- DAMPED NEWTON ALGORITHM ---
function run_damped_newton(x0; max_iter=200, tol=1e-5)
    x = copy(x0)
    x_history = [copy(x)]
    alpha_history = Float64[]
    
    for i in 1:max_iter
        g = ∇f_rosen(x)
        if norm(g) < tol
            break
        end
        
        H_k = H_rosen(x)
        
        # Compute the Newton direction
        d = -(H_k \ g)
        
        # Damped step: Use backtracking line search. 
        # initial alpha = 1.0 (full Newton step) - may be reduced 
        alpha = backtracking_search(f_rosen, ∇f_rosen, x, d, 1.0)
        
        # Update position
        x = x + alpha * d
        push!(x_history, copy(x))
        push!(alpha_history, alpha)
    end
    
    return x_history, alpha_history
end

# --- EXPERIMENT ---
# Initialize at [0, 0]
x0 = [0.0, 0.0]
history_x, history_alpha = run_damped_newton(x0)
n_iters = length(history_alpha)

# --- VISUALIZATION ---

# 1. Subplot: Trajectory on the Rosenbrock function
x_range = range(-0.5, 1.5, length=400)
y_range = range(-0.5, 1.5, length=400)
Z = [f_rosen([xi, yi]) for yi in y_range, xi in x_range]

p1 = contour(x_range, y_range, Z, levels=10 .^ range(-1, 3.5, length=40), 
            color=:viridis, xlabel="x₁", ylabel="x₂", colorbar=false, 
            framestyle=:box, title="Damped Newton Trajectory")

X_hist = [pt[1] for pt in history_x]
Y_hist = [pt[2] for pt in history_x]

# Dynamic label with iteration count
plot!(p1, X_hist, Y_hist, color=:red, linewidth=2.5, marker=:circle, markersize=4, label="Damped Newton ($n_iters iterations)")
scatter!(p1, [x0[1]], [x0[2]], color=:blue, markersize=6, label="Start")
scatter!(p1, [1.0], [1.0], color=:gold, shape=:star5, markersize=10, label="Global Minimum")

# 2. Subplot: Alpha parameter history
iters = 1:n_iters
p2 = plot(iters, history_alpha, 
          linecolor=:royalblue, linewidth=2, marker=:circle, markercolor=:royalblue, markersize=5,
          xlabel="Iteration k", ylabel="Step size αₖ",
          title="Step Size History",
          framestyle=:box, legend=false,
          ylims=(0.0, 1.1), yticks=0.0:0.2:1.0,
          xticks=1:2:n_iters) # Force integer ticks on the x-axis

# Combine into a single figure
final_plot = plot(p1, p2, layout=(1, 2), size=(1000, 450), margin=5Plots.mm)

savefig(final_plot, "damped_newton_example.pdf")
println("Successfully saved the plot as 'damped_newton_example.pdf'")
println("Number of iterations: ", n_iters)