__precompile__()

module FilePathsBase

using Dates
using Printf
using UUIDs

import Base: ==
export
    # Types
    AbstractPath,
    Path,
    SystemPath,
    PosixPath,
    WindowsPath,
    FilePath,
    DirectoryPath,
    RelativePath,
    AbsolutePath,
    Mode,
    Status,
    FileBuffer,

    # Methods
    cwd,
    home,
    hasparent,
    parents,
    isascendant,
    isdescendant,
    filename,
    extension,
    extensions,
    exists,
    absolute,
    isabsolute,
    mode,
    created,
    modified,
    normalize,
    canonicalize,
    relative,
    isrelative,
    ismount,
    islink,
    cp,
    mv,
    sync,
    tmpname,
    tmpdir,
    mktmp,
    mktmpdir,
    chown,
    executable,
    readable,
    writable,
    raw,
    readpath,
    walkpath,

    # Macros
    @p_str,
    @__PATH__,
    @__FILEPATH__,

    # Constants
    READ,
    WRITE,
    EXEC


export isexecutable

const PATH_TYPES = Type[]

function __init__()
    register(PosixPath)
    register(WindowsPath)
end

abstract type Form end
struct Abs <: Form end
struct Rel <: Form end

abstract type Kind end
struct Dir <: Kind end
struct File <: Kind end
# Could choose to extend this with Symlink?

"""
    AbstractPath{F<:Form, K<:Kind}

Defines an abstract filesystem path.

# Properties

- `segments::Tuple{Vararg{String}}` - path segments (required)
- `root::String` - path root (defaults to "/")
- `drive::String` - path drive (defaults to "")
- `separator::String` - path separator (defaults to "/")

# Required Methods
- `T(str::String)` - A string constructor
- `FilePathsBase.ispathtype(::Type{T}, x::AbstractString) = true`
- `read(path::T)`
- `write(path::T, data)`
- `exists(path::T` - whether the path exists
- `stat(path::T)` - File status describing permissions, size and creation/modified times
- `mkdir(path::T; kwargs...)` - Create a new directory
- `rm(path::T; kwags...)` - Remove a file or directory
- `readdir(path::T)` - Scan all files and directories at a specific path level
"""
abstract type AbstractPath{F<:Form, K<:Kind} end  # Define the AbstractPath here to avoid circular include dependencies

# A couple utility methods to extract the form and kind from a type.
form(fp::AbstractPath{F}) where {F<:Form} = F
kind(fp::AbstractPath{F, K}) where {F<:Form, K<:Kind} = K
function fptype(fp::AbstractPath)
    i = findfirst(T -> fp isa T, PATH_TYPES)
    return PATH_TYPES[i]
end

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

"""
    ispathtype(::Type{T}, x::AbstractString) where T <: AbstractPath

Return a boolean as to whether the string `x` fits the specified the path type.
"""
function ispathtype end

# define some aliases for parameterized abstract paths
const AbsolutePath = AbstractPath{Abs}
const RelativePath = AbstractPath{Rel}
const FilePath = AbstractPath{<:Form, File}
const DirectoryPath = AbstractPath{<:Form, Dir}

include("constants.jl")
include("utils.jl")
include("libc.jl")
include("mode.jl")
include("status.jl")
include("buffer.jl")
include("path.jl")
include("aliases.jl")
include("system.jl")
include("posix.jl")
include("windows.jl")
include("test.jl")
include("deprecates.jl")

end # end of module
