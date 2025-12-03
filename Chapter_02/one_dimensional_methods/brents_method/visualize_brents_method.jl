using Plots
using LaTeXStrings
using Measures # Required for margin adjustments

# Load the algorithm
include("brents_method.jl")

"""
    visualize_brent(f, a, b, ε; filename="brents_search", fps=1)

Visualizes Brent's method with refined aesthetics matching QFS examples:
- Italicized title and text info
- Adjusted margins to prevent label clipping
- Blue function line, Red interval, Bullseye point markers
"""
function visualize_brent(f, a, b, ε; filename="brent_full", fps=1)
    # Run the algorithm
    x_min, f_min, iterations, history = brents_method(f, a, b, ε)
    
    # Setup directory
    frames_dir = "frames_$(filename)"
    if !isdir(frames_dir)
        mkdir(frames_dir)
    end
    
    # Plot settings
    # Increased DPI for crisp text, added margins
    default(size=(900, 600), dpi=300, framestyle=:box, legendfontsize=9)
    
    # Determine axes limits
    margin_x = (b - a) * 0.1
    x_range = range(a - margin_x, b + margin_x, length=400)
    y_values = f.(x_range)
    y_min, y_max = minimum(y_values), maximum(y_values)
    y_span = y_max - y_min
    y_padding = y_span * 0.2
    
    frames = []
    
    for i in 1:length(history)
        # Unpack FULL state
        a_i, b_i, x_i, w_i, v_i, fx_i, u_i, fu_i = history[i]
        
        # Calculate function values for w and v
        fw_i = f(w_i)
        fv_i = f(v_i)
        
        # 1. Main Plot Setup
        p = plot(x_range, f.(x_range), 
                linewidth=2.5, 
                color=:royalblue,   # Blue function line
                alpha=0.8,
                label=L"f(x)",
                # Title in Italics using LaTeX
                title=L"\textit{Brent's\ Method:\ Iteration\ %$i}",
                xlabel=L"x", 
                ylabel=L"f(x)",
                ylims=(y_min - y_padding, y_max + y_padding),
                xlims=(a - margin_x, b + margin_x),
                legend=:topright,
                # Margins to prevent label clipping
                left_margin=10mm, 
                right_margin=5mm,
                bottom_margin=5mm,
                top_margin=5mm) 
        
        # 2. Search Interval (Red Line)
        plot!([a_i, b_i], [y_min - y_padding/2, y_min - y_padding/2], 
              linewidth=4, color=:red, label="Interval [a,b]")
        
        # 3. Points v, w, x (Layered Bullseye Strategy)
        # Draw v (largest, back)
        scatter!([v_i], [fv_i], 
                markersize=14, color=:lightblue, markerstrokecolor=:blue,
                label=L"v\ (prev\ best)")
        
        # Draw w (medium, middle)
        scatter!([w_i], [fw_i], 
                markersize=10, color=:lightgreen, markerstrokecolor=:green,
                label=L"w\ (2nd\ best)")
        
        # Draw x (smallest, front)
        scatter!([x_i], [fx_i], 
                markersize=6, color=:red, markerstrokecolor=:black,
                label=L"x\ (best)")
                
        # 4. Trial point u (Gold Star)
        if !isnan(u_i)
             scatter!([u_i], [fu_i], 
                markersize=11, shape=:star5, color=:gold, markerstrokecolor=:black,
                label=L"u\ (trial)")
             
             # Drop line
             plot!([u_i, u_i], [y_min - y_padding/2, fu_i], 
                   linestyle=:dot, color=:gray, label="")
        end

        # Text Info (Interval Length)
        # Position: Top-Left but shifted slightly right to avoid border collision
        plot_width = (b + margin_x) - (a - margin_x)
        text_x_pos = (a - margin_x) + (plot_width * 0.02) # 2% offset from left edge
        
        annotate!(text_x_pos, y_max + y_padding*0.8, 
                 text(L"\textit{Interval\ length:\ %$(round(b_i - a_i, digits=6))}", :left, 10, :black))
        
        savefig(p, joinpath(frames_dir, "frame_$i.pdf"))
        push!(frames, p)
    end
    
    anim = Animation()
    for p in frames; frame(anim, p); end
    gif(anim, "$(filename).gif", fps=fps)
end

# --- RUN EXAMPLES ---
function run_all()
    println("Generating animations...")
    
    # 1. Asymmetric function 
    f2(x) = x * cos(x)
    visualize_brent(f2, 0.0, 5.0, 1e-4, filename="brent_full_asymmetric")
    println("- brent_full_asymmetric.gif created")
    
    # 2. Oscillating function
    f1(x) = 0.5*(x-2)^2 - 0.5*cos(4*x)
    visualize_brent(f1, 0.0, 5.0, 1e-4, filename="brent_full_oscillating")
    println("- brent_full_oscillating.gif created")
end

run_all()