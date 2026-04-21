# backend/server.jl
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

# Helper function to create a custom user-defined function and its derivatives
# takes x0 as an argument to check if the function is defined at the starting point
function create_custom_function(func_str::String, x0::Vector{Float64})
    try
        decoded_str = HTTP.unescapeuri(func_str)
        clean_str = replace(decoded_str, "\\" => "")
        
        println("[DEBUG] Received raw: $func_str")
        println("[DEBUG] After cleanup: $clean_str")

        expr = Meta.parse(clean_str)
        f_raw = eval(:(x -> $expr))
        f = x -> Base.invokelatest(f_raw, x)
        
        ∇f = x -> ForwardDiff.gradient(f, x)
        Hf = x -> ForwardDiff.hessian(f, x)
        
        # Test call using the ACTUAL starting point x0
        test_result = f(x0)
        ∇f(x0)
        
        if isnan(test_result) || isinf(test_result)
            return nothing, nothing, nothing, "Function evaluates to NaN or Inf at x0"
        end
        
        return f, ∇f, Hf, nothing
    catch e
        error_msg = "Error in custom function (check syntax or domain at x0): " * string(e)
        println("[ERROR] $error_msg")
        return nothing, nothing, nothing, error_msg
    end
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
    
    println("Request: Func=$selected_function, Method=$selected_method, x0=$x0")
    
    f_obj, ∇f_obj, Hf_obj = nothing, nothing, nothing
    
    if selected_function == "custom"
        # x0 to check if the function is defined at the starting point and to provide better error messages
        f_obj, ∇f_obj, Hf_obj, err = create_custom_function(custom_formula, x0)
        if err !== nothing
            return Dict("status" => "error", "message" => err)
        end
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
        history, alpha_hist, div_info = run_optimization(f_obj, ∇f_obj, x0, method, linesearch; max_iter=2000, tol=1e-4)
        
        dim_x = clamp(dim_x, 1, length(x0))
        dim_y = clamp(dim_y, 1, length(x0))

        clean_val(v) = (isnan(v) || isinf(v)) ? nothing : v

        # Extract 2D slice for plotting
        x_hist = [clean_val(pt[dim_x]) for pt in history]
        y_hist = [clean_val(pt[dim_y]) for pt in history]
        
        # Extract full N-dimensional history for tooltips
        full_x_hist = [[clean_val(v) for v in pt] for pt in history]
        
        f_hist = [clean_val(f_obj(pt)) for pt in history]
        grad_norm_hist = [clean_val(norm(∇f_obj(pt))) for pt in history]
        alpha_hist_clean = [clean_val(v) for v in alpha_hist]
        
        # --- Generating a dynamic contour grid ---
        x_min, x_max = minimum(filter(x -> x !== nothing, x_hist)), maximum(filter(x -> x !== nothing, x_hist))
        y_min, y_max = minimum(filter(x -> x !== nothing, y_hist)), maximum(filter(x -> x !== nothing, y_hist))
        
        # Protection against single-point trajectory
        if x_min == x_max; x_min -= 1.0; x_max += 1.0; end
        if y_min == y_max; y_min -= 1.0; y_max += 1.0; end
        
        # Zoom out a bit to ensure we capture the landscape around the trajectory
        pad_x = max(2.0, (x_max - x_min) * 1.5)
        pad_y = max(2.0, (y_max - y_min) * 1.5)
        
        # Limit the resolution to prevent excessive computation for very large ranges
        RESOLUTION = 150
        x_grid = range(x_min - pad_x, stop=x_max + pad_x, length=RESOLUTION)
        y_grid = range(y_min - pad_y, stop=y_max + pad_y, length=RESOLUTION)
        z_grid = Matrix{Union{Float64, Nothing}}(nothing, RESOLUTION, RESOLUTION)
        
        base_x = copy(x0)
        for (j, yv) in enumerate(y_grid)
            for (i, xv) in enumerate(x_grid)
                temp_x = copy(base_x)
                temp_x[dim_x] = xv
                temp_x[dim_y] = yv
                try
                    val = f_obj(temp_x)
                    if !isnan(val) && !isinf(val)
                        z_grid[j, i] = val
                    end
                catch
                    # Out of domain -> leave as nothing (JSON null)
                end
            end
        end

        return Dict(
            "status" => div_info.diverged ? "diverged" : "success",
            "iterations" => length(history) - 1,
            "x_hist" => x_hist,
            "y_hist" => y_hist,
            "full_x_hist" => full_x_hist, # NEW: Transmitting full N-dim history
            "f_hist" => f_hist,
            "grad_norm_hist" => grad_norm_hist,
            "alpha_hist" => alpha_hist_clean,
            "diverged" => div_info.diverged,
            "divergence_reason" => div_info.reason,
            "divergence_iteration" => div_info.iteration,
            "final_grad_norm" => div_info.grad_norm,
            "final_f_value" => div_info.f_value,
            "contour_x" => collect(x_grid),
            "contour_y" => collect(y_grid),
            "contour_z" => z_grid
        )
    catch e
        # Domain errors or math errors (like log of negative number) are common when the optimization goes out of bounds.
        # We catch them and provide a user-friendly message.
        error_string = string(e)
        if occursin("DomainError", error_string) || occursin("Math", error_string)
            return Dict("status" => "error", "message" => "The method left the function's domain (DomainError). Unconstrained optimization algorithms do not know the boundaries of functions (such as logarithm or square root). Try a different starting point or a smaller step (e.g., a more precise line search).")
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