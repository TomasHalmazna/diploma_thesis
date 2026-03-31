using LinearAlgebra
using Plots

function backtracking_search(f, ∇f, x, d, α; p=0.5, β=1e-4)
    y, g = f(x), ∇f(x)
    while f(x + α * d) > y + β * α * dot(g, d)
        α *= p
    end
    return α
end