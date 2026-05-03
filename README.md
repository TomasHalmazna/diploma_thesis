# Diploma Thesis: Numerical Optimization Algorithms

## Overview

This repository contains a comprehensive master's thesis on numerical optimization algorithms, spanning from foundational concepts to advanced methods and practical implementations. The project includes theoretical analysis, educational notebooks, algorithm implementations in Julia, and an interactive web-based visualization platform.

## Repository Structure

### Chapter 01: Fundamentals of Optimization

**Contents:** Local minimum and optimization foundations

- `local_minimum.ipynb` - Foundational concepts in optimization theory

### Chapter 02: Univariate Optimization

**Contents:** One-dimensional optimization methods and numerical differentiation

**Key Topics:**
- Numerical differentiation techniques
- Unimodal function optimization
- One-dimensional line search methods

**Implementations:**

- **Golden Section Search** (`golden_section_search_method/`)
  - `golden_section_search.jl` - Core implementation of the golden section search algorithm
  - `test_gss.jl` - Unit tests and validation
  - `visualize_gss.jl` - Algorithm visualization with frame generation
  - Ratio illustration and visualization frames

- **Dichotomous Search** (`dichotomous_search_method/`)
  - `dichotomous_search_method.jl` - Implementation of dichotomous (bisection) search
  - `visualize_dichotomous_search.jl` - Step-by-step visualization
  - Test suite and frame generation

- **Brent's Method** (`brents_method/`)
  - `brents_method.jl` - Robust root-finding algorithm combining bisection, secant, and inverse quadratic interpolation
  - `visualize_brents_method.jl` - Comprehensive visualization framework
  - Edge case demonstrations and initialization configuration
  - Multiple frame sequences for asymmetric, concave, and oscillating function behaviors

- **Quadratic Fit Search** (`quadratic_fit_search/`)
  - `qfs_example_frames/` - Visualization of quadratic approximation
  - Edge case analysis and stress testing

### Chapter 03: Multivariate Optimization

**Contents:** Advanced optimization algorithms for multivariate functions

**Gradient-Based Methods:**

- **Steepest Descent** (`steepest_descent/`)
  - `steepest_descent.jl` - Classical first-order method
  - `steepest_descent_rosenbrock_example.jl` - Demonstration on Rosenbrock function

- **Newton's Method** (`newton_method/`)
  - `damped_newton_example.jl` - Damped Newton approach for improved stability
  - `newton_divergence_example.jl` - Analysis of convergence failures

- **Quasi-Newton Methods** (`quasi_newton/`)
  - `bfgs.jl` / `bfgs_example.jl` - Broyden-Fletcher-Goldfarb-Shanno method
  - `dfp.jl` / `dfp_example.jl` - Davidon-Fletcher-Powell method
  - `lbfgs.jl` / `lbfgs_example.jl` - Limited-memory BFGS for high-dimensional problems

- **Conjugate Gradient** (`conjugate_gradient/`)
  - `conjugate_gradient.jl` - CG method implementation
  - `rosenbrock_cg_example.jl` - CG applied to Rosenbrock function
  - `rosenbrock_pr_beta_analysis.jl` - Polak-Ribiière beta parameter analysis
  - `rosenbrock_pr_bracketing.jl` - Bracketing strategy in CG

**Line Search Methods** (`step_size/`)

- `backtracking.jl` - Backtracking line search
- `ArmijoConditions.jl` - Armijo sufficient decrease condition
- `curvature_condition.jl` - Strong Wolfe curvature condition
- `strong_curvature_condition.jl` - Strong curvature condition implementation
- `step_size_decay_diff.jl` - Comparative analysis of step size decay strategies
- `OptimizationSkelet.jl` - Generic optimization framework
- `backtracking_example.jl` - Practical backtracking demonstration

**Test Functions** (`Examples_Graphs/`)

- Rosenbrock function analysis
- Himmelblau function demonstrations
- Quasi-Newton vs. line search comparisons
- Quasi-Newton vs. Rosenbrock function analysis

### Chapter 04: Interactive Optimization Visualizer

**Contents:** Full-stack web application for algorithm visualization and experimentation

**Technology Stack:**
- **Backend:** Julia with HTTP server
- **Frontend:** HTML5/CSS3/JavaScript
- **Containerization:** Docker support

**Backend Components** (`backend/`)

- `server.jl` - HTTP server and API endpoints
- `Core.jl` - Core optimization framework
- `TestFunctions.jl` - Repository of test functions (Rosenbrock, Himmelblau, etc.)

**Line Search Implementations:**
- `LineSearch/Backtracking.jl` - Backtracking line search
- `LineSearch/Bracketing.jl` - Bracketing phase implementation
- `LineSearch/BrentsMethod.jl` - Brent's method for 1D optimization
- `LineSearch/DichotomousSearch.jl` - Dichotomous search
- `LineSearch/GoldenSectionSearch.jl` - Golden section search
- `LineSearch/QuadraticFitSearch.jl` - Quadratic fit interpolation

