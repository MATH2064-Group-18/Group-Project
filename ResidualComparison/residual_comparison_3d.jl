using Swirl, LinearAlgebra, Plots

include("../common/benchmark_utils.jl")

const Nx = 64
const Ny = 64
const Nz = 64


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
savefig(p, "residual_plot_3d.svg")