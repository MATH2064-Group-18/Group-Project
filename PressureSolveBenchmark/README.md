# Pressure Solve Benchmark

Benchmarks each implemented iterative method to solve Poisson equation
```math
\nabla^2 p = 0
```
with Neumann boundary condition
```math
\frac{\partial p}{\partial n} = 0.
```

## Instructions

If current working directory is parent directory, use:
```bash
julia --project --threads=[insert number of threads] PressureSolveBenchmark/pressure_solve_benchmark.jl
```

If your current working directory is this folder, use:
```bash
julia --project=".." --threads=[insert number of threads] pressure_solve_benchmark.jl
```


## Configuration

Near the top of [pressure_solve_benchmark.jl](pressure_solve_benchmark.jl) are a bunch of settings for the benchmark, such as `MaxSolveIterations`.