**Optimizer Implementations:**
- `Optimizers/SteepestDescent.jl`
- `Optimizers/NewtonMethod.jl`
- `Optimizers/ConjugateGradient.jl`
- `Optimizers/BFGS.jl`
- `Optimizers/DFP.jl`
- `Optimizers/LBFGS.jl`

**Frontend Components** (`frontend/`)

- `index.html` - Main application interface
- `app.js` - Interactive visualizer logic
  - Algorithm selection and parameter configuration
  - Real-time optimization trajectory visualization
  - 2D contour plot rendering
  - Convergence metrics monitoring
  - Comparison with reference solutions
- `style.css` - Application styling

**Features:**

- Interactive selection of 10+ test functions or custom function input
- 6 multivariate optimization methods with variants
- 5 line search strategies with configurable parameters
- 2D contour plot visualization of optimization trajectories
- Real-time convergence monitoring (function value, gradient norm, step size, distance)
- Comparison against reference optimization results
- Parameter sweep and sensitivity analysis capabilities

## Technical Details

### Algorithms Covered

**One-Dimensional Optimization:**
- Golden Section Search
- Dichotomous Search
- Brent's Method
- Quadratic Fit Search

**Line Search Methods:**
- Backtracking with Armijo condition
- Bracketing phase (to establish bounded interval)
- Strong Wolfe curvature condition
- Step size decay strategies

**Multivariate Optimization:**
- Steepest Descent (Gradient Descent)
- Newton's Method (second-order, with damping)
- Conjugate Gradient (Fletcher-Reeves, Polak-Ribiière)
- BFGS (Broyden-Fletcher-Goldfarb-Shanno)
- DFP (Davidon-Fletcher-Powell)
- L-BFGS (Limited-memory BFGS)

### Test Functions

The implementation includes standard benchmark functions used in optimization literature:
- Rosenbrock function
- Himmelblau function
- Additional multi-dimensional test cases

## File Organization

```
diploma_thesis/
├── Chapter_01/              # Optimization Fundamentals
│   └── local_minimum.ipynb
├── Chapter_02/              # One-Dimensional Optimization
│   ├── numerical_differentiation.jl
│   ├── unimodal_univariate.ipynb
│   └── one_dimensional_methods/
│       ├── golden_section_search_method/
│       ├── dichotomous_search_method/
│       ├── brents_method/
│       └── quadratic_fit_search/
├── Chapter_03/              # Multivariate Optimization
│   ├── steepest_descent/
│   ├── newton_method/
│   ├── quasi_newton/
│   ├── conjugate_gradient/
│   └── step_size/
├── Chapter_04/              # Interactive Visualizer Application
│   ├── backend/             # Julia HTTP server & algorithms
│   ├── frontend/            # HTML/CSS/JavaScript interface
│   └── DOCUMENTATION.md     # Detailed API documentation
├── Examples_Graphs/         # Comparative analysis results
└── README.md                # This file
```

## Usage

### Educational Content

Navigate to the respective chapter directories to explore:
- Jupyter notebooks for conceptual understanding
- Julia implementations for algorithm details
- Visualization scripts for step-by-step algorithm execution

### Interactive Visualizer

1. **Setup Backend:**
   ```julia
   cd Chapter_04/backend
   julia server.jl
   ```

2. **Access Frontend:**
   - Open `Chapter_04/frontend/index.html` in a web browser
   - Or use the Docker container for deployment

3. **Experimentation:**
   - Select optimization method and line search strategy
   - Configure algorithm parameters
   - Visualize convergence behavior on test functions
   - Compare different algorithmic approaches

## Docker Support

The backend includes Docker containerization for deployment:
- `Dockerfile` - Container configuration
- `Project.toml` / `Manifest.toml` - Julia dependency management

## Documentation

- `Chapter_04/DOCUMENTATION.md` - Comprehensive API reference and architecture details
- Inline code comments throughout implementations

## Dependencies

### Julia Packages

- Optim.jl - Reference optimization library for validation
- HTTP.jl - Web server functionality
- Additional standard Julia libraries (Statistics, LinearAlgebra, etc.)

### Frontend

- KaTeX (for mathematical notation rendering)
- Standard HTML5/CSS3/JavaScript (no external dependencies required)

## Academic Context

This thesis explores the theory, implementation, and practical application of numerical optimization algorithms. It progresses from fundamental concepts through classical methods to modern variants, providing both theoretical foundation and interactive educational tools for understanding algorithm behavior on various problem classes.

## License

This work is provided as academic material for educational and research purposes.

---

**Last Updated:** 2024
