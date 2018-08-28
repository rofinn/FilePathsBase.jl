using Compat
using FilePathsBase
using Compat.LinearAlgebra
using Compat.Test

@testset "FilePathsBase" begin

include("mode.jl")
include("path.jl")
include("unc.jl")

end
