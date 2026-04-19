# backend/TestFunctions.jl

# --- 1. N-DIMENSIONAL ROSENBROCK FUNCTION ---
function f_rosen(x::Vector{Float64})
    sum = 0.0
    for i in 1:(length(x) - 1)
        sum += 100.0 * (x[i+1] - x[i]^2)^2 + (1.0 - x[i])^2
    end
    return sum
end

function ∇f_rosen(x::Vector{Float64})
    n = length(x)
    g = zeros(n)
    if n == 2
        g[1] = -400.0 * x[1] * (x[2] - x[1]^2) - 2.0 * (1.0 - x[1])
        g[2] = 200.0 * (x[2] - x[1]^2)
        return g
    end
    
    g[1] = -400.0 * x[1] * (x[2] - x[1]^2) - 2.0 * (1.0 - x[1])
    for i in 2:(n - 1)
        g[i] = 200.0 * (x[i] - x[i-1]^2) - 400.0 * x[i] * (x[i+1] - x[i]^2) - 2.0 * (1.0 - x[i])
    end
    g[n] = 200.0 * (x[n] - x[n-1]^2)
    return g
end

function Hf_rosen(x::Vector{Float64})
    n = length(x)
    H = zeros(n, n)
    if n == 2
        H[1, 1] = 2.0 - 400.0 * (x[2] - 3.0 * x[1]^2)
        H[1, 2] = -400.0 * x[1]
        H[2, 1] = -400.0 * x[1]
        H[2, 2] = 200.0
        return H
    end
    
    H[1, 1] = 2.0 - 400.0 * (x[2] - 3.0 * x[1]^2)
    H[1, 2] = -400.0 * x[1]
    for i in 2:(n - 1)
        H[i, i-1] = -400.0 * x[i-1]
        H[i, i]   = 202.0 - 400.0 * (x[i+1] - 3.0 * x[i]^2)
        H[i, i+1] = -400.0 * x[i]
    end
    H[n, n-1] = -400.0 * x[n-1]
    H[n, n]   = 200.0
    return H
end

# --- 2. 2D HIMMELBLAU FUNCTION ---
f_himmel(x::Vector{Float64}) = (x[1]^2 + x[2] - 11.0)^2 + (x[1] + x[2]^2 - 7.0)^2

function ∇f_himmel(x::Vector{Float64})
    g1 = 4.0 * x[1] * (x[1]^2 + x[2] - 11.0) + 2.0 * (x[1] + x[2]^2 - 7.0)
    g2 = 2.0 * (x[1]^2 + x[2] - 11.0) + 4.0 * x[2] * (x[1] + x[2]^2 - 7.0)
    return [g1, g2]
end

function Hf_himmel(x::Vector{Float64})
    h11 = 12.0 * x[1]^2 + 4.0 * x[2] - 42.0
    h12 = 4.0 * x[1] + 4.0 * x[2]
    h21 = 4.0 * x[1] + 4.0 * x[2]
    h22 = 12.0 * x[2]^2 + 4.0 * x[1] - 26.0
    return [h11 h12; h21 h22]
end

# --- 3. N-DIMENSIONAL ELLIPTICAL BOWL (Sphere variant) ---
function f_sphere(x::Vector{Float64})
    return sum(i * x[i]^2 for i in 1:length(x))
end

function ∇f_sphere(x::Vector{Float64})
    return [2.0 * i * x[i] for i in 1:length(x)]
end

function Hf_sphere(x::Vector{Float64})
    n = length(x)
    H = zeros(n, n)
    for i in 1:n
        H[i, i] = 2.0 * i
    end
    return H
end