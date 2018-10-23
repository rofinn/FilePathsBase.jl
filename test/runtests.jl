using Compat
using FilePathsBase
using Compat.LinearAlgebra
using Compat.Test

include("testpaths.jl")

@testset "FilePathsBase" begin
    include("mode.jl")
    include("path.jl")

    # Test that our weird registered path works
    path = p"test|;;my;weird;test;path"
    @test path.parts == ("test|", "", "my", "weird", "test", "path")
end
