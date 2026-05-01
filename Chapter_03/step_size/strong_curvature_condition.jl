using Plots
using LaTeXStrings

# 1. Function and its derivative definition
phi(alpha) = 1.0 - 1.0*alpha + 2.0*alpha^2 - 0.9*alpha^3
dphi(alpha) = -1.0 + 4.0*alpha - 2.7*alpha^2  # Derivative f'(alpha)

# Initial slope
slope0 = dphi(0.0)

# 2. Parameters
sigma = 0.2  # Curvature parameter
alpha_max = 1.9
alphas = 0.0:0.005:alpha_max

# 3. Colors
color_func = :black
color_highlight = :red
color_tangent = RGB(0.0, 0.6, 0.9)

# 4. Create base plot
p2 = plot(alphas, phi.(alphas), 
    label=nothing, color=color_func, linewidth=1.5,
    grid=false, framestyle=:origin, xlims=(-0.16, 2.1), ylims=(-0.2, 1.2),
    size=(680, 480), ticks=nothing, arrow=true, legend=(0.17, 0.30), 
    legendfontsize=10, foreground_color_legend=:black, legend_background_color=:white
)

# 5. Highlight "Strong Curvature Condition" region
# Condition: |dphi(alpha)| <= -sigma * slope0
y_strong = copy(phi.(alphas))
mask_strong = abs.(dphi.(alphas)) .<= -sigma * slope0
y_strong[.!mask_strong] .= NaN

plot!(p2, alphas, y_strong, 
    label="Strong curvature condition satisfied", color=color_highlight, linewidth=4.5
)

# Draw the threshold lines (dashed) - LOWER AND UPPER BOUNDS
plot!(p2, alphas, phi(0.0) .+ alphas .* (sigma * slope0), 
    label=raw"Threshold slopes: $\pm \sigma \nabla f(x_k)^T d_k$", 
    color=color_tangent, linestyle=:dash, linewidth=1.5
)
plot!(p2, alphas, phi(0.0) .+ alphas .* (-sigma * slope0), 
    label=nothing,
    color=color_tangent, linestyle=:dash, linewidth=1.5
)

# 6. Helper function to draw short tangent segments
function plot_tangent!(p, a, color; len=0.35, lab=nothing)
    x_vals = [a - len/2, a + len/2]
    y_vals = [phi(a) - (len/2)*dphi(a), phi(a) + (len/2)*dphi(a)]
    plot!(p, x_vals, y_vals, label=lab, color=color, linewidth=1.5)
end

# Draw tangets in specific points representing different states
plot_tangent!(p2, 0.0, color_tangent, len=0.4, lab=raw"Local slopes: $\nabla f(x_k + \alpha_k d_k)^T d_k$")    
plot_tangent!(p2, 0.35, color_tangent)
plot_tangent!(p2, 0.74, color_tangent)
plot_tangent!(p2, 1.15, color_tangent)

# Add black dot at f(x) point
scatter!(p2, [0.0], [phi(0.0)], label=nothing, color=:black, markersize=5)

# 7. Annotations
annotate!(p2, [
    (alpha_max - 0.15, -0.15, text(L"\alpha_k", 12, :black, :right)),
    (0.05, 1.15, text(L"y", 12, :black, :left)),
    (-0.05, -0.1, text(L"0", 12, :black, :right)),
    (1.08, 1.19, text(L"f(x_k + \alpha_k d_k)", 12, :black, :left)),
    (-0.03, 0.98, text(L"f(x_k)", 12, :black, :right))
])

display(p2)
savefig("strong_curvature_condition.pdf")