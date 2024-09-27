using Swirl, BenchmarkTools, LinearAlgebra
using Dates, InteractiveUtils

include("../common/benchmark_utils.jl")

const Nx = 512
const Ny = 512

const MaxSolveIterations = 100

# Uncomment if wanting to run single-threaded. (must also run with --threads not set to larger than 1)
#BLAS.set_num_threads(1)

fluid = let
    T = Float64
    l = T[10, 10]
    n = (Nx, Ny)
    Dx = @. l / (n-1)
    v = zeros(T, 2, n[1], n[2])
    p = zeros(T, n[1], n[2])
    d = zeros(T, n[1], n[2])
    coll = ones(T, n[1], n[2])

    for i = 1:Nx
        for j = 1:Ny
            x = (i-1) * Dx[1]
            y = (j-1) * Dx[2]
            if hypot(x-0.5l[1], y-0.5l[2]) <= 2
                d[i, j] = 1
            end

            s = x - 0.5l[1]
            t = y - 0.5l[2]
            v[1, i, j] = s
            v[2, i, j] = -t
            if i == 1 || j == 1 || i == Nx || j == Ny
                coll[i, j] = -1
            end
        end
    end
    Swirl.Fluid(Dx, v, coll, p, d)
end

for _ in 1:3
    Swirl.timestepUpdate!(fluid, 1/60)
end

v_div = zeros(eltype(fluid.p), size(fluid.p))

divergence!(v_div, fluid.vel, fluid.collision, fluid.dx)




#==================== BENCHMARK ======================#

versioninfo()
printstyled("\n\nPRESSURE SOLVE BENCHMARK\n\n", bold=true, color=:light_magenta)

println("Pressure solve run with fixed $(MaxSolveIterations) iterations on $(Nx) × $(Ny) grid.")
v_div_norm = norm(v_div)
println("norm(∇⋅v) = $(v_div_norm)\n")
print("ETA: ")
printstyled(Dates.format(Dates.now() + Minute(3), "H:MM  yyyy-mm-dd"), color=:light_green)
println("\n\n")


# Gauss-Seidel Benchmark

printstyled("Gauss-Seidel Method:\n\n", bold=true, color=:light_yellow)
b1 = @benchmark gaussSeidel_bench($(fluid), $(v_div), MaxSolveIterations) seconds=20
res_norm_gs = gaussSeidel_bench(fluid, v_div, MaxSolveIterations).residual_norm
gradeResidual(v_div_norm, res_norm_gs)
println("Residual norm: $(res_norm_gs)")
show(stdout, MIME("text/plain"), b1)
println("\n\n")


# Jacobi Benchmark

printstyled("Jacobi Method:\n\n", bold=true, color=:light_yellow)
b2 = @benchmark jacobi_bench($(fluid), $(v_div), MaxSolveIterations) seconds=20
res_norm_j = jacobi_bench(fluid, v_div, MaxSolveIterations).residual_norm
gradeResidual(v_div_norm, res_norm_j)
println("Residual norm: $(res_norm_j)")
show(stdout, MIME("text/plain"), b2)
println("\n\n")



printstyled("Conjugate Gradient Method:\n\n", bold=true, color=:light_yellow)
b3 = @benchmark conjugateGradient_bench($(fluid), $(v_div), MaxSolveIterations) seconds=20
res_norm_cg = conjugateGradient_bench(fluid, v_div, MaxSolveIterations).residual_norm
gradeResidual(v_div_norm, res_norm_cg)
println("Residual norm: $(res_norm_cg)")
show(stdout, MIME("text/plain"), b3)
println("\n\n")

printstyled("Preconditioned Conjugate Gradient Method:\n\n", bold=true, color=:light_yellow)
b4 = @benchmark preconditionedConjugateGradient_bench($(fluid), $(v_div), MaxSolveIterations) seconds=20
res_norm_pcg = preconditionedConjugateGradient_bench(fluid, v_div, MaxSolveIterations).residual_norm
gradeResidual(v_div_norm, res_norm_pcg)
println("Residual norm: $(res_norm_pcg)")
show(stdout, MIME("text/plain"), b4)
println("\n")