using Plots
using LaTeXStrings

f(x) = x^2
g(x) = 2x

function run_gradient_descent(x0, alpha_init, iterations, type, c=0.8)
    path_x = [x0]; path_y = [f(x0)]
    x = x0
    for k in 0:(iterations-1)
        alpha = (type == :exp) ? alpha_init * (0.9^k) : c / (type == :inv ? (k + 1) : sqrt(k + 1))
        x = x - alpha * g(x)
        push!(path_x, x); push!(path_y, f(x))
    end
    return path_x, path_y
end

x_start = 2.5; iter_count = 5; x_range = -3.0:0.1:3.0; y_curve = f.(x_range)

function make_p(path_x, path_y, title_str)
    p = plot(x_range, y_curve, color=:black, lw=2, title=title_str, legend=false)
    plot!(p, path_x, path_y, color=:green, lw=1.5, marker=:circle, markersize=5, markercolor=:blue)
    scatter!(p, [x_start], [f(x_start)], color=:red, markersize=8)
    return p
end

# Figure 3.1: Failure modes
p1 = make_p(run_gradient_descent(x_start, 0.95, iter_count, :exp)..., "Large Step (Overshooting)")
p2 = make_p(run_gradient_descent(x_start, 0.1, iter_count, :exp)..., "Small Step (Slow Convergence)")
savefig(plot(p1, p2, layout=(1,2), size=(1000, 400)), "step_size_decay.pdf")

# Figure 3.2: Robbins-Monro success
p3 = make_p(run_gradient_descent(x_start, 0, iter_count, :inv, 0.8)..., L"Inverse: $c / (k+1)$")
p4 = make_p(run_gradient_descent(x_start, 0, iter_count, :inv_sqrt, 0.8)..., L"Inverse Sqrt: $c / \sqrt{k+1}$")
savefig(plot(p3, p4, layout=(1,2), size=(1000, 400)), "step_size_rm.pdf")