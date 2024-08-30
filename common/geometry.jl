using StaticArrays


abstract type AbstractPrim end

struct Square <: AbstractPrim end
struct Circle <: AbstractPrim end

# Only 2d shapes
mutable struct Geometry{T<:AbstractFloat, M<:AbstractMatrix{T}}
    pos::MVector{2, T}
    transform::M
    v::MVector{2, T}
    prim::AbstractPrim
    collide::Bool
end
