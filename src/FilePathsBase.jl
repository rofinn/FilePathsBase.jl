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
abstract type AbstractPath end  # Define the AbstractPath here to avoid circular include dependencies

"""
    register(::Type{<:AbstractPath})

Registers a new path type to support using `Path("...")` constructor and p"..." string
macro.
"""
function register(T::Type{<:AbstractPath})
    # We add the type to the beginning of our PATH_TYPES,
    # so that they can take precedence over the Posix and
    # Windows paths.
    pushfirst!(PATH_TYPES, T)
end

include("constants.jl")
include("utils.jl")
include("libc.jl")
include("mode.jl")
include("status.jl")
include("buffer.jl")
include("path.jl")
include("posix.jl")
include("windows.jl")
include("ospath.jl")

end # end of module
