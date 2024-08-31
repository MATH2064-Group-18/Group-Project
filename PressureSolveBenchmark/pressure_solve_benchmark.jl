using Swirl, BenchmarkTools

const Nx = 512
const Ny = 512

const MaxSolveIterations = 100

"""
    divergence!(v_div, v, collision, dx)

Compute divergence while enforcing free-slip boundary condition.
"""
function divergence!(v_div, v, collision, dx)
    @assert length(dx) == size(v, 1)
    s0 = length(dx)

    for i in eachindex(collision)
        if collision[i] > 0
            for (j, s) in enumerate(strides(collision))
                b1 = collision[i - s] > 0 ? v[j + s0*(i - s-1)] : 2 * v[j + s0*(i - s - 1)] - v[j + s0 * (i-1)]
                b2 = collision[i + s] > 0 ? v[j + s0*(i + s-1)] : 2 * v[j + s0*(i + s - 1)] - v[j + s0 * (i-1)]
                v_div[i] += (b2 - b1) * 0.5 / dx[j]
            end
        end
    end
    
    return v_div
end

function jacobi_bench(fluid, v_div, maxIterations, ϵ=0)
    f = similar(fluid.p)
    f_old = similar(f)
    copy!(f, fluid.p)
    Swirl.PressureSolve.jacobi!(f, f_old, v_div, fluid.collision, fluid.dx, maxIterations)
end

function gaussSeidel_bench(fluid, v_div, maxIterations, ϵ=0)
    f = similar(fluid.p)
    copy!(f, fluid.p)
    Swirl.PressureSolve.gaussSeidel!(f, v_div, fluid.collision, fluid.dx, maxIterations)
end

function conjugateGradient_bench(fluid, v_div, maxIterations, ϵ=0)
    f = similar(fluid.p)
    copy!(f, fluid.p)
    Swirl.PressureSolve.conjugateGradient!(f, v_div, fluid.collision, fluid.dx, maxIterations, ϵ)
end

function preconditionedConjugateGradient_bench(fluid, v_div, maxIterations, ϵ=0)
    f = similar(fluid.p)
    copy!(f, fluid.p)
    Swirl.PressureSolve.preconditionedConjugateGradient!(f, v_div, fluid.collision, fluid.dx, maxIterations, ϵ)
end


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


printstyled("\n\nPRESSURE SOLVE BENCHMARK\n\n\n", bold=true, color=:light_magenta)


# Gauss-Seidel Benchmark

printstyled("Gauss-Seidel Method:\n\n", bold=true, color=:light_yellow)
b1 = @benchmark gaussSeidel_bench($(fluid), $(v_div), MaxSolveIterations) seconds=20
println("Residual norm: $(gaussSeidel_bench(fluid, v_div, MaxSolveIterations).residual_norm)")
show(stdout, MIME("text/plain"), b1)
println("\n\n")


# Jacobi Benchmark

printstyled("Jacobi Method:\n\n", bold=true, color=:light_yellow)
b2 = @benchmark jacobi_bench($(fluid), $(v_div), MaxSolveIterations) seconds=20
println("Residual norm: $(jacobi_bench(fluid, v_div, MaxSolveIterations).residual_norm)")
show(stdout, MIME("text/plain"), b2)
println("\n\n")



printstyled("Conjugate Gradient Method:\n\n", bold=true, color=:light_yellow)
b3 = @benchmark conjugateGradient_bench($(fluid), $(v_div), MaxSolveIterations) seconds=20
println("Residual norm: $(conjugateGradient_bench(fluid, v_div, MaxSolveIterations).residual_norm)")
show(stdout, MIME("text/plain"), b3)
println("\n\n")

printstyled("Preconditioned Conjugate Gradient Method:\n\n", bold=true, color=:light_yellow)
b4 = @benchmark preconditionedConjugateGradient_bench($(fluid), v_div, MaxSolveIterations) seconds=20
println("Residual norm: $(preconditionedConjugateGradient_bench(fluid, v_div, MaxSolveIterations).residual_norm)")
show(stdout, MIME("text/plain"), b4)
println("\n")