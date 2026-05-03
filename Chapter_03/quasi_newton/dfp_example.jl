using LinearAlgebra
using Plots

# Import required modules
include(joinpath(@__DIR__, "..", "..", "Chapter_02", "one_dimensional_methods", "golden_section_search_method", "golden_section_search.jl"))
include("dfp.jl")

# Rosenbrock function and its exact gradient
f_rosen(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2

function ∇f_rosen(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end

# --- MAIN OPTIMIZATION LOOP ---
function run_dfp_experiment(x0; max_iter=200, tol=1e-5)
    n = length(x0)
    
    # Initialize method and state (W0 = Identity matrix)
    method = DFPMethod()
    state = OptimizationState(copy(x0), ∇f_rosen(x0), Matrix{Float64}(I, n, n))
    
    x_history = [copy(state.x)]
    
    for i in 1:max_iter
        if norm(state.gradient) < tol
            break
        end
        
        # 1. Compute direction
        d = compute_direction(method, state)
        
        # 2. Line search
        h(α) = f_rosen(state.x + α * d)
        bracket_start, bracket_end = bracket_minimum(h)
        res = golden_section_search(h, bracket_start, bracket_end; tol=1e-8)
        alpha = res.xmin
        
        # 3. Take step to new point
        x_next = state.x + alpha * d
        g_next = ∇f_rosen(x_next)
        
        # 4. Prepare vectors for Quasi-Newton update
        s = x_next - state.x
        y = g_next - state.gradient
        
        # 5. Update inverse Hessian
        update_approximation!(method, state, s, y)
        
        # 6. Store new state for next iteration
        state.x = x_next
        state.gradient = g_next
        push!(x_history, copy(state.x))
    end
    
    return x_history
end

# --- EXPERIMENT AND VISUALIZATION ---
x0 = [0.0, 0.0] 
history_x = run_dfp_experiment(x0)
n_iters = length(history_x) - 1

x_range = range(-0.5, 1.5, length=400)
y_range = range(-0.5, 1.5, length=400)
Z = [f_rosen([xi, yi]) for yi in y_range, xi in x_range]

p1 = contour(x_range, y_range, Z, levels=10 .^ range(-1, 3.5, length=40), 
            color=:viridis, xlabel="x₁", ylabel="x₂", colorbar=false, 
            framestyle=:box, title="DFP Trajectory on Rosenbrock", dpi=300,
            xlims=(-0.1, 1.1), ylims=(-0.1, 1.1))

X_hist = [pt[1] for pt in history_x]
Y_hist = [pt[2] for pt in history_x]

plot!(p1, X_hist, Y_hist, color=:red, linewidth=2.5, marker=:circle, markersize=4, label="DFP ($n_iters iterations)")
scatter!(p1, [x0[1]], [x0[2]], color=:blue, markersize=6, label="Start")
scatter!(p1, [1.0], [1.0], color=:gold, shape=:star5, markersize=10, label="Global Minimum")

savefig(p1, "dfp_rosenbrock.pdf")
println("Successfully saved 'dfp_rosenbrock.pdf'. Iterations: ", n_iters)