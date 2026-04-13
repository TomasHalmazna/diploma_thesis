using Plots
using LinearAlgebra
using LaTeXStrings

# Include the Conjugate Gradient implementation and Golden Section Search
include("conjugate_gradient.jl")
include(joinpath(@__DIR__, "..", "..", "Chapter_02", "one_dimensional_methods", "golden_section_search_method", "golden_section_search.jl"))

f(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
function ∇f(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end

mutable struct ConjugateGradientWithBeta
    variant::Symbol
    d_prev::Union{Nothing, Vector{Float64}}
    g_prev::Union{Nothing, Vector{Float64}}
    ConjugateGradientWithBeta(; variant=:PR) = new(variant, nothing, nothing)
end

function compute_direction(method::ConjugateGradientWithBeta, g_k)
    if method.d_prev === nothing
        # First step is standard steepest descent
        d_k = -g_k
        beta = 0.0
    else
        # Polak-Ribiere formula
        beta = dot(g_k - method.g_prev, g_k) / dot(method.g_prev, method.g_prev)
        d_k = -g_k + beta * method.d_prev
    end
    
    # Store history for the next iteration
    method.d_prev = copy(d_k)
    method.g_prev = copy(g_k)
    return d_k, beta
end

# Symmetric log transformation to visualize both huge values and zero-crossings
symlog(x) = sign(x) * log10(1.0 + abs(x))

function run_cg_detailed_analysis(f, ∇f, x0; max_iter=2000, tol=1e-4)
    x = copy(x0)
    
    x_hist = [copy(x)]
    beta_hist = [0.0]
    desc_hist = [dot(∇f(x), -∇f(x))] # Initial steepest descent condition
    grad_norm_hist = [norm(∇f(x))]
    
    optimizer = ConjugateGradientWithBeta(variant=:PR)
    fail_reason = "Reached max iterations"
    
    for i in 1:max_iter
        g = ∇f(x)
        g_norm = norm(g)
        
        if g_norm < tol
            fail_reason = "Converged successfully"
            break
        end
        
        d, beta = compute_direction(optimizer, g)
        descent_val = dot(g, d)
        
        push!(beta_hist, beta)
        push!(desc_hist, descent_val)
        push!(grad_norm_hist, g_norm)
        
        # 1. Catch loss of descent direction (g^T d >= 0)
        if descent_val >= 0
            fail_reason = "Loss of descent direction (g^T d >= 0) at iter $i"
            break
        end
        
        # 2. Catch numerical overflow (NaN or Inf)
        if any(isnan, d) || any(isinf, d)
            fail_reason = "Numerical overflow (NaN/Inf) at iter $i"
            break
        end
        
        # Exact line search using golden section search
        h(α) = f(x + α * d)
        res = golden_section_search(h, 0.0, 3.0; tol=1e-8)
        
        x = x + res.xmin * d
        push!(x_hist, copy(x))
    end
    
    return x_hist, beta_hist, desc_hist, grad_norm_hist, fail_reason
end

# Run the analysis
x0 = [0.0, 0.0]
x_hist, beta_hist, desc_hist, grad_norm_hist, fail_reason = run_cg_detailed_analysis(f, ∇f, x0)

println("\n=== Optimization Terminated ===")
println("Reason: $fail_reason")
println("Total completed steps: $(length(x_hist)-1)")

# === Visualization ===
x_range = range(-2.0, 2.0, length=400)
y_range = range(-1.5, 3.0, length=400)
Z = [f([xi, yi]) for yi in y_range, xi in x_range]

X_hist = [pt[1] for pt in x_hist]
Y_hist = [pt[2] for pt in x_hist]

# Plot 1: Optimization Path
path_title = "Polak-Ribière ($(length(X_hist)-1) steps)"
p1 = contour(x_range, y_range, Z, levels=10 .^ range(-1, 3.5, length=40), 
            color=:viridis, colorbar=false, framestyle=:box, legend=false,
            xlim=(-0.25, 1.25), ylim=(-0.15, 1.35), 
            title=path_title,
            xlabel=L"$x_1$", ylabel=L"$x_2$")
plot!(p1, X_hist, Y_hist, color=:red, lw=2, marker=:circle, ms=4)
scatter!(p1, [X_hist[1]], [Y_hist[1]], color=:blue, ms=6)

# Plot 2: Beta (Symmetric Log Scale)
p2 = plot(0:(length(beta_hist)-1), symlog.(beta_hist),
          title=L"$\beta_k$ (SymLog Scale)", color=:darkblue, lw=2, legend=false,
          xlabel=L"Iteration $k$", ylabel=L"$\operatorname{symlog}(\beta_k)$")
hline!(p2, [0.0], color=:red, ls=:dash)

# Plot 3: Descent Condition g^T d (Symmetric Log Scale)
# This will clearly show values dipping into deep negatives and then crossing 0
p3 = plot(0:(length(desc_hist)-1), symlog.(desc_hist), 
          title=L"$g_k^T d_k$ (SymLog Scale)", 
          color=:purple, lw=2, legend=false,
          xlabel=L"Iteration $k$", ylabel=L"$\operatorname{symlog}(g_k^T d_k)$")
hline!(p3, [0.0], color=:red, ls=:dash) # Zero-crossing threshold
scatter!(p3, [length(desc_hist)-1], [symlog(desc_hist[end])], color=:red, ms=5) # Mark the failure point

# Plot 4: Gradient Norm (Standard Log Scale)
p4 = plot(0:(length(grad_norm_hist)-1), grad_norm_hist, yscale=:log10,
          title=L"$\|\nabla f(x_k)\|$ (Log Scale)", color=:green, lw=2, legend=false,
          xlabel=L"Iteration $k$", ylabel=L"$\log_{10}\|\nabla f\|$")

# Combine plots
p_combined = plot(p1, p2, p3, p4, layout=(2,2), size=(1000, 800), margin=5Plots.mm)
savefig(p_combined, "rosenbrock_pr_detailed_failure.pdf")
println("Saved detailed failure analysis to 'rosenbrock_pr_detailed_failure.pdf'")