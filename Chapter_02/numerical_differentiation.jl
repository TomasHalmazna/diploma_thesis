# Example: Numerical differentiation of f(x) = e^x at x = 0

using Printf

# Define the function
f(x) = exp(x)

# Exact derivative at x = 0
fprime_exact = 1.0

# Define step sizes
h_values = 10.0 .^ (-1:-1:-9)

# Initialize arrays to store results
forward_val = zeros(length(h_values))
central_val = zeros(length(h_values))
forward_err = zeros(length(h_values))
central_err = zeros(length(h_values))

# Compute finite difference approximations
for (i, h) in enumerate(h_values)
    forward_val[i] = (f(0 + h) - f(0)) / h                # Forward difference
    central_val[i] = (f(0 + h) - f(0 - h)) / (2h)         # Central difference
    forward_err[i] = forward_val[i] - fprime_exact
    central_err[i] = central_val[i] - fprime_exact
end

# Print results
println("  h\t\tForward\t\t\tError\t\t\tCentral\t\t\tError")
for i in 1:length(h_values)
    @printf("%-10.0e\t%.12f\t%.12e\t%.12f\t%.12e\n",
        h_values[i],
        forward_val[i], forward_err[i],
        central_val[i], central_err[i])
end

using Plots

p = plot(h_values, abs.(forward_err),
    xscale = :log10, yscale = :log10,
    label = "Forward",
    xlabel = "h",
    ylabel = "Absolute Error",
    title = "Error in Numerical Differentiation of \$e^x\$ at \$x=0\$",
    titlefontsize = 10,
    legend = :topleft,
    yticks = 10.0 .^ (-16:2:0),
    linewidth = 3)

plot!(p, h_values, abs.(central_err), label = "Central", linewidth = 3)

# export the plot as vector graphic pdf file to the current working directory
savefig(p, "numerical_differentiation_error.pdf")