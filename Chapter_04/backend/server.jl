# backend/server.jl

# initialize the package environment and load dependencies
using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Oxygen
using HTTP
using LinearAlgebra
using ForwardDiff
using Optim

# 1. Load core and mathematical functions
include("Core.jl")
include("TestFunctions.jl")

# 2. Load optimizers
include(joinpath("Optimizers", "SteepestDescent.jl"))
include(joinpath("Optimizers", "ConjugateGradient.jl"))
include(joinpath("Optimizers", "NewtonMethod.jl"))
include(joinpath("Optimizers", "DFP.jl"))
include(joinpath("Optimizers", "BFGS.jl"))
include(joinpath("Optimizers", "LBFGS.jl"))

# 3. Load line search methods
include(joinpath("LineSearch", "Backtracking.jl"))
include(joinpath("LineSearch", "Bracketing.jl"))
include(joinpath("LineSearch", "GoldenSectionSearch.jl"))
include(joinpath("LineSearch", "DichotomousSearch.jl")) 
include(joinpath("LineSearch", "QuadraticFitSearch.jl"))
include(joinpath("LineSearch", "BrentsMethod.jl")) 

# Helper function to create a custom user-defined function and its derivatives.
# Takes x0 as an argument to verify if the function is defined at the starting point.
function create_custom_function(func_str::String, x0::Vector{Float64})
    try
        decoded_str = HTTP.unescapeuri(func_str)
        clean_str = replace(decoded_str, "\\" => "")
        
        expr = Meta.parse(clean_str)
        f_raw = eval(:(x -> $expr))
        
        # Enforce type stability so Optim.jl does not crash on "Any" return types
        f = x -> convert(eltype(x), Base.invokelatest(f_raw, x))
        
        ∇f = x -> ForwardDiff.gradient(f, x)
        Hf = x -> ForwardDiff.hessian(f, x)
        
        # Test if function and gradient are computable at the initial point
        f(x0)
        ∇f(x0)
        
        return f, ∇f, Hf, nothing
    catch e
        return nothing, nothing, nothing, "Function Error: " * string(e)
    end
end

# Maps the string identifier from the frontend to the actual Julia functions
function get_function_objects(selected_function, custom_formula, x0)
    if selected_function == "custom"
        return create_custom_function(custom_formula, x0)
    elseif selected_function == "ackley"
        return f_ackley, ∇f_ackley, Hf_ackley, nothing
    elseif selected_function == "beale"
        return f_beale, ∇f_beale, Hf_beale, nothing
    elseif selected_function == "booth"
        return f_booth, ∇f_booth, Hf_booth, nothing
    elseif selected_function == "goldstein_price"
        return f_goldstein_price, ∇f_goldstein_price, Hf_goldstein_price, nothing
    elseif selected_function == "matyas"
        return f_matyas, ∇f_matyas, Hf_matyas, nothing
    elseif selected_function == "levi_n13"
        return f_levi_n13, ∇f_levi_n13, Hf_levi_n13, nothing
    elseif selected_function == "three_hump_camel"
        return f_three_hump_camel, ∇f_three_hump_camel, Hf_three_hump_camel, nothing
    elseif selected_function == "himmelblau"
        return f_himmel, ∇f_himmel, Hf_himmel, nothing
    elseif selected_function == "sphere"
        return f_sphere, ∇f_sphere, Hf_sphere, nothing
    else
        return f_rosen, ∇f_rosen, Hf_rosen, nothing
    end
end

# Provides reasonable initial bounding boxes for the 2D contour plot
function get_default_bounds(selected_function, traj_x_min, traj_x_max, traj_y_min, traj_y_max)
    if selected_function == "rosenbrock"
        return -2.0, 2.0, -1.0, 3.0
    elseif selected_function == "beale"
        return -4.5, 4.5, -4.5, 4.5
    elseif selected_function in ["booth", "matyas", "levi_n13"]
        return -10.0, 10.0, -10.0, 10.0
    elseif selected_function == "goldstein_price"
        return -2.0, 2.0, -2.0, 2.0
    elseif selected_function in ["himmelblau", "sphere", "ackley", "three_hump_camel"]
        return -5.0, 5.0, -5.0, 5.0
    else
        # Dynamic fallback based on the actual trajectory
        return traj_x_min - 2.0, traj_x_max + 2.0, traj_y_min - 2.0, traj_y_max + 2.0
    end
end

# ENDPOINT: Generates Z-values for the contour map based on the current frontend view
@get "/contours" function(req::HTTP.Request)
    query = queryparams(req)
    func_type = get(query, "function", "rosenbrock")
    formula = get(query, "custom_formula", "")
    
    xmin = parse(Float64, get(query, "xmin", "-5"))
    xmax = parse(Float64, get(query, "xmax", "5"))
    ymin = parse(Float64, get(query, "ymin", "-5"))
    ymax = parse(Float64, get(query, "ymax", "5"))
    
    dx = parse(Int, get(query, "dim_x", "1"))
    dy = parse(Int, get(query, "dim_y", "2"))
    x0 = parse.(Float64, split(get(query, "x0", "0,0"), ","))

    f_obj, _, _, err = get_function_objects(func_type, formula, x0)
    if err !== nothing || f_obj === nothing 
        return Dict("error" => "invalid function") 
    end

    RESOLUTION = 150
    x_grid = range(xmin, stop=xmax, length=RESOLUTION)
    y_grid = range(ymin, stop=ymax, length=RESOLUTION)
    
    # Initialize array of arrays for robust JSON serialization
    z_grid = Vector{Vector{Union{Float64, Nothing}}}(undef, RESOLUTION)
    for j in 1:RESOLUTION
        z_grid[j] = Vector{Union{Float64, Nothing}}(undef, RESOLUTION)
        fill!(z_grid[j], nothing)
    end
    
    base_x = copy(x0)
    for (j, yv) in enumerate(y_grid)
        for (i, xv) in enumerate(x_grid)
            temp_x = copy(base_x)
            temp_x[dx] = xv
            temp_x[dy] = yv
            try
                val = f_obj(temp_x)
                if !isnan(val) && !isinf(val)
                    z_grid[j][i] = val
                end
            catch
                # Silently ignore domain errors during grid generation
            end
        end
    end

    return Dict("contour_x" => collect(x_grid), "contour_y" => collect(y_grid), "contour_z" => z_grid)
end

# ENDPOINT: Runs the optimization algorithm and returns the trajectory and metrics
@get "/optimize" function(req::HTTP.Request)
    query = queryparams(req)
    
    selected_function = get(query, "function", "rosenbrock")
    custom_formula = get(query, "custom_formula", "")
    selected_method = get(query, "method", "sd")
    cg_variant_str = get(query, "cg_variant", "PR_plus")
    
    m_val = tryparse(Int, get(query, "m", "5"))
    m_val = (m_val === nothing || m_val < 1) ? 5 : m_val
    
    ls_type = get(query, "linesearch", "backtracking")
    auto_bracket = parse(Bool, get(query, "auto_bracket", "true"))
    bracket_a = parse(Float64, get(query, "bracket_a", "0.0"))
    bracket_b = parse(Float64, get(query, "bracket_b", "1.0"))
    
    x0_str = get(query, "x0", "-1.0,0.0")
    x0 = parse.(Float64, split(x0_str, ","))
    dim_x = parse(Int, get(query, "dim_x", "1"))
    dim_y = parse(Int, get(query, "dim_y", "2"))
    
    term_criterion = get(query, "term_criterion", "gradient")
    tol = parse(Float64, get(query, "tol", "1e-4"))
    max_iter = parse(Int, get(query, "max_iter", "2000"))
    
    f_obj, ∇f_obj, Hf_obj, err = get_function_objects(selected_function, custom_formula, x0)
    if err !== nothing 
        return Dict("status" => "error", "message" => err) 
    end
    
    # Optimizer selection
    if selected_method == "cg"
        method = ConjugateGradient(Symbol(cg_variant_str))
    elseif selected_method == "newton"
        method = NewtonMethod(Hf_obj)
    elseif selected_method == "dfp"
        method = DFPMethod()
    elseif selected_method == "bfgs"
        method = BFGSMethod()
    elseif selected_method == "lbfgs"
        method = LBFGSMethod(m_val)
    else
        method = SteepestDescent()
    end
    
    # Line search selection
    if ls_type == "gss"
        linesearch = GoldenSectionSearch(auto_bracket=auto_bracket, manual_interval=(bracket_a, bracket_b))
    elseif ls_type == "dichotomous"
        linesearch = DichotomousSearch(auto_bracket=auto_bracket, manual_interval=(bracket_a, bracket_b))
    elseif ls_type == "quadratic"
        linesearch = QuadraticFitSearch(auto_bracket=auto_bracket, manual_interval=(bracket_a, bracket_b))
    elseif ls_type == "brent"
        linesearch = BrentsMethod(auto_bracket=auto_bracket, manual_interval=(bracket_a, bracket_b))
    else
        linesearch = Backtracking()
    end
    
    try
        # Run the core algorithm
        history, alpha_hist, div_info = run_optimization(f_obj, ∇f_obj, x0, method, linesearch; 
                                                         max_iter=max_iter, term_criterion=term_criterion, tol=tol)
        
        dim_x = clamp(dim_x, 1, length(x0))
        dim_y = clamp(dim_y, 1, length(x0))

        clean_val(v) = (isnan(v) || isinf(v)) ? nothing : v

        x_hist = [clean_val(pt[dim_x]) for pt in history]
        y_hist = [clean_val(pt[dim_y]) for pt in history]
        full_x_hist = [[clean_val(v) for v in pt] for pt in history]
        f_hist = [clean_val(f_obj(pt)) for pt in history]
        grad_norm_hist = [clean_val(norm(∇f_obj(pt))) for pt in history]
        alpha_hist_clean = [clean_val(v) for v in alpha_hist]
        
        # Step distance calculation ||x_{k+1} - x_k||
        step_distances = Float64[]
        for i in 1:(length(history)-1)
            push!(step_distances, clean_val(norm(history[i+1] - history[i])))
        end

        # Calculate Ground Truth using Optim.jl
        true_min_f = nothing
        true_min_full = nothing
        try
            # First attempt: Fast gradient method L-BFGS
            g! = (G, x) -> begin G .= ∇f_obj(x) end
            od = Optim.OnceDifferentiable(f_obj, g!, copy(x0))
            opt_res = Optim.optimize(od, copy(x0), Optim.LBFGS())
            res_min = Optim.minimizer(opt_res)
            
            true_min_full = [clean_val(v) for v in res_min]
            true_min_f = clean_val(f_obj(res_min))
        catch e
            println("L-BFGS failed (likely singularity/non-differentiable minimum). Trying Nelder-Mead...")
            try
                # Second attempt: Nelder-Mead, which does not rely on gradients and can handle non-smooth functions
                opt_res_nm = Optim.optimize(f_obj, copy(x0), Optim.NelderMead())
                res_min_nm = Optim.minimizer(opt_res_nm)
                
                true_min_full = [clean_val(v) for v in res_min_nm]
                true_min_f = clean_val(f_obj(res_min_nm))
            catch e2
                println("Ground truth optimization entirely failed: ", e2)
            end
        end

        traj_x_min, traj_x_max = minimum(filter(x -> x !== nothing, x_hist)), maximum(filter(x -> x !== nothing, x_hist))
        traj_y_min, traj_y_max = minimum(filter(x -> x !== nothing, y_hist)), maximum(filter(x -> x !== nothing, y_hist))
        
        # Calculate bounding box for the UI map
        view_xmin, view_xmax, view_ymin, view_ymax = get_default_bounds(selected_function, traj_x_min, traj_x_max, traj_y_min, traj_y_max)
        plot_xmin, plot_xmax = min(view_xmin, traj_x_min), max(view_xmax, traj_x_max)
        plot_ymin, plot_ymax = min(view_ymin, traj_y_min), max(view_ymax, traj_y_max)
        
        # Add padding
        pad_x = (plot_xmax - plot_xmin) * 0.1
        pad_y = (plot_ymax - plot_ymin) * 0.1
        plot_xmin -= pad_x
        plot_xmax += pad_x
        plot_ymin -= pad_y
        plot_ymax += pad_y
        
        RESOLUTION = 150
        x_grid = range(plot_xmin, stop=plot_xmax, length=RESOLUTION)
        y_grid = range(plot_ymin, stop=plot_ymax, length=RESOLUTION)
        
        z_grid = Vector{Vector{Union{Float64, Nothing}}}(undef, RESOLUTION)
        for j in 1:RESOLUTION
            z_grid[j] = Vector{Union{Float64, Nothing}}(undef, RESOLUTION)
            fill!(z_grid[j], nothing)
        end
        
        # Generate contour background for the path
        base_x = copy(x0)
        for (j, yv) in enumerate(y_grid)
            for (i, xv) in enumerate(x_grid)
                temp_x = copy(base_x)
                temp_x[dim_x] = xv
                temp_x[dim_y] = yv
                try
                    val = f_obj(temp_x)
                    if !isnan(val) && !isinf(val)
                        z_grid[j][i] = val
                    end
                catch; end
            end
        end

        return Dict(
            "status" => div_info.diverged ? "diverged" : "success",
            "iterations" => length(history) - 1,
            "x_hist" => x_hist,
            "y_hist" => y_hist,
            "full_x_hist" => full_x_hist,
            "f_hist" => f_hist,
            "grad_norm_hist" => grad_norm_hist,
            "alpha_hist" => alpha_hist_clean,
            "step_dist_hist" => step_distances,
            "true_min_f" => true_min_f,
            "true_min_full" => true_min_full,
            "diverged" => div_info.diverged,
            "divergence_reason" => div_info.reason,
            "divergence_iteration" => div_info.iteration,
            "final_grad_norm" => clean_val(div_info.grad_norm),
            "final_f_value" => clean_val(div_info.f_value),
            "contour_x" => collect(x_grid),
            "contour_y" => collect(y_grid),
            "contour_z" => z_grid
        )
    catch e
        # Domain errors or math errors (like log of negative number) are common when the optimization goes out of bounds.
        # We catch them and provide a user-friendly message.
        error_string = string(e)
        if occursin("DomainError", error_string) || occursin("Math", error_string)
            return Dict("status" => "error", "message" => "The method left the function's domain (DomainError). Unconstrained optimization algorithms do not know the boundaries of functions (such as logarithm or square root). Try a different starting point or a smaller step.")
        else
            return Dict("status" => "error", "message" => "Runtime error: " * error_string)
        end
    end
end

function cors_middleware(handler)
    return function(req::HTTP.Request)
        if req.method == "OPTIONS"
            return HTTP.Response(200, ["Access-Control-Allow-Origin" => "*", "Access-Control-Allow-Headers" => "*", "Access-Control-Allow-Methods" => "*"])
        end
        res = handler(req)
        HTTP.setheader(res, "Access-Control-Allow-Origin" => "*")
        return res
    end
end

println("Starting server at http://127.0.0.1:8080 ...")
serve(port=8080, middleware=[cors_middleware])