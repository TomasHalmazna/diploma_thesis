using Plots
using LaTeXStrings
using Measures
using LinearAlgebra # Needed for calculating parabola coefficients

include("brents_method.jl")

"""
    visualize_brent(f, a, b, ε; filename="brent_full", fps=1, title_text="")

Visualizes Brent's method including the fitting parabola (dashed line) whenever QFS is used.
"""
function visualize_brent(f, a, b, ε; filename="brent_full", fps=1, title_text="")
    x_min, f_min, iterations, history = brents_method(f, a, b, ε)
    
    frames_dir = "frames_$(filename)"
    if !isdir(frames_dir)
        mkdir(frames_dir)
    end
    
    default(size=(900, 600), dpi=300, framestyle=:box, legendfontsize=9)
    
    margin_x = (b - a) * 0.1
    x_range = range(a - margin_x, b + margin_x, length=400)
    y_values = f.(x_range)
    y_min, y_max = minimum(y_values), maximum(y_values)
    y_span = y_max - y_min
    y_padding = y_span * 0.2
    
    frames = []
    
    for i in 1:length(history)
        # Unpack including is_qfs flag
        a_i, b_i, x_i, w_i, v_i, fx_i, u_i, fu_i, is_qfs = history[i]
        
        fw_i = f(w_i)
        fv_i = f(v_i)
        
        # 1. Main Plot
        p = plot(x_range, f.(x_range), 
                linewidth=2.5, color=:royalblue, alpha=0.8,
                label=L"f(x)",
                title=L"\textit{Brent's\ Method:\ Iteration\ %$i}",
                xlabel=L"x", ylabel=L"f(x)",
                ylims=(y_min - y_padding, y_max + y_padding),
                xlims=(a - margin_x, b + margin_x),
                legend=:topright,
                left_margin=10mm, right_margin=5mm, bottom_margin=5mm, top_margin=5mm)
        
        # --- NEW: Plot Parabola if QFS was used ---
        if is_qfs
            # We need to find parabola P(t) = c1*t^2 + c2*t + c3 passing through x, w, v
            # Construct Vandermonde matrix
            X_mat = [x_i^2 x_i 1; w_i^2 w_i 1; v_i^2 v_i 1]
            Y_vec = [fx_i, fw_i, fv_i]
            
            # Check if points are distinct enough to avoid singular matrix
            # (Brent guarantees distinctness roughly, but safe check is good)
            if abs(det(X_mat)) > 1e-12
                coeffs = X_mat \ Y_vec
                parabola(t) = coeffs[1]*t^2 + coeffs[2]*t + coeffs[3]
                
                plot!(x_range, parabola.(x_range), 
                      linestyle=:dash, 
                      linewidth=1.5, 
                      color=:orange, 
                      alpha=0.8,
                      label=L"Parabolic\ Fit")
            end
        end
        # ------------------------------------------

        # 2. Interval
        plot!([a_i, b_i], [y_min - y_padding/2, y_min - y_padding/2], 
              linewidth=4, color=:red, label="Interval [a,b]")
        
        # 3. Points v, w, x (Bullseye)
        scatter!([v_i], [fv_i], markersize=14, color=:lightblue, markerstrokecolor=:blue, label=L"v")
        scatter!([w_i], [fw_i], markersize=10, color=:lightgreen, markerstrokecolor=:green, label=L"w")
        scatter!([x_i], [fx_i], markersize=6, color=:red, markerstrokecolor=:black, label=L"x")
                
        # 4. Trial point u
        if !isnan(u_i)
             scatter!([u_i], [fu_i], markersize=11, shape=:star5, color=:gold, markerstrokecolor=:black, label=L"u")
             plot!([u_i, u_i], [y_min - y_padding/2, fu_i], linestyle=:dot, color=:gray, label="")
        end

        # Text Info
        plot_width = (b + margin_x) - (a - margin_x)
        text_x_pos = (a - margin_x) + (plot_width * 0.02)
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
    # 1. Asymmetric (Nice parabola fit)
    f2(x) = x * cos(x)
    visualize_brent(f2, 0.0, 5.0, 1e-4, filename="brent_full_asymmetric")
    
    # 2. Oscillating (Shows switching between GSS and QFS)
    f1(x) = 0.5*(x-2)^2 - 0.5*cos(4*x)
    visualize_brent(f1, 0.0, 5.0, 1e-4, filename="brent_full_oscillating")
end

run_all()