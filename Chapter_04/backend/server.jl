# backend/server.jl
using Oxygen
using HTTP
using LinearAlgebra

# 1. Loading core and mathematical functions
include("Core.jl")
include("TestFunctions.jl") # NEW FUNCTIONS ARE LOADED HERE

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

@get "/optimize" function(req::HTTP.Request)
    query = queryparams(req)
    
    # Parsing basic parameters
    selected_function = get(query, "function", "rosenbrock")
    selected_method = get(query, "method", "sd")
    cg_variant_str = get(query, "cg_variant", "PR_plus")
    
    m_val = tryparse(Int, get(query, "m", "5"))
    if m_val === nothing || m_val < 1 m_val = 5 end
    
    ls_type = get(query, "linesearch", "backtracking")
    auto_bracket = parse(Bool, get(query, "auto_bracket", "true"))
    bracket_a = parse(Float64, get(query, "bracket_a", "0.0"))
    bracket_b = parse(Float64, get(query, "bracket_b", "1.0"))
    
    # Parsing x0 and axis dimensions for plotting
    x0_str = get(query, "x0", "-1.0,0.0")
    x0 = parse.(Float64, split(x0_str, ","))
    dim_x = parse(Int, get(query, "dim_x", "1"))
    dim_y = parse(Int, get(query, "dim_y", "2"))
    
    println("Request: Func=$selected_function, Method=$selected_method, x0=$x0")
    
    # --- Assigning functions from TestFunctions.jl ---
    if selected_function == "himmelblau"
        f_obj, ∇f_obj, Hf_obj = f_himmel, ∇f_himmel, Hf_himmel
    elseif selected_function == "sphere"
        f_obj, ∇f_obj, Hf_obj = f_sphere, ∇f_sphere, Hf_sphere
    else
        f_obj, ∇f_obj, Hf_obj = f_rosen, ∇f_rosen, Hf_rosen
    end
    
    # --- Optimizer instance ---
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
    
    # --- Line search instance ---
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
    
    # Running optimization
    history, div_info = run_optimization(f_obj, ∇f_obj, x0, method, linesearch; max_iter=2000, tol=1e-4)
    
    dim_x = clamp(dim_x, 1, length(x0))
    dim_y = clamp(dim_y, 1, length(x0))

    # Extract trajectory data
    f_hist_raw = [f_obj(pt) for pt in history]
    grad_norm_hist_raw = [norm(∇f_obj(pt)) for pt in history]

    # Clean data for JSON (handle NaN/Inf)
    clean_val(v) = (isnan(v) || isinf(v)) ? nothing : v

    x_hist = [clean_val(pt[dim_x]) for pt in history]
    y_hist = [clean_val(pt[dim_y]) for pt in history]
    f_hist = [clean_val(v) for v in f_hist_raw]
    grad_norm_hist = [clean_val(v) for v in grad_norm_hist_raw]
    
    # Build response with divergence information
    response = Dict(
        "status" => div_info.diverged ? "diverged" : "success",
        "iterations" => length(history) - 1,
        "x_hist" => x_hist,
        "y_hist" => y_hist,
        "f_hist" => f_hist,
        "grad_norm_hist" => grad_norm_hist,
        "diverged" => div_info.diverged,
        "divergence_reason" => div_info.reason,
        "divergence_iteration" => div_info.iteration,
        "final_grad_norm" => div_info.grad_norm,
        "final_f_value" => div_info.f_value
    )
    
    if div_info.diverged
        println("⚠️ Divergence detected: $(div_info.reason) at iteration $(div_info.iteration)")
    end
    
    return response
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