using StaticArrays


abstract type AbstractPrim end

struct Square <: AbstractPrim end
struct Circle <: AbstractPrim end

function primIntersect(pos, ::Square)
    return all(x -> -1 <= x <= 1, pos)
end

function primIntersect(pos, ::Circle)
    return hypot(pos[1], pos[2]) <= 1
end

# Only 2d shapes
mutable struct Geometry{T<:AbstractFloat}
    prim::AbstractPrim
    transform::MMatrix{2, 2, T, 4}
    pos::MVector{2, T}
    v::MVector{2, T}
    ω::T
    isCollider::Bool
    isSource::Bool
end