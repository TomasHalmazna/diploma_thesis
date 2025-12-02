using Plots
using LaTeXStrings

include("brents_method.jl")

"""
    visualize_brent(f, a, b, ε; filename="brents_search", fps=1)

Create an animation showing the progress of Brent's method using the same visual style
as the dichotomous search example (Blue function, Red interval/minimum).
"""
function visualize_brent(f, a, b, ε; filename="brents_search", fps=1)
    # Run the optimization
    x_min, f_min, iterations, history = brents_method(f, a, b, ε)
    
    # Create directory for frames
    frames_dir = "frames_brent"
    if !isdir(frames_dir)
        mkdir(frames_dir)
    end
    
    # Set default plot settings consistent with previous examples
    default(size=(800,600), dpi=300, framestyle=:box)
    
    # Determine axes limits
    # We create a range slightly larger than initial [a,b] for better view
    margin = (b - a) * 0.1
    x_range = range(a - margin, b + margin, length=300)
    y_values = f.(x_range)
    y_min, y_max = minimum(y_values), maximum(y_values)
    y_padding = (y_max - y_min) * 0.15
    
    frames = []
    
    for i in 1:length(history)
        # Unpack state
        # a_i, b_i: current bracket
        # x_i, fx_i: current best estimate
        # u_i, fu_i: the trial point calculated in this step
        a_i, b_i, x_i, fx_i, u_i, fu_i = history[i]
        
        # 1. Main Plot (Blue function line)
        p = plot(x_range, f.(x_range), 
                linewidth=2, 
                color=:royalblue,   # Matches your request "funkce modře"
                label=L"f(x)",
                title="Brent's Method: Iteration $i",
                xlabel=L"x",
                ylabel=L"f(x)",
                ylims=(y_min - y_padding, y_max + y_padding),
                legend=:topright)
        
        # 2. Search Interval (Red line at bottom)
        plot!([a_i, b_i], [y_min - y_padding/2, y_min - y_padding/2], 
              linewidth=3, 
              color=:red,           # Matches your request "interval červeně"
              label="Search Interval")
        
        # 3. Current Estimate x (Red dot)
        scatter!([x_i], [fx_i],
                markersize=7,
                color=:red,         # Matches your request "odhad červeně"
                label=L"\bar{x}\ (current\ min)")
        
        # 4. Trial Point u (Orange/Gold star - optional but helpful for animation)
        # If u_i is finite (it is NaN for the very first setup step sometimes)
        if !isnan(u_i)
             scatter!([u_i], [fu_i],
                markersize=8,
                shape=:star5,
                color=:orange,
                label=L"u\ (new\ trial)")
        end

        # Add text annotation for interval length
        interval_len = b_i - a_i
        annotate!(a - margin, y_max + y_padding/2, 
                 text("Interval length: $(round(interval_len, digits=6))", :left, 8))
        
        # Save frame
        savefig(p, joinpath(frames_dir, "$(filename)_frame_$i.pdf"))
        push!(frames, p)
    end
    
    # Generate GIF
    anim = Animation()
    for p in frames
        frame(anim, p)
    end
    gif(anim, "$(filename).gif", fps=fps)
    
    return anim
end

# --- EXAMPLE USAGE ---
function run_brent_example()
    # Example function
    f(x) = (x - 2)^2 + 1
    
    # Visualize
    visualize_brent(f, 0.0, 5.0, 1e-4, filename="brent_example")
end

# Uncomment to run
run_brent_example()