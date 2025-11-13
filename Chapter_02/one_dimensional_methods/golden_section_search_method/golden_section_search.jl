"""
golden_section_search(f, a, b; tol=1e-8, N=nothing)

One-dimensional minimization using the Golden-Section Search (GSS).

Arguments
- `f`: a scalar function `f(x)` to minimize on `[a,b]`.
- `a`, `b`: interval endpoints with `a < b`.

Keyword arguments
- `tol`: stopping tolerance on the interval length `b-a` (default `1e-8`).
- `N`: optional maximum number of function evaluations `N` (must be >= 2).

Returns a named tuple with fields
- `xmin`: estimated minimizer (midpoint of final interval),
- `fmin`: function value at `xmin` (evaluated if needed),
- `a`, `b`: final bracketing interval,
- `evaluations`: number of function evaluations performed.

The implementation follows the standard GSS pseudocode and re-uses
previously computed function values when advancing the interval.
"""
function golden_section_search(f, a::Float64, b::Float64; tol=1e-8, N=nothing)
	if !(a < b)
		throw(ArgumentError("Require a < b"))
	end

	τ = (1 + sqrt(5)) / 2.0
	# Interior points: x^- (left inside), x^+ (right inside)
    
	x_minus = a + (b - a) / τ^2   # corresponds to α = 1/τ^2
	x_plus  = a + (b - a) / τ     # corresponds to 1/τ

	# Evaluate function at the two interior points
	fx_minus = f(x_minus)
	fx_plus  = f(x_plus)
	evals = 2

	# If N provided, ensure at least 2
	if N !== nothing && N < 2
		throw(ArgumentError("N must be >= 2 when provided"))
	end

	# Main loop: stop when interval length <= tol or when we reach N
	while (b - a) > tol && (N === nothing || evals < N)
		if fx_minus >= fx_plus
			# Minimum lies in [x_minus, b]
			a = x_minus
			# Shift points: x_{k+1}^- := x_k^+
			x_minus = x_plus
			fx_minus = fx_plus  # reuse evaluation
			# New x_plus inside new interval
			x_plus = a + (b - a) / τ
			fx_plus = f(x_plus)
			evals += 1
		else
			# Minimum lies in [a, x_plus]
			b = x_plus
			# Shift points: x_{k+1}^+ := x_k^-
			x_plus = x_minus
			fx_plus = fx_minus  # reuse evaluation
			# New x_minus inside new interval
			x_minus = a + (b - a) / τ^2
			fx_minus = f(x_minus)
			evals += 1
		end
	end

	xmin = (a + b) / 2.0
	# Optionally compute f at xmin if we haven't yet
	fmin = f(xmin)
	evals += 1

	return (xmin = xmin, fmin = fmin, a = a, b = b, evaluations = evals)
end


# Example usage
function example()
	# Example function: f(x) = x² + 2x + 1
	f(x) = x^2 + 2x + 1

	# Parameters
	a, b = -5.0, 5.0  # Initial interval
	ε = 1e-4          # Tolerance for interval length

	# Run the algorithm (use `tol` keyword)
	res = golden_section_search(f, a, b; tol=ε)

	println("Results:")
	println("xmin = ", res.xmin)
	println("f(xmin) = ", res.fmin)
	println("Final interval length: ", res.b - res.a)
	println("Function evaluations: ", res.evaluations)
end

# Run the example
example()

