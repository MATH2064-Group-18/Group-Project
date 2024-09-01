# Residual Comparison

Generates plot comparing the residual after each iteration for the Jacobi, Gauss-Seidel, vanilla Conjugate Gradient, Incomplete Cholesky Preconditioned Conjugate Gradient methods.

## Instructions

If current working directory is parent directory, use:
```bash
julia --project --threads=[insert number of threads] ResidualComparison/residual_comparison.jl
```

If your current working directory is this folder, use:
```bash
julia --project=".." --threads=[insert number of threads] residual_comparison.jl
```
(The plot will  be saved in the working directory.)