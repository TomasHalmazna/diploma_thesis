using Plots
using LaTeXStrings
using Plots.PlotMeasures
pyplot()

# Golden ratio
β = (sqrt(5) - 1) / 2       # ≈ 0.618
α = β^2                     # ≈ 0.382

# Interval endpoints
a_prev = 0.0
b_prev = 1.0
x_plus = a_prev + β * (b_prev - a_prev)
x_minus = a_prev + α * (b_prev - a_prev)

# Create completely blank plot
p = plot(; 
    legend=false, 
    axis=false, 
    grid=false, 
    framestyle=:none, 
    ticks=nothing,
    background_color=:transparent,
    size=(700,200)
)

# Draw main interval line
plot!([a_prev, b_prev], [0, 0], lw=5, color=:black)

# Points
scatter!([a_prev, x_plus, x_minus, b_prev], [0, 0, 0, 0], color=:black, markersize=6)

# Curved arcs
t = range(0, π, length=100)
y_curve1 = 0.15 .* sin.(t)
y_curve2 = 0.08 .* sin.(t)

# larger part
plot!(a_prev .+ (x_plus - a_prev) .* (t ./ π), y_curve1, lw=3, color=:black)
# smaller part
plot!(x_plus .+ (b_prev - x_plus) .* (t ./ π), y_curve2, lw=3, color=:black)

# Labels
annotate!([
    (a_prev, -0.05, text(L"a_{k-1}", 10)),
    (x_plus, -0.05, text(L"x_k^{+}", 10)),
    (x_minus, -0.05, text(L"x_k^{-}", 10)),
    (b_prev, -0.05, text(L"b_{k-1}", 10)),
    ((a_prev + x_plus)/2, 0.22, text(L"x_k^{-} - a_{k-1}", 10)),
    (x_plus + (b_prev - x_plus)/2, 0.22, text(L"b_{k-1} - x_k^{-}", 10)),
    ((a_prev + x_plus)/2, 0.10, text("larger part", 10)),
    (x_plus + (b_prev - x_plus)/2, 0.11, text("smaller part", 10))
])

# Tighten layout — no padding
xlims!(-0.05, 1.05)
ylims!(-0.1, 0.3)
plot!(margin=0mm)

# Save as vector PDF
savefig(p, "golden_section_ratio.pdf")
