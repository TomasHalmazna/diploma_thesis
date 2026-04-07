using LinearAlgebra
using Plots

include(joinpath(@__DIR__, "..", "step_size", "backtracking.jl"))
include("lbfgs.jl")

f_rosen(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2

function ∇f_rosen(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end

# Main optimization loop
function run_lbfgs_experiment(x0, m=5; max_iter=200, tol=1e-5)
    method = LBFGSMethod(m)
    
    # Initialize state with an empty history array
    state = OptimizationState(copy(x0), ∇f_rosen(x0), [])
    
    x_history = [copy(state.x)]
    
    for i in 1:max_iter
        if norm(state.gradient) < tol
            break
        end
        
        d = compute_direction(method, state)
        alpha = backtracking_search(f_rosen, ∇f_rosen, state.x, d, 1.0)
        x_next = state.x + alpha * d
        g_next = ∇f_rosen(x_next)
        
        s = x_next - state.x
        y = g_next - state.gradient
        
        update_approximation!(method, state, s, y)
        
        state.x = x_next
        state.gradient = g_next
        push!(x_history, copy(state.x))
    end
    
    return x_history
end

# Experiment and visualization
x0 = [0.0, 0.0] 
history_x = run_lbfgs_experiment(x0, 5) # Memory parameter m = 5
n_iters = length(history_x) - 1

x_range = range(-0.5, 1.5, length=400)
y_range = range(-0.5, 1.5, length=400)
Z = [f_rosen([xi, yi]) for yi in y_range, xi in x_range]

p1 = contour(x_range, y_range, Z, levels=10 .^ range(-1, 3.5, length=40), 
            color=:viridis, xlabel="x₁", ylabel="x₂", colorbar=false, 
            framestyle=:box, title="L-BFGS Trajectory on Rosenbrock (m=5)", dpi=300)

X_hist = [pt[1] for pt in history_x]
Y_hist = [pt[2] for pt in history_x]

plot!(p1, X_hist, Y_hist, color=:red, linewidth=2.5, marker=:circle, markersize=4, label="L-BFGS ($n_iters iterations)")
scatter!(p1, [x0[1]], [x0[2]], color=:blue, markersize=6, label="Start")
scatter!(p1, [1.0], [1.0], color=:gold, shape=:star5, markersize=10, label="Global Minimum")

savefig(p1, "lbfgs_rosenbrock.pdf")
println("Successfully saved 'lbfgs_rosenbrock.pdf'. Iterations: ", n_iters)