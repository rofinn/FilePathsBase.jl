using FilePathsBase
using LinearAlgebra
using Test

using FilePathsBase.TestPaths

include("testpkg.jl")

@testset "FilePathsBase" begin
    include("mode.jl")
    include("buffer.jl")
    include("system.jl")
    # include("path.jl")

    # Test that our weird registered path works
    path = p"test|;;my;weird;test;path"
    @test path.parts == ("test|", "", "my", "weird", "test", "path")
end
