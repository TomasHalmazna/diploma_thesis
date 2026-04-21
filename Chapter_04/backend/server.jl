# backend/server.jl
using Pkg
Pkg.activate(@__DIR__) # Activates the environment in the current directory (where this server.jl is located)
Pkg.instantiate()      # Checks the Manifest and downloads the exactly the same versions of packages


using Oxygen
using HTTP
using LinearAlgebra
using ForwardDiff

# 1. Loading core and mathematical functions
include("Core.jl")
include("TestFunctions.jl")

# 2. Loading optimizers
include(joinpath("Optimizers", "SteepestDescent.jl"))
include(joinpath("Optimizers", "ConjugateGradient.jl"))
include(joinpath("Optimizers", "NewtonMethod.jl"))
include(joinpath("Optimizers", "DFP.jl"))
include(joinpath("Optimizers", "BFGS.jl"))
include(joinpath("Optimizers", "LBFGS.jl"))

# 3. Loading line search methods
include(joinpath("LineSearch", "Backtracking.jl"))
include(joinpath("LineSearch", "Bracketing.jl"))
include(joinpath("LineSearch", "GoldenSectionSearch.jl"))
include(joinpath("LineSearch", "DichotomousSearch.jl")) 
include(joinpath("LineSearch", "QuadraticFitSearch.jl"))
include(joinpath("LineSearch", "BrentsMethod.jl")) 

function create_custom_function(func_str::String, x0::Vector{Float64})
    try
        decoded_str = HTTP.unescapeuri(func_str)
        clean_str = replace(decoded_str, "\\" => "")
        
        expr = Meta.parse(clean_str)
        f_raw = eval(:(x -> $expr))
        f = x -> Base.invokelatest(f_raw, x)
        
        ∇f = x -> ForwardDiff.gradient(f, x)
        Hf = x -> ForwardDiff.hessian(f, x)
        
        f(x0)
        ∇f(x0)
        
        return f, ∇f, Hf, nothing
    catch e
        return nothing, nothing, nothing, "Function Error: " * string(e)
    end
end

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

    f_obj = nothing
    if func_type == "custom"
        f_obj, _, _, _ = create_custom_function(formula, x0)
    elseif func_type == "himmelblau"
        f_obj = f_himmel
    elseif func_type == "sphere"
        f_obj = f_sphere
    else
        f_obj = f_rosen
    end

    if f_obj === nothing return Dict("error" => "invalid function") end

    RESOLUTION = 150
    x_grid = range(xmin, stop=xmax, length=RESOLUTION)
    y_grid = range(ymin, stop=ymax, length=RESOLUTION)
    
    # CRITICAL FIX: Using Array of Arrays instead of Matrix for proper JSON 2D serialization
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
            end
        end
    end

    return Dict(
        "contour_x" => collect(x_grid),
        "contour_y" => collect(y_grid),
        "contour_z" => z_grid
    )
end

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
    
    # NEW: Parsing Termination Criteria parameters
    term_criterion = get(query, "term_criterion", "gradient")
    tol = parse(Float64, get(query, "tol", "1e-4"))
    max_iter = parse(Int, get(query, "max_iter", "2000"))
    
    f_obj, ∇f_obj, Hf_obj = nothing, nothing, nothing
    if selected_function == "custom"
        f_obj, ∇f_obj, Hf_obj, err = create_custom_function(custom_formula, x0)
        if err !== nothing return Dict("status" => "error", "message" => err) end
    elseif selected_function == "himmelblau"
        f_obj, ∇f_obj, Hf_obj = f_himmel, ∇f_himmel, Hf_himmel
    elseif selected_function == "sphere"
        f_obj, ∇f_obj, Hf_obj = f_sphere, ∇f_sphere, Hf_sphere
    else
        f_obj, ∇f_obj, Hf_obj = f_rosen, ∇f_rosen, Hf_rosen
    end
    
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
        # PASSING NEW PARAMS TO THE CORE
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
        
        traj_x_min, traj_x_max = minimum(filter(x -> x !== nothing, x_hist)), maximum(filter(x -> x !== nothing, x_hist))
        traj_y_min, traj_y_max = minimum(filter(x -> x !== nothing, y_hist)), maximum(filter(x -> x !== nothing, y_hist))
        
        if selected_function == "rosenbrock"
            view_xmin, view_xmax, view_ymin, view_ymax = -2.0, 2.0, -1.0, 3.0
        elseif selected_function in ["himmelblau", "sphere"]
            view_xmin, view_xmax, view_ymin, view_ymax = -5.0, 5.0, -5.0, 5.0
        else
            view_xmin, view_xmax, view_ymin, view_ymax = traj_x_min - 2.0, traj_x_max + 2.0, traj_y_min - 2.0, traj_y_max + 2.0
        end

        plot_xmin, plot_xmax = min(view_xmin, traj_x_min), max(view_xmax, traj_x_max)
        plot_ymin, plot_ymax = min(view_ymin, traj_y_min), max(view_ymax, traj_y_max)
        
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
        error_string = string(e)
        if occursin("DomainError", error_string) || occursin("Math", error_string)
            return Dict("status" => "error", "message" => "Method left the domain (DomainError). Try different x0 or smaller steps.")
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