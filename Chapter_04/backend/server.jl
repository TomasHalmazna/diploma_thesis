# backend/server.jl
using Oxygen
using HTTP
using LinearAlgebra

include("Core.jl")

# include multidimensional optimizers
include(joinpath("Optimizers", "SteepestDescent.jl"))
include(joinpath("Optimizers", "ConjugateGradient.jl"))
include(joinpath("Optimizers", "NewtonMethod.jl"))
include(joinpath("Optimizers", "DFP.jl"))
include(joinpath("Optimizers", "BFGS.jl"))
include(joinpath("Optimizers", "LBFGS.jl"))

# include line search methods
include(joinpath("LineSearch", "Backtracking.jl"))
include(joinpath("LineSearch", "Bracketing.jl"))
include(joinpath("LineSearch", "GoldenSectionSearch.jl"))
include(joinpath("LineSearch", "DichotomousSearch.jl")) 
include(joinpath("LineSearch", "QuadraticFitSearch.jl"))
include(joinpath("LineSearch", "BrentsMethod.jl")) 

# --- ROSENBROCK FUNCTION DEFINITIONS ---
f_rosen(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2

function ∇f_rosen(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end

# Exact Hessian for the pure Newton's Method
function Hf_rosen(x)
    h11 = 2.0 - 400.0 * (x[2] - 3.0 * x[1]^2)
    h12 = -400.0 * x[1]
    h21 = -400.0 * x[1]
    h22 = 200.0
    return [h11 h12; h21 h22]
end

@get "/optimize" function(req::HTTP.Request)
    query = queryparams(req)
    
    selected_method = get(query, "method", "sd")
    cg_variant_str = get(query, "cg_variant", "PR_plus")
    ls_type = get(query, "linesearch", "backtracking")
    auto_bracket = parse(Bool, get(query, "auto_bracket", "true"))
    bracket_a = parse(Float64, get(query, "bracket_a", "0.0"))
    bracket_b = parse(Float64, get(query, "bracket_b", "1.0"))
    
    println("Request: Method=$selected_method, LS=$ls_type, AutoBracket=$auto_bracket")
    
    x0 = [-1.0, 0.0]
    
    # --- Instantiate Optimizer ---
    if selected_method == "cg"
        method = ConjugateGradient(Symbol(cg_variant_str))
    elseif selected_method == "newton"
        method = NewtonMethod(Hf_rosen)
    elseif selected_method == "dfp"
        method = DFPMethod()
    elseif selected_method == "bfgs"
        method = BFGSMethod()
    elseif selected_method == "lbfgs"
        method = LBFGSMethod() # Default: m=10
    else
        method = SteepestDescent()
    end
    
    # --- Instantiate Line Search ---
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
    
    history = run_optimization(f_rosen, ∇f_rosen, x0, method, linesearch; max_iter=2000, tol=1e-4)
    
    x_hist = [pt[1] for pt in history]
    y_hist = [pt[2] for pt in history]

    # Calculate function values and gradient norms for the charts
    f_hist = [f_rosen(pt) for pt in history]
    grad_norm_hist = [norm(∇f_rosen(pt)) for pt in history]
    
    return Dict(
        "status" => "success",
        "iterations" => length(history) - 1,
        "x_hist" => x_hist,
        "y_hist" => y_hist,
        "f_hist" => f_hist,
        "grad_norm_hist" => grad_norm_hist
    )
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