__precompile__()
module CachedArrays

using Missings
# using JLD2 # for JLDCachedArray

export

    cachedarray

abstract type CachedArray{T,N} <: AbstractArray{T,N} end

struct InMemoryCachedArray{T,N,A} <: AbstractArray{T,N} where {A <: AbstractArray{T,N}}
    parent::A
    cache::Array{Union{T,Missing},N}

    function InMemoryCachedArray(parent::AbstractArray{T,N}) where {T,N}
        cache = missings(T, size(parent))
        new{T,N,typeof(parent)}(parent,cache)
    end
end

Base.size(A::InMemoryCachedArray) = size(A.parent)

Base.@propagate_inbounds function Base.getindex(A::InMemoryCachedArray{T}, I::Int...) where T
    cached = A.cache[I...]
    ismissing(cached) || return cached::T
    A.cache[I...] = A.parent[I...]
end

"""
    cachedarray(A::AbstractArray) -> InMemoryCachedArray

Create a lazy decorator around `A` with the same shape and eltype
that caches the accessed elements. This is mainly useful if
`getindex(A, I)` triggers a lot of computation and the element
`I` is accessed often.
"""
cachedarray(A::AbstractArray) = InMemoryCachedArray(A)

end # module
