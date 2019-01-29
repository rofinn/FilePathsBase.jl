module TestPaths

using FilePathsBase

import Base: ==

__init__() = FilePathsBase.register(TestPath)

# We'll make a semicolon separate test path
struct TestPath <: AbstractPath
    parts::Tuple{Vararg{String}}
end

TestPath() = TestPath(tuple())

function TestPath(str::AbstractString)
    str = string(str)

    if isempty(str)
        return TestPath(tuple("."))
    end

    tokenized = split(str, ";")
    if isempty(tokenized[1])
        tokenized[1] = ";"
    end
    return TestPath(tuple(map(String, tokenized)...))
end

==(a::TestPath, b::TestPath) = a.parts == b.parts
Base.string(path::TestPath) = join([path.parts...], ";")
FilePathsBase.ispathtype(::Type{TestPath}, str::AbstractString) = startswith(str, "test|;;")
Base.show(io::IO, path::TestPath) = print(io, "p\"$path\"")


end
