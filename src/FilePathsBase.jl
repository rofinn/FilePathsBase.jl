__precompile__()

module FilePathsBase

using Dates
using LinearAlgebra
using Printf

import Base: ==
export
    # Types
    AbstractPath,
    Path,
    PosixPath,
    WindowsPath,
    Mode,
    Status,

    # Methods
    anchor,
    cwd,
    drive,
    home,
    parts,
    root,
    hasparent,
    parents,
    filename,
    extension,
    extensions,
    exists,
    isabs,
    mode,
    created,
    modified,
    relative,
    move,
    remove,
    tmpname,
    tmpdir,
    mktmp,
    mktmpdir,
    chown,
    executable,
    readable,
    writable,
    raw,

    # Macros
    @p_str,
    @__PATH__,
    @__FILEPATH__,

    # Constants
    READ,
    WRITE,
    EXEC


export isexecutable

const PATH_TYPES = DataType[]

function __init__()
    register(PosixPath)
    register(WindowsPath)
end

"""
    AbstractPath

Defines an abstract filesystem path. Subtypes of `AbstractPath` should implement the
following methods:

- `Base.print(io, p)` (default: call base julia's joinpath with drive and path parts)
- `FilePathsBase.parts(p)`
- `FilePathsBase.root(p)`
- `FilePathsBase.drive(p)`
- `FilePathsBase.ispathtype(::Type{MyPath}, x::AbstractString) = true`
"""
abstract type AbstractPath end

function register(T::Type{<:AbstractPath})
    # We add the type to the beginning of our PATH_TYPES,
    # so that they can take precedence over the Posix and
    # Windows paths.
    pushfirst!(PATH_TYPES, T)
end

#=
We only want to print the macro string syntax when compact is true and
we want print to just return the string (this allows `string` to work normally)
=#
Base.print(io::IO, path::AbstractPath) = print(io, joinpath(drive(path), parts(path)...))

function Base.show(io::IO, path::AbstractPath)
    get(io, :compact, false) ? print(io, path) : print(io, "p\"$path\"")
end

Base.parse(::Type{<:AbstractPath}, x::AbstractString) = Path(x)
Base.convert(::Type{AbstractPath}, x::AbstractString) = Path(x)
Base.convert(::Type{String}, x::AbstractPath) = string(x)
Base.promote_rule(::Type{String}, ::Type{<:AbstractPath}) = String
ispathtype(::Type{<:AbstractPath}, x::AbstractString) = false

include("constants.jl")
include("utils.jl")
include("libc.jl")
include("mode.jl")
include("status.jl")
include("buffer.jl")
include("posix.jl")
include("windows.jl")
include("path.jl")
include("deprecates.jl")

end # end of module
