using LinearAlgebra, Plots, Swirl

include("../common/benchmark_utils.jl")

const Nx = 512
const Ny = 512

const MaxSolveIterations = 100



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




rh_j = Vector{Float64}(undef, 0)
rh_g = Vector{Float64}(undef, 0)
rh_cg = Vector{Float64}(undef, 0)
rh_pcg = Vector{Float64}(undef, 0)


jacobi_bench!(fluid, v_div, 1000; res_hist=rh_j)
gaussSeidel_bench!(fluid, v_div, 1000; res_hist=rh_g)
conjugateGradient_bench!(fluid, v_div, 1000, 0.0; res_hist=rh_cg)
preconditionedConjugateGradient_bench!(fluid, v_div, 1000, 0.0; res_hist=rh_pcg)
p = plot([rh_g rh_j rh_cg rh_pcg], label=["Gauss-Seidel" "Jacobi" "CG" "PCG"], xlabel="iterations", ylabel="residual")
plot([rh_j rh_pcg])
savefig(p, "residual_plot.svg")