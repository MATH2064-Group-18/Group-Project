using Swirl, BenchmarkTools, LinearAlgebra

include("../common/benchmark_utils.jl")

const Nx = 64
const Ny = 64
const Nz = 64

const MaxSolveIterations = 100


# Uncomment if wanting to run single-threaded.
#BLAS.set_num_threads(1)


fluid = let
    T = Float64
    l = T[10, 10, 10]
    n = (Nx, Ny, Nz)
    Dx = @. l / (n-1)
    v = zeros(T, length(n), n[1], n[2], n[3])
    p = zeros(T, n)
    d = zeros(T, n)
    coll = ones(T, n)

    for I in CartesianIndices(p)
        x = (Tuple(I).-1) .* Dx
        for j in 1:ndims(p)
            k = (j % ndims(p)) + 1
            s = j % 2 == 0 ? 1 : -1
            v[j, I] = s * x[k]
        end
        if any(q -> q[2] == 1 || q[2] == n[q[1]], enumerate(Tuple(I)))
            v[:, I] .= 0
            coll[I] = -1
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


printstyled("\n\nPRESSURE SOLVE BENCHMARK 3D\n\n", bold=true, color=:light_magenta)

println("Pressure solve run with fixed $(MaxSolveIterations) iterations on $(Nx) × $(Ny) × $(Nz) grid.")
v_div_norm = norm(v_div)
println("norm(∇⋅v) = $(v_div_norm)\n\n")


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
b4 = @benchmark preconditionedConjugateGradient_bench($(fluid), v_div, MaxSolveIterations) seconds=20
res_norm_pcg = preconditionedConjugateGradient_bench(fluid, v_div, MaxSolveIterations).residual_norm
gradeResidual(v_div_norm, res_norm_pcg)
println("Residual norm: $(res_norm_pcg)")
show(stdout, MIME("text/plain"), b4)
println("\n")
