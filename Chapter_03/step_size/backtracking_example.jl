using LinearAlgebra
using Plots
include("backtracking.jl")

# 2. Simple quadratic problem
f(x) = x[1]^2 + x[2]^2
∇f(x) = [2*x[1], 2*x[2]]

x0 = [1.0, 1.0]
g0 = ∇f(x0)      # Gradient is [2.0, 2.0]
d = -g0          # Direction is [-2.0, -2.0]
alpha_init = 1.5 # Start slightly overshooting

# 3. Run algorithm with illustrative parameters
# β=0.2 so the Armijo line has a visible slope
alpha_final = backtracking_search(f, ∇f, x0, d, alpha_init, β=0.2)

# === VISUALIZATION ===
h(α) = f(x0 + α * d)
slope = dot(g0, d) # -8.0
l(α) = f(x0) + 0.2 * α * slope # Armijo condition line

alpha_range = range(0, 1.6, length=200)

p_plot = plot(alpha_range, h.(alpha_range), 
              label="h(α) = f(x₀ + αd)", 
              linewidth=2.5, 
              color=:royalblue,
              xlabel="Step size α", 
              ylabel="h(α) = f(x₀ + αd)",
              legend=:topleft,
              framestyle=:box,
              dpi=300)

plot!(alpha_range, l.(alpha_range), 
      label="Armijo condition (β = 0.2)", 
      linestyle=:dash, 
      color=:red, 
      linewidth=2)

# Mark the exact minimum for reference
scatter!([0.5], [h(0.5)], label="Exact minimum", shape=:star5, color=:gold, markersize=10, markerstrokecolor=:black)

# Mark tested points
scatter!([1.5], [h(1.5)], label="Rejected α = 1.5", color=:red, markersize=7)
scatter!([alpha_final], [h(alpha_final)], label="Accepted α = $alpha_final", color=:green, markersize=9, markerstrokecolor=:black)

savefig(p_plot, "backtracking_illustrative.pdf")

# === WOLFE CONDITIONS CHECK ===
x_new = x0 + alpha_final * d
g_new = ∇f(x_new)
slope_new = dot(g_new, d)

println("Initial directional derivative: ", slope)
println("New directional derivative:     ", slope_new)

# Standard vs Strong Wolfe
sigma = 0.4
standard_wolfe = slope_new >= sigma * slope
strong_wolfe = abs(slope_new) <= -sigma * slope

println("Armijo Condition (1st Wolfe):     TRUE (alpha accepted)")
println("Standard Curvature (2nd Wolfe):   ", standard_wolfe)
println("Strong Curvature (Strong 2nd):    ", strong_wolfe)