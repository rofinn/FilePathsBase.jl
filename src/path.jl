

"""
    Path()
    Path(path::AbstractPath)
    Path(path::Tuple)
    Path(path::AbstractString)

Responsible for creating the appropriate platform specific path
(e.g., `PosixPath` and `WindowsPath` for Unix and Windows systems respectively)

NOTE: `Path(::AbstractString` can also work for custom paths if `ispathtype` is defined
for that type.
"""
function Path end

Path(path::AbstractPath) = path

# May want to support using the registry for other constructors as well
function Path(str::AbstractString; debug=false)
    types = filter(t -> ispathtype(t, str), PATH_TYPES)

    if length(types) > 1
        @debug(
            string(
                "Found multiple path types that match the string specified ($types). ",
                "Please use a specific constructor if $(first(types)) is not the correct type."
            )
        )
    end

    return first(types)(str)
end

"""
    @p_str -> Path

Constructs a `Path` (platform specific subtype of `AbstractPath`), such as
`p"~/.juliarc.jl"`.
"""
macro p_str(path)
    Path(path)
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

cwd() = Path(pwd())
home() = Path(homedir())

anchor(path::AbstractPath) = drive(path) * root(path)

#=
Path Modifiers
===============================================
The following are methods for working with and extracting
path components
=#
"""
    hasparent(path::AbstractPath) -> Bool

Returns whether there is a parent directory component to the supplied path.
"""
hasparent(path::AbstractPath) = length(parts(path)) > 1

"""
    parent{T<:AbstractPath}(path::T) -> T

Returns the parent of the supplied path.

# Example
```
julia> parent(p"~/.julia/v0.6/REQUIRE")
p"~/.julia/v0.6"
```

# Throws
* `ErrorException`: if `path` doesn't have a parent
"""
Base.parent(path::AbstractPath) = parents(path)[end]

"""
    parents{T<:AbstractPath}(path::T) -> Array{T}

# Example
```
julia> parents(p"~/.julia/v0.6/REQUIRE")
3-element Array{FilePathsBase.PosixPath,1}:
 p"~"
 p"~/.julia"
 p"~/.julia/v0.6"
 ```

# Throws
* `ErrorException`: if `path` doesn't have a parent
"""
function parents(path::T) where {T <: AbstractPath}
    if hasparent(path)
        return map(1:length(parts(path))-1) do i
            T(parts(path)[1:i])
        end
    else
        error("$path has no parents")
    end
end

"""
  *(a::T, b::Union{T, AbstractString, AbstractChar}...) where {T <: AbstractPath} -> T

Concatenate paths, strings and/or characters, producing a new path.
This is equivalent to concatenating the string representations of paths and other strings
and then constructing a new path.

# Example

julia> p"foo" * "bar"
p"foobar"
"""
function Base.:(*)(a::T, b::Union{T, AbstractString, AbstractChar}...) where T <: AbstractPath
    T(*(string(a), string.(b)...))
end

"""
  /(a::AbstractPath, b::Union{AbstractPath, AbstractString}...) -> AbstractPath

Join the path components into a new fulll path, equivalent to calling `joinpath`

# Example

julia> p"foo" / "bar"
p"foo/bar"

julia> p"foo" / "bar" / "baz"
p"foo/bar/baz"
"""
function Base.:(/)(root::AbstractPath, pieces::Union{AbstractPath, AbstractString}...)
    join(root, pieces...)
end

"""
    join(root::AbstractPath, pieces::Union{AbstractPath, AbstractString}...) -> AbstractPath

Joins path components into a full path.

# Example
```
julia> join(p"~/.julia/v0.6", "REQUIRE")
p"~/.julia/v0.6/REQUIRE"
```
"""
function Base.join(root::AbstractPath, pieces::Union{AbstractPath, AbstractString}...)
    all_parts = String[]
    push!(all_parts, parts(root)...)

    for p in map(Path, pieces)
        push!(all_parts, parts(p)...)
    end

    return Path(tuple(all_parts...))
end

function Base.joinpath(root::AbstractPath, pieces::Union{AbstractPath, AbstractString}...)
    return join(root, pieces...)
end

Base.basename(path::AbstractPath) = parts(path)[end]

"""
    filename(path::AbstractPath) -> AbstractString

Extracts the `basename` without any extensions.

# Example
```
julia> filename(p"~/repos/FilePathsBase.jl/src/FilePathsBase.jl")
"FilePathsBase"
```
"""
function filename(path::AbstractPath)
    name = basename(path)
    return split(name, '.')[1]
end

"""
    extension(path::AbstractPath) -> AbstractString

Extracts the last extension from a filename if there any, otherwise it returns an empty string.

# Example
```
julia> extension(p"~/repos/FilePathsBase.jl/src/FilePathsBase.jl")
"jl"
```
"""
function extension(path::AbstractPath)
    name = basename(path)

    tokenized = split(name, '.')
    if length(tokenized) > 1
        return tokenized[end]
    else
        return ""
    end
end

"""
    extensions(path::AbstractPath) -> AbstractString

Extracts all extensions from a filename if there any, otherwise it returns an empty string.

# Example
```
julia> extensions(p"~/repos/FilePathsBase.jl/src/FilePathsBase.jl.bak")
2-element Array{SubString{String},1}:
 "jl"
 "bak"
```
"""
function extensions(path::AbstractPath)
    name = basename(path)

    tokenized = split(name, '.')
    if length(tokenized) > 1
        return tokenized[2:end]
    else
        return []
    end
end

"""
    isempty(path::AbstractPath) -> Bool

Returns whether or not a path is empty.

NOTE: Empty paths are usually only created by `Path()`, as `p""` and `Path("")` will
default to using the current directory (or `p"."`).
"""
Base.isempty(path::AbstractPath) = isempty(parts(path))

"""
    norm(path::AbstractPath) -> AbstractPath

Normalizes a path by removing "." and ".." entries.
"""
function LinearAlgebra.norm(path::T) where {T <: AbstractPath}
    p = parts(path)
    result = String[]
    rem = length(p)
    count = 0
    del = 0

    while count < length(p)
        str = p[end - count]

        if str == ".."
            del += 1
        elseif str != "."
            if del == 0
                push!(result, str)
            else
                del -= 1
            end
        end

        rem -= 1
        count += 1
    end

    return T(tuple(fill("..", del)..., reverse(result)...))
end

"""
    abs(path::AbstractPath) -> AbstractPath

Creates an absolute path by adding the current working directory if necessary.
"""
function Base.abs(path::AbstractPath)
    result = expanduser(path)

    if isabs(result)
        return norm(result)
    else
        return norm(join(cwd(), result))
    end
end

"""
    relative{T<:AbstractPath}(path::T, start::T=T("."))

Creates a relative path from either the current directory or an arbitrary start directory.
"""
function relative(path::T, start::T=T(".")) where {T <: AbstractPath}
    curdir = "."
    pardir = ".."

    p = parts(abs(path))
    s = parts(abs(start))

    p == s && return T(curdir)

    i = 0
    while i < min(length(p), length(s))
        i += 1
        @static if Sys.iswindows()
            if lowercase(p[i]) != lowercase(s[i])
                i -= 1
                break
            end
        else
            if p[i] != s[i]
                i -= 1
                break
            end
        end
    end

    pathpart = p[(i + 1):findlast(x -> !isempty(x), p)]
    prefix_num = findlast(x -> !isempty(x), s) - i - 1
    if prefix_num >= 0
        relpath_ = isempty(pathpart) ?
            tuple(fill(pardir, prefix_num + 1)...) :
            tuple(fill(pardir, prefix_num + 1)..., pathpart...)
    else
        relpath_ = pathpart
    end
    return isempty(relpath_) ? T(curdir) : T(relpath_)
end

"""
    cp(src::AbstractPath, dst::AbstractPath; force=false, follow_symlinks=false)

Copy the file or directory from `src` to `dst`. An existing `dst` will only be overwritten
if `force=true`. If the path types support symlinks then `follow_symlinks=true` will
copy the contents of the symlink to the destination.
"""
function Base.cp(src::AbstractPath, dst::AbstractPath; force=false)
    if exists(dst)
        if force
            rm(dst; force=force, recursive=true)
        else
            throw(ArgumentError("Destination already exists: $dst"))
        end
    end

    if !exists(src)
        throw(ArgumentError("Source path does not exist: $src"))
    elseif isdir(src)
        mkdir(dst)

        for path in readdir(src)
            cp(src / path, dst / path; force=force)
        end
    elseif isfile(src)
        write(dst, read(src))
    else
        throw(ArgumentError("Source path is not a file or directory: $src"))
    end

    return dst
end

"""
    mv(src::AbstractPath, dst::AbstractPath; force=false)

Move the file or director from `src` to `dst`. An exist `dst` will only be overwritten if
`force=true`.
"""
function Base.mv(src::AbstractPath, dst::AbstractPath; force=false)
    cp(src, dst; force=force)
    rm(src; recursive=true)
end

# TODO: Implement walkdir

############################################################################################
#                     Implementation Specific Methods                                      #
############################################################################################
# NOTE: Some methods seem `OSPath` specific, so we're leaving them out of the documented   #
# AbstractPath API.                                                                        #
#                                                                                          #
# (e.g., `stat`, `mode`, `islink`, `issocket`, `isfifo`, `ismount`, `chown`/`chmod`)       #
############################################################################################

"""
    exists(path::AbstractPath) -> Bool

Returns whether the path actually exists on the system.
"""
exists(path::AbstractPath) = throw(MethodError(exists, (path,)))

"""
    real(path::AbstractPath) -> AbstractPath

Canonicalizes a path by expanding symlinks and removing "." and ".." entries.
"""
Base.real(path::AbstractPath) = throw(MethodError(real, (path,)))

"""
    size(path::AbstractPath) -> Int

Returns the number of bytes for a file or object at the specified path location.
"""
Base.size(path::AbstractPath) = throw(MethodError(size, (path,)))

"""
    modified(path::AbstractPath) -> DateTime

Returns the last modified date for the `path`.

# Example
```
julia> modified(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
modified(path::AbstractPath) = throw(MethodError(modified, (path,)))

"""
    created(path::AbstractPath) -> DateTime

Returns the creation date for the `path`.

# Example
```
julia> created(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
created(path::AbstractPath) = throw(MethodError(created, (path,)))

"""
    isdir(path::AbstractPath) -> Bool

Returns `true` if `path` is a "directory", `false` otherwise.
"""
Base.isdir(path::AbstractPath) = throw(MethodError(isdir, (path,)))

"""
    isfile(path::AbstractPath) -> Bool

Returns `true` if `path` is a file, `false` otherwise.
"""
Base.isfile(path::AbstractPath) = throw(MethodError(isfile, (path,)))

"""
    isexecutable(path::AbstractPath) -> Bool

Returns whether the `path` is executable for the current user.
"""
isexecutable(path::AbstractPath) = throw(MethodError(isexecutable, (path,)))

"""
    iswritable(path::AbstractPath) -> Bool

Returns whether the `path` is writable for the current user.
"""
Base.iswritable(path::AbstractPath) = throw(MethodError(iswritable, (path,)))

"""
    isreadable(path::AbstractPath) -> Bool

Returns whether the `path` is readable for the current user.
"""
Base.isreadable(path::AbstractPath) = throw(MethodError(isreadable, (path,)))

"""
    cd(path::AbstractPath)
    cd(f::Function, path::AbstractPath)

Set the current working directory, or run a function `f` in that directory.
"""
Base.cd(path::AbstractPath) = throw(MethodError(cd, (path,)))
Base.cd(f::Function, path::AbstractPath) = throw(MethodError(cd, (f, path)))

"""
    mkdir(path::AbstractPath; mode=mode=0o777, recursive=false, exist_ok=false)

Make a new directory with the permissions `mode`. If the directory already exists and
`exist_ok` is `false` then an error will be thrown. All intermediate directories will be
created if `recursive` is `true`.
"""
Base.mkdir(path::AbstractPath; kwargs...) = throw(MethodError(mkdir, (path,)))

"""
    rm(path::AbstractPath; force::Bool=false, recursive::Bool=false)

Delete the file or directory. Directory contents will only be deleted recursively when `recursive=true`.
Non-existent paths will error unless `force=true`.
"""
Base.rm(path::AbstractPath; kwargs...) = throw(MethodError(rm, (path,)))

"""
    readdir(path::AbstractPath)

Reads a list of files and directories at the top level of the provided path.
"""
Base.readdir(path::AbstractPath) = throw(MethodError(readdir, (path,)))

# ALIASES for base filesystem API
Base.dirname(path::AbstractPath) = parent(path)
Base.ispath(path::AbstractPath) = exists(path)
Base.realpath(path::AbstractPath) = real(path)
Base.normpath(path::AbstractPath) = norm(path)
Base.abspath(path::AbstractPath) = abs(path)
Base.relpath(path::AbstractPath) = relative(path)
Base.filemode(path::AbstractPath) = mode(path)
Base.isabspath(path::AbstractPath) = isabs(path)
Base.mkpath(path::AbstractPath) = mkdir(path; recursive=true)

# ALIASES for now old FilePaths API
move(src::AbstractPath, dest::AbstractPath; kwargs...) = mv(src, dest; kwargs...)
remove(path::AbstractPath; kwargs...) = rm(path; kwargs...)
