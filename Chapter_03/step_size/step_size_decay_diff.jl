using Plots

# 1. Problem Definition
# Simple quadratic function: f(x) = x^2
f(x) = x^2
# Its derivative (gradient): f'(x) = 2x
g(x) = 2x

# 2. Helper function for Gradient Descent
function run_gradient_descent(x0, learning_rate, iterations, decay_rate=0.95)
    path_x = [x0]
    path_y = [f(x0)]
    
    x = x0
    current_lr = learning_rate
    for i in 1:iterations
        # Gradient Descent step: x_new = x - alpha * gradient
        x = x - current_lr * g(x)
        # Apply learning rate decay
        current_lr = current_lr * decay_rate
        
        push!(path_x, x)
        push!(path_y, f(x))
    end
    return path_x, path_y
end

# 3. Setting parameters for visualization
x_start = 2.5       # Starting point (red dot on the right)
iter_count = 5      # Just a few steps for illustration

# A) Large step (Overshooting - Figure 7.49)
# For f(x)=x^2, the critical value alpha = 1.0 (divergence). 
# For oscillation with convergence, we choose something between 0.5 and 1.0.
alpha_large = 0.95   
decay_large = 0.9
path_x_large, path_y_large = run_gradient_descent(x_start, alpha_large, iter_count, decay_large)

# B) Small step (Undershooting - Figure 7.50)
alpha_small = 0.1
decay_small = 0.9
path_x_small, path_y_small = run_gradient_descent(x_start, alpha_small, iter_count, decay_small)

# 4. Visualization
x_range = -3.0:0.1:3.0
y_curve = f.(x_range)

# Plot 1: Too large step size
p1 = plot(x_range, y_curve, label="f(x)", color=:black, lw=2, title="Large Step Size (Overshooting)", legend=false)
plot!(p1, path_x_large, path_y_large, label="Iterace", color=:green, lw=1.5, marker=:circle, markersize=5, markercolor=:blue)
scatter!(p1, [x_start], [f(x_start)], color=:red, markersize=8, label="Start") # Red start
xlims!(p1, -3, 3)
ylims!(p1, 0, 9)

# Plot 2: Too small step size
p2 = plot(x_range, y_curve, label="f(x)", color=:black, lw=2, title="Small Step Size (Slow Convergence)", legend=false)
plot!(p2, path_x_small, path_y_small, label="Iterace", color=:green, lw=1.5, marker=:circle, markersize=5, markercolor=:blue)
scatter!(p2, [x_start], [f(x_start)], color=:red, markersize=8, label="Start") # Red start
xlims!(p2, -3, 3)
ylims!(p2, 0, 9)

# Display side by side
#final_plot = plot(p1, p2, layout=(1,2), size=(1000, 400))
#display(final_plot)

# Export to PDF
savefig(final_plot, "step_size_decay.pdf")