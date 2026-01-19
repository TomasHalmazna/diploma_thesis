using Plots
using LaTeXStrings

# 1. Function definition
# A simple nonlinear function that decreases, increases, then decreases again
phi(alpha) = 1.0 - 1.0*alpha + 2.0*alpha^2 - 0.9*alpha^3

# Derivative at zero is -1.0
slope = -1.0
intercept = 1.0

# Line functions
tangent_line(alpha) = intercept + slope * alpha       # Tangent line (100% slope)
armijo_line(alpha, beta) = intercept + beta * slope * alpha # Armijo line (beta% slope)

# 2. Parameters
beta = 0.2  # Armijo parameter (controls sufficient decrease threshold)
alpha_max = 2.0
alphas = 0.0:0.005:alpha_max

# 3. Colors
color_func = :black
color_armijo = :red  # For sufficient decrease (bold)
color_armijo_line = RGB(0.0, 0.6, 0.9)  # For Armijo rule line (blue)
color_tangent = :grey

# 4. Create base plot
p = plot(alphas, phi.(alphas), 
    label=nothing,
    color=color_func, 
    linewidth=2,
    grid=false,
    framestyle=:origin,
    xlims=(-0.1, 2.1),
    ylims=(-0.2, 1.2),
    size=(900, 400),
    ticks=nothing,
    arrow=true
)

# 5. Add guideline curves
# Tangent line (grey)
plot!(p, alphas, tangent_line.(alphas), 
    label=nothing, color=color_tangent, linewidth=1, linestyle=:solid
)

# Armijo line (blue)
plot!(p, alphas, armijo_line.(alphas, beta), 
    label=nothing, color=color_armijo_line, linewidth=1.5, linestyle=:solid
)

# 6. Highlight "Sufficient Decrease" region
# Instead of filtering array, we create a copy and replace non-matching points with NaN.
# This breaks the line in the graph and prevents connecting disconnected intervals.
y_sufficient = copy(phi.(alphas))
mask = phi.(alphas) .<= armijo_line.(alphas, beta)
y_sufficient[.!mask] .= NaN

plot!(p, alphas, y_sufficient, 
    label=nothing, 
    color=color_armijo, 
    linewidth=4.5
)

# 7. Annotations (updated with adjusted positions)
annotate!(p, [
    (alpha_max - 0.15, -0.15, text(L"\alpha", 12, :black, :right)),
    (0.05, 1.15, text(L"y", 12, :black, :left)),
    (-0.05, -0.1, text(L"0", 12, :black, :right)),

    # Function label
    (1.75, 0.75, text(L"f(x + \alpha d)", 12, :black, :left)),
    
    # Tangent line label
    (0.35, 0.2, text(L"f(x) + \alpha \nabla f^T d", 10, :grey, :left)),
    
    # Armijo line label (with beta)
    (0.9, 0.95, text(L"f(x) + \beta \alpha \nabla f^T d", 10, color_armijo_line, :left)),
    
    # Sufficient decrease label (bold blue)
    (1.1, 0.35, text(L"\mathbf{sufficient\ decrease}", 11, color_armijo, :center))
])

display(p)
savefig("armijo_condition.pdf")