__precompile__()
module CachedArrays

using Missings
using JLD2

export

    cachedarray

abstract type CachedArray{T,N} <: AbstractArray{T,N} end

"""
    InMemoryCachedArray(A::AbstractArray)
"""
struct InMemoryCachedArray{T,N,A} <: AbstractArray{T,N} where {A <: AbstractArray{T,N}}
    parent::A
    cache::Array{Union{T,Missing},N}

    function InMemoryCachedArray(parent::AbstractArray{T,N}) where {T,N}
        cache = missings(T, size(parent))
        new{T,N,typeof(parent)}(parent, cache)
    end
end

Base.parent(A::InMemoryCachedArray) = A.parent
Base.size(A::InMemoryCachedArray) = size(A.parent)

Base.@propagate_inbounds function Base.getindex(A::InMemoryCachedArray{T}, I::Int...) where T
    cached = A.cache[I...]
    ismissing(cached) || return cached::T
    A.cache[I...] = A.parent[I...]
end

"""
    JLDCachedArray(A::AbstractArray, [dir])
"""
struct JLDCachedArray{T,N,A} <: AbstractArray{T,N}
    parent::A
    dir::String

    function JLDCachedArray(parent::AbstractArray{T,N}, dir = mktempdir()) where {T,N}
        isdir(dir) || mkpath(dir)
        new{T,N,typeof(parent)}(parent, dir)
    end

end

Base.parent(A::JLDCachedArray) = A.parent
Base.size(A::JLDCachedArray) = size(A.parent)

# remove trailing ones to avoid duplicated files
function _squeeze_tuple(tup)
    n = 0
    for i in length(tup):-1:2
        if tup[i] == 1
            n += 1
        else
            break
        end
    end
    tup[1:end-n]
end

function Base.getindex(A::JLDCachedArray{T}, I::Int...) where T
    path = joinpath(A.dir, string(join(_squeeze_tuple(I), "_"), ".jld2"))
    if isfile(path)
        _load(path, "value")::T
    else
        value = A.parent[I...]
        _save(path, "value", value)
        value
    end
end

function _save(path, name::AbstractString, value)
    jldopen(path, "w") do file
        wsession = JLD2.JLDWriteSession()
        write(file, String(name), value, wsession)
    end
end

function _load(path, name::AbstractString)
    jldopen(path, "r") do file
        read(file, String(name))
    end
end

"""
    cachedarray(A::AbstractArray) -> InMemoryCachedArray

Create a lazy decorator around `A` with the same shape and eltype
that caches the accessed elements. This is mainly useful if
`getindex(A, I)` triggers a lot of computation and the element
`I` is accessed often.
"""
cachedarray(A::AbstractArray) = InMemoryCachedArray(A)

"""
    cachedarray(A::AbstractArray, dir::String) -> JLDCachedArray

Caches the elements on disk at `dir` instead of in-memory. This
can be useful for persisting data between sessions (if the
indicies-to-element remains consistant), or for arrays that don't
fit into memory.
"""
cachedarray(A::AbstractArray, dir) = JLDCachedArray(A, dir)

end # module
