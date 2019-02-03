using FilePathsBase
using LinearAlgebra
using Test

include("testpaths.jl")

@testset "FilePathsBase" begin
    include("mode.jl")
    include("buffer.jl")
    include("path.jl")

    # Test that our weird registered path works
    path = p"test|;;my;weird;test;path"
    @test path.parts == ("test|", "", "my", "weird", "test", "path")
end
