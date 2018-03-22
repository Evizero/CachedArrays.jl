# CachedArrays

[![Build Status](https://travis-ci.org/Evizero/CachedArrays.jl.svg?branch=master)](https://travis-ci.org/Evizero/CachedArrays.jl)
[![codecov.io](http://codecov.io/github/Evizero/CachedArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/Evizero/CachedArrays.jl?branch=master)

CachedArrays.jl provides a couple of array decorator types that
buffer intermediate result when `getindex` is invoked. This is
mainly useful in the combination with other lazy array decorators
such as
[MappedArrays.jl](https://github.com/JuliaArrays/MappedArrays.jl).

## Usage

```julia
julia> using CachedArrays, MappedArrays

julia> function foo(x)
           println("# expensive computation on ", x)
           x^2
       end

julia> A = mappedarray(foo, [1 2; 3 4]);

julia> B = cachedarray(A);

julia> size(B)
(2, 2)

julia> B[1,2]
# expensive computation on 2
4

julia> B[1,2]
4

julia> B[2,2]
# expensive computation on 4
16

julia> collect(B)
# expensive computation on 1
# expensive computation on 3
2×2 Array{Int64,2}:
 1   4
 9  16
```
