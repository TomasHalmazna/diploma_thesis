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
        d_k = -g_k
        beta = 0.0
    else
        beta = dot(g_k - method.g_prev, g_k) / dot(method.g_prev, method.g_prev)
        d_k = -g_k + beta * method.d_prev
    end
    
    method.d_prev = copy(d_k)
    method.g_prev = copy(g_k)
    return d_k, beta
end

symlog(x) = sign(x) * log10(1.0 + abs(x))

# --- Nová funkce pro Bracketing ---
function bracket_minimum(h, a=0.0, initial_step=1e-4, expansion=2.0, max_iter=50)
    f_a = h(a)
    b = a + initial_step
    f_b = h(b)
    
    # Pokud už první krok zhoršil funkci, minimum je velmi blízko nuly
    if f_b > f_a
        return 0.0, b
    end
    
    c = b + expansion * (b - a)
    f_c = h(c)
    
    for _ in 1:max_iter
        if f_c > f_b
            return a, c # Minimum ohraničeno
        end
        a, f_a = b, f_b
        b, f_b = c, f_c
        c = b + expansion * (b - a)
        f_c = h(c)
    end
    return a, c # Fallback, pokud nenajde
end
# ----------------------------------

function run_cg_detailed_analysis(f, ∇f, x0; max_iter=2000, tol=1e-4)
    x = copy(x0)
    
    x_hist = [copy(x)]
    alpha_hist = Float64[]
    desc_hist = [dot(∇f(x), -∇f(x))] 
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
        
        push!(desc_hist, descent_val)
        push!(grad_norm_hist, g_norm)
        
        if descent_val >= 0
            fail_reason = "Loss of descent direction (g^T d >= 0) at iter $i"
            break
        end
        
        if any(isnan, d) || any(isinf, d)
            fail_reason = "Numerical overflow (NaN/Inf) at iter $i"
            break
        end
        
        # Exact line search s bracketingem
        h(α) = f(x + α * d)
        bracket_start, bracket_end = bracket_minimum(h)
        res = golden_section_search(h, bracket_start, bracket_end; tol=1e-8)
        alpha = res.xmin
        
        push!(alpha_hist, alpha)
        
        x = x + alpha * d
        push!(x_hist, copy(x))
    end
    
    return x_hist, alpha_hist, desc_hist, grad_norm_hist, fail_reason
end

# Run the analysis
x0 = [0.0, 0.0]
x_hist, alpha_hist, desc_hist, grad_norm_hist, fail_reason = run_cg_detailed_analysis(f, ∇f, x0)

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

# Plot 2: Alpha values
p2 = plot(1:length(alpha_hist), alpha_hist,
          title=L"Step Size $\alpha_k$ (Log Scale)", color=:darkorange, lw=2, legend=false,
          xlabel=L"Iteration $k$", ylabel=L"$\log_{10} \alpha_k$")

# Plot 3: Descent Condition g^T d
p3 = plot(0:(length(desc_hist)-1), symlog.(desc_hist), 
          title=L"$g_k^T d_k$ (SymLog Scale)", 
          color=:purple, lw=2, legend=false,
          xlabel=L"Iteration $k$", ylabel=L"$\operatorname{symlog}(g_k^T d_k)$")
hline!(p3, [0.0], color=:red, ls=:dash) 
scatter!(p3, [length(desc_hist)-1], [symlog(desc_hist[end])], color=:red, ms=5)

# Plot 4: Gradient Norm 
p4 = plot(0:(length(grad_norm_hist)-1), grad_norm_hist, yscale=:log10,
          title=L"$\|\nabla f(x_k)\|$ (Log Scale)", color=:green, lw=2, legend=false,
          xlabel=L"Iteration $k$", ylabel=L"$\log_{10}\|\nabla f\|$")

p_combined = plot(p1, p2, p3, p4, layout=(2,2), size=(1000, 800), margin=5Plots.mm)
savefig(p_combined, "rosenbrock_pr_detailed_bracketing.pdf")
println("Saved detailed failure analysis to 'rosenbrock_pr_detailed_bracketing.pdf'")