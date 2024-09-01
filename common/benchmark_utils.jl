using Swirl, LinearAlgebra
using Swirl, Plots

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



function jacobi_bench!(fluid, v_div, maxIterations, ϵ=0; res_hist=nothing)
    f = similar(fluid.p)
    f_old = similar(f)
    copy!(f, fluid.p)
    Swirl.PressureSolve.jacobi!(f, f_old, v_div, fluid.collision, fluid.dx, maxIterations, res_history=res_hist)
end

function gaussSeidel_bench!(fluid, v_div, maxIterations, ϵ=0; res_hist=nothing)
    f = similar(fluid.p)
    copy!(f, fluid.p)
    Swirl.PressureSolve.gaussSeidel!(f, v_div, fluid.collision, fluid.dx, maxIterations, res_history=res_hist)
end

function conjugateGradient_bench!(fluid, v_div, maxIterations, ϵ=0; res_hist=nothing)
    f = similar(fluid.p)
    copy!(f, fluid.p)
    Swirl.PressureSolve.conjugateGradient!(f, v_div, fluid.collision, fluid.dx, maxIterations, ϵ, res_history=res_hist)
end

function preconditionedConjugateGradient_bench!(fluid, v_div, maxIterations, ϵ=0; res_hist=nothing)
    f = similar(fluid.p)
    copy!(f, fluid.p)
    Swirl.PressureSolve.preconditionedConjugateGradient!(f, v_div, fluid.collision, fluid.dx, maxIterations, ϵ; res_history=res_hist)
end

function jacobi_bench(fluid, v_div, maxIterations, ϵ=0)
    jacobi_bench!(fluid, v_div, maxIterations, ϵ; res_hist=nothing)
end
function gaussSeidel_bench(fluid, v_div, maxIterations, ϵ=0)
    gaussSeidel_bench!(fluid, v_div, maxIterations, ϵ; res_hist=nothing)
end
function conjugateGradient_bench(fluid, v_div, maxIterations, ϵ=0)
    conjugateGradient_bench!(fluid, v_div, maxIterations, ϵ; res_hist=nothing)
end
function preconditionedConjugateGradient_bench(fluid, v_div, maxIterations, ϵ=0)
    preconditionedConjugateGradient_bench!(fluid, v_div, maxIterations, ϵ; res_hist=nothing)
end

function gradeResidual(g_norm, res_norm, newLine=true)
    
    # as a (rough) rule of thumb, this seems to work
    if res_norm < 0.2g_norm
        printstyled("Good", color=:light_green)
    elseif res_norm < 0.7g_norm
        printstyled("Acceptable", color=:light_cyan)
    else
        printstyled("Bad", color=:light_red)
    end
    if newLine
        println()
    end
    nothing
end