using CachedArrays
using Missings
using MappedArrays
using Base.Test

@testset "InMemoryCachedArray" begin
    A = @inferred cachedarray(2:5);
    @test A isa CachedArrays.InMemoryCachedArray{Int,1}
    @test eltype(A) == Int
    @test size(A) == (4,)
    @test A.parent === 2:5
    @test parent(A) === A.parent
    @test all(ismissing.(A.cache))
    @test @inferred(getindex(A, 2)) == 3
    @test ismissing.(A.cache) == [true, false, true, true]
    @test A[4] == 5
    @test A.cache[4] == 5
    @test ismissing.(A.cache) == [true, false, true, false]

    global counter = 0
    X = mappedarray(i->(global counter+=1; i), 1:5);
    @test counter == 1
    A = @inferred cachedarray(X);
    @test A isa CachedArrays.InMemoryCachedArray{Int,1}
    @test eltype(A) == Int
    @test counter == 1
    @test size(A) == (5,)
    @test counter == 1
    @test A[2] == 2
    @test counter == 2
    @test A[2] == 2
    @test counter == 2
    @test A[1] == 1
    @test counter == 3

    X = [1. 2 3; 4 5 6]
    A = @inferred cachedarray(X);
    @test A isa CachedArrays.InMemoryCachedArray{Float64,2}
    @test eltype(A) == Float64
    @test size(A) == (2,3)
    @test parent(A) === X
    @test ismissing.(A.cache) == [true true true; true true true]
    @test A[2,2] == 5
    @test A.cache[2,2] == 5
    @test ismissing.(A.cache) == [true true true; true false true]
    @test A[3] == 2
    @test ismissing.(A.cache) == [true false true; true false true]
end
