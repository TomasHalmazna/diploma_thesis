using Oxygen
using HTTP
using LinearAlgebra

# Definice Rosenbrockovy funkce a jejího gradientu
f_rosen(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
function ∇f_rosen(x)
    g1 = -2.0 * (1.0 - x[1]) - 400.0 * x[1] * (x[2] - x[1]^2)
    g2 = 200.0 * (x[2] - x[1]^2)
    return [g1, g2]
end

@get "/optimize" function(req::HTTP.Request)
    # Startovní bod (zajímavější pro Rosenbrocka) a pevný malý krok
    x = [-1.0, 0.0]
    alpha = 0.001 
    
    # Historie pro vykreslení
    x_hist = [x[1]]
    y_hist = [x[2]]
    
    # Jednoduchý Steepest Descent
    for _ in 1:2000
        g = ∇f_rosen(x)
        if norm(g) < 1e-4
            break
        end
        x = x - alpha * g
        push!(x_hist, x[1])
        push!(y_hist, x[2])
    end
    
    return Dict(
        "status" => "success",
        "iterations" => length(x_hist) - 1,
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