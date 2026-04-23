# backend/TestFunctions.jl
using ForwardDiff

# --- 1. N-DIMENSIONAL ROSENBROCK FUNCTION ---
function f_rosen(x::AbstractVector)
    sum_val = 0.0
    for i in 1:(length(x) - 1)
        sum_val += 100.0 * (x[i+1] - x[i]^2)^2 + (1.0 - x[i])^2
    end
    return sum_val
end

function ∇f_rosen(x::AbstractVector)
    n = length(x)
    g = zeros(eltype(x), n)
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

function Hf_rosen(x::AbstractVector)
    n = length(x)
    H = zeros(eltype(x), n, n)
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
f_himmel(x::AbstractVector) = (x[1]^2 + x[2] - 11.0)^2 + (x[1] + x[2]^2 - 7.0)^2

function ∇f_himmel(x::AbstractVector)
    g1 = 4.0 * x[1] * (x[1]^2 + x[2] - 11.0) + 2.0 * (x[1] + x[2]^2 - 7.0)
    g2 = 2.0 * (x[1]^2 + x[2] - 11.0) + 4.0 * x[2] * (x[1] + x[2]^2 - 7.0)
    return [g1, g2]
end

function Hf_himmel(x::AbstractVector)
    h11 = 12.0 * x[1]^2 + 4.0 * x[2] - 42.0
    h12 = 4.0 * x[1] + 4.0 * x[2]
    h21 = 4.0 * x[1] + 4.0 * x[2]
    h22 = 12.0 * x[2]^2 + 4.0 * x[1] - 26.0
    return [h11 h12; h21 h22]
end

# --- 3. N-DIMENSIONAL ELLIPTICAL BOWL (Sphere variant) ---
function f_sphere(x::AbstractVector)
    return sum(i * x[i]^2 for i in 1:length(x))
end

function ∇f_sphere(x::AbstractVector)
    return [2.0 * i * x[i] for i in 1:length(x)]
end

function Hf_sphere(x::AbstractVector)
    n = length(x)
    H = zeros(eltype(x), n, n)
    for i in 1:n
        H[i, i] = 2.0 * i
    end
    return H
end


# ==========================================
# Using ForwardDiff for robust derivatives
# ==========================================

# --- 4. ACKLEY FUNCTION (N-D) ---
f_ackley(x::AbstractVector) = begin
    d = length(x)
    sum_sq = sum(xi^2 for xi in x)
    sum_cos = sum(cos(2π * xi) for xi in x)
    return -20.0 * exp(-0.2 * sqrt(sum_sq / d)) - exp(sum_cos / d) + 20.0 + exp(1.0)
end
∇f_ackley(x) = ForwardDiff.gradient(f_ackley, x)
Hf_ackley(x) = ForwardDiff.hessian(f_ackley, x)


# --- 5. BEALE FUNCTION (2D) ---
f_beale(x::AbstractVector) = (1.5 - x[1] + x[1]*x[2])^2 + (2.25 - x[1] + x[1]*x[2]^2)^2 + (2.625 - x[1] + x[1]*x[2]^3)^2
∇f_beale(x) = ForwardDiff.gradient(f_beale, x)
Hf_beale(x) = ForwardDiff.hessian(f_beale, x)


# --- 6. BOOTH FUNCTION (2D) ---
f_booth(x::AbstractVector) = (x[1] + 2.0*x[2] - 7.0)^2 + (2.0*x[1] + x[2] - 5.0)^2
∇f_booth(x) = ForwardDiff.gradient(f_booth, x)
Hf_booth(x) = ForwardDiff.hessian(f_booth, x)


# --- 7. GOLDSTEIN-PRICE FUNCTION (2D) ---
f_goldstein_price(x::AbstractVector) = begin
    x1, x2 = x[1], x[2]
    term1 = 1.0 + (x1 + x2 + 1.0)^2 * (19.0 - 14.0*x1 + 3.0*x1^2 - 14.0*x2 + 6.0*x1*x2 + 3.0*x2^2)
    term2 = 30.0 + (2.0*x1 - 3.0*x2)^2 * (18.0 - 32.0*x1 + 12.0*x1^2 + 48.0*x2 - 36.0*x1*x2 + 27.0*x2^2)
    return term1 * term2
end
∇f_goldstein_price(x) = ForwardDiff.gradient(f_goldstein_price, x)
Hf_goldstein_price(x) = ForwardDiff.hessian(f_goldstein_price, x)


# --- 8. MATYAS FUNCTION (2D) ---
f_matyas(x::AbstractVector) = 0.26*(x[1]^2 + x[2]^2) - 0.48*x[1]*x[2]
∇f_matyas(x) = ForwardDiff.gradient(f_matyas, x)
Hf_matyas(x) = ForwardDiff.hessian(f_matyas, x)


# --- 9. LÉVI FUNCTION N.13 (2D) ---
f_levi_n13(x::AbstractVector) = begin
    x1, x2 = x[1], x[2]
    return sin(3π*x1)^2 + (x1 - 1.0)^2 * (1.0 + sin(3π*x2)^2) + (x2 - 1.0)^2 * (1.0 + sin(2π*x2)^2)
end
∇f_levi_n13(x) = ForwardDiff.gradient(f_levi_n13, x)
Hf_levi_n13(x) = ForwardDiff.hessian(f_levi_n13, x)


# --- 10. THREE-HUMP CAMEL FUNCTION (2D) ---
f_three_hump_camel(x::AbstractVector) = 2.0*x[1]^2 - 1.05*x[1]^4 + (x[1]^6)/6.0 + x[1]*x[2] + x[2]^2
∇f_three_hump_camel(x) = ForwardDiff.gradient(f_three_hump_camel, x)
Hf_three_hump_camel(x) = ForwardDiff.hessian(f_three_hump_camel, x)