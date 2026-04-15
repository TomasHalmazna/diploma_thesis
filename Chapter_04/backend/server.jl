using Oxygen
using HTTP
using LinearAlgebra

# Include core optimization logic:
include("Core.jl")

# Include optimizers:
include(joinpath("Optimizers", "ConjugateGradient.jl"))
include(joinpath("Optimizers", "SteepestDescent.jl"))

# Include line search methods:
include(joinpath("LineSearch", "GoldenSectionSearch.jl"))
include(joinpath("LineSearch", "Backtracking.jl"))


# Definice Rosenbrockovy funkce a jejího gradientu
f_rosen(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
function ∇f_rosen(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end


# Define the API endpoint for optimization
@get "/optimize" function(req::HTTP.Request)
    query = queryparams(req)
    
    # 1. Parse optimizer options
    selected_method = get(query, "method", "sd")
    cg_variant_str = get(query, "cg_variant", "PR_plus")
    
    # 2. Parse line search options
    ls_type = get(query, "linesearch", "backtracking")
    auto_bracket = parse(Bool, get(query, "auto_bracket", "true"))
    bracket_a = parse(Float64, get(query, "bracket_a", "0.0"))
    bracket_b = parse(Float64, get(query, "bracket_b", "1.0"))
    
    println("Request: Method=$selected_method, LS=$ls_type, AutoBracket=$auto_bracket")
    
    x0 = [-1.0, 0.0]
    
    # --- Instantiate Optimizer ---
    if selected_method == "cg"
        variant_symbol = Symbol(cg_variant_str)
        method = ConjugateGradient(variant_symbol)
    else
        method = SteepestDescent()
    end
    
    # --- Instantiate Line Search ---
    if ls_type == "gss"
        linesearch = GoldenSectionSearch(
            auto_bracket=auto_bracket, 
            manual_interval=(bracket_a, bracket_b)
        )
    else
        linesearch = Backtracking()
    end
    
    # Run optimization
    history = run_optimization(f_rosen, ∇f_rosen, x0, method, linesearch; max_iter=2000, tol=1e-4)
    
    x_hist = [pt[1] for pt in history]
    y_hist = [pt[2] for pt in history]
    
    return Dict(
        "status" => "success",
        "iterations" => length(history) - 1,
        "x_hist" => x_hist,
        "y_hist" => y_hist
    )
end

function cors_middleware(handler)
    return function(req::HTTP.Request)
        if req.method == "OPTIONS"
            return HTTP.Response(200, [
                "Access-Control-Allow-Origin" => "*",
                "Access-Control-Allow-Headers" => "*",
                "Access-Control-Allow-Methods" => "*"
            ])
        end
        res = handler(req)
        HTTP.setheader(res, "Access-Control-Allow-Origin" => "*")
        return res
    end
end

println("Startuji server na http://127.0.0.1:8080 ...")
serve(port=8080, middleware=[cors_middleware])
