

"""
    Path()
    Path(fp::AbstractPath)
    Path(fp::Tuple)
    Path(fp::AbstractString)

Responsible for creating the appropriate platform specific path
(e.g., `PosixPath` and `WindowsPath` for Unix and Windows systems respectively)

NOTE: `Path(::AbstractString` can also work for custom paths if `ispathtype` is defined
for that type.
"""
function Path end

Path(fp::AbstractPath) = fp

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
macro p_str(fp)
    return :(Path($fp))
end

==(a::P, b::P) where P <: AbstractPath = components(a) == components(b)

#=
We only want to print the macro string syntax when compact is true and
we want print to just return the string (this allows `string` to work normally)
=#
Base.print(io::IO, fp::AbstractPath) = print(io, anchor(fp) * joinpath(path(fp)...))

function Base.show(io::IO, fp::AbstractPath)
    get(io, :compact, false) ? print(io, fp) : print(io, "p\"$fp\"")
end

Base.parse(::Type{<:AbstractPath}, x::AbstractString) = Path(x)
Base.convert(::Type{<:AbstractPath}, x::AbstractString) = Path(x)
Base.convert(::Type{String}, x::AbstractPath) = string(x)
Base.promote_rule(::Type{String}, ::Type{<:AbstractPath}) = String

cwd() = Path(pwd())
home() = Path(homedir())

anchor(fp::AbstractPath) = drive(fp) * root(fp)
components(fp::AbstractPath) = tuple(drive(fp), root(fp), path(fp)...)

#=
Path Modifiers
===============================================
The following are methods for working with and extracting
path components
=#
"""
    hasparent(fp::AbstractPath) -> Bool

Returns whether there is a parent directory component to the supplied path.
"""
hasparent(fp::AbstractPath) = length(path(fp)) > 1

"""
    parent{T<:AbstractPath}(fp::T) -> T

Returns the parent of the supplied path.

# Example
```
julia> parent(p"~/.julia/v0.6/REQUIRE")
p"~/.julia/v0.6"
```

# Throws
* `ErrorException`: if `path` doesn't have a parent
"""
Base.parent(fp::AbstractPath) = parents(fp)[end]

"""
    parents{T<:AbstractPath}(fp::T) -> Array{T}

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
function parents(fp::T) where {T <: AbstractPath}
    if hasparent(fp)
        return map(2:length(components(fp))-1) do i
            T(tuple(components(fp)[1:i]...))
        end
    else
        error("$fp has no parents")
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
function Base.join(prefix::T, pieces::Union{AbstractPath, AbstractString}...) where T <: AbstractPath
    all_parts = String[]
    push!(all_parts, components(prefix)...)

    for p in map(Path, pieces)
        push!(all_parts, components(p)...)
    end

    return T(tuple(all_parts...))
end

function Base.joinpath(root::AbstractPath, pieces::Union{AbstractPath, AbstractString}...)
    return join(root, pieces...)
end

Base.basename(fp::AbstractPath) = path(fp)[end]

"""
    filename(fp::AbstractPath) -> AbstractString

Extracts the `basename` without any extensions.

# Example
```
julia> filename(p"~/repos/FilePathsBase.jl/src/FilePathsBase.jl")
"FilePathsBase"
```
"""
function filename(fp::AbstractPath)
    name = basename(fp)
    return split(name, '.')[1]
end

"""
    extension(fp::AbstractPath) -> AbstractString

Extracts the last extension from a filename if there any, otherwise it returns an empty string.

# Example
```
julia> extension(p"~/repos/FilePathsBase.jl/src/FilePathsBase.jl")
"jl"
```
"""
function extension(fp::AbstractPath)
    name = basename(fp)

    tokenized = split(name, '.')
    if length(tokenized) > 1
        return tokenized[end]
    else
        return ""
    end
end

"""
    extensions(fp::AbstractPath) -> AbstractString

Extracts all extensions from a filename if there any, otherwise it returns an empty string.

# Example
```
julia> extensions(p"~/repos/FilePathsBase.jl/src/FilePathsBase.jl.bak")
2-element Array{SubString{String},1}:
 "jl"
 "bak"
```
"""
function extensions(fp::AbstractPath)
    name = basename(fp)

    tokenized = split(name, '.')
    if length(tokenized) > 1
        return tokenized[2:end]
    else
        return []
    end
end

"""
    isempty(fp::AbstractPath) -> Bool

Returns whether or not a path is empty.

NOTE: Empty paths are usually only created by `Path()`, as `p""` and `Path("")` will
default to using the current directory (or `p"."`).
"""
Base.isempty(fp::AbstractPath) = isempty(path(fp))

"""
    norm(fp::AbstractPath) -> AbstractPath

Normalizes a path by removing "." and ".." entries.
"""
function LinearAlgebra.norm(fp::T) where {T <: AbstractPath}
    p = path(fp)
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

    return T(tuple(drive(fp), root(fp), fill("..", del)..., reverse(result)...))
end

"""
    abs(fp::AbstractPath) -> AbstractPath

Creates an absolute path by adding the current working directory if necessary.
"""
function Base.abs(fp::AbstractPath)
    result = expanduser(fp)

    if isabs(result)
        return norm(result)
    else
        return norm(join(cwd(), result))
    end
end

function isabs(fp::AbstractPath)
    return !isempty(drive(fp)) && !isempty(root(fp))
end

"""
    relative{T<:AbstractPath}(fp::T, start::T=T("."))

Creates a relative path from either the current directory or an arbitrary start directory.
"""
function relative(fp::T, start::T=T(".")) where {T <: AbstractPath}
    curdir = "."
    pardir = ".."

    p = path(abs(fp))
    s = path(abs(start))

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

        for fp in readdir(src)
            cp(src / fp, dst / fp; force=force)
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

"""
    download(url::Union{AbstractString, AbstractPath}, localfile::AbstractPath)

Download a file from the remote url and save it to the localfile path.
"""
function Base.download(url::AbstractString, localfile::AbstractPath)
    mktmp() do fp, io
        download(url, fp)
        cp(fp, localfile)
    end
end

Base.download(url::AbstractPath, localfile::AbstractPath) = cp(url, localfile)

"""
    readpath(fp::P) where {P <: AbstractPath} -> Vector{P}
"""
function readpath(p::P)::Vector{P} where P <: AbstractPath
    return P[join(p, f) for f in readdir(p)]
end

"""
    walkpath(fp::AbstractPath; topdown=true, follow_symlinks=false, onerror=throw)

Performs a depth first search through the directory structure
"""
function walkpath(fp::AbstractPath; topdown=true, follow_symlinks=false, onerror=throw)
    return Channel() do chnl
        for p in readpath(fp)
            topdown && put!(chnl, p)
            if isdir(p) && (follow_symlinks || !islink(p))
                # Iterate through children
                children = walkpath(
                    p; topdown=topdown, follow_symlinks=follow_symlinks, onerror=onerror
                )

                for c in children
                    put!(chnl, c)
                end
            end
            topdown || put!(chnl, p)
        end
    end
end

"""
  open(filename::AbstractPath; keywords...) -> FileBuffer
  open(filename::AbstractPath, mode="r) -> FileBuffer

Return a default FileBuffer for `open` calls to paths which only support `read` and `write`
methods. See base `open` docs for details on valid keywords.
"""
Base.open(fp::AbstractPath; kwargs...) = FileBuffer(fp; kwargs...)

function Base.open(fp::AbstractPath, mode)
    if mode == "r"
        return FileBuffer(fp; read=true, write=false)
    elseif mode == "w"
        return FileBuffer(fp; read=false, write=true, create=true, truncate=true)
    elseif mode == "a"
        return FileBuffer(fp; read=false, write=true, create=true, append=true)
    elseif mode == "r+"
        return FileBuffer(fp; read=true, writable=true)
    elseif mode == "w+"
        return FileBuffer(fp; read=true, write=true, create=true, truncate=true)
    elseif mode == "a+"
        return FileBuffer(fp; read=true, write=true, create=true, append=true)
    else
        throw(ArgumentError("$mode is not support for $(typeof(fp))"))
    end
end

# Default `touch` will just write an empty string to a file
Base.touch(fp::AbstractPath) = write(fp, "")

tmpname() = Path(tempname())
tmpdir() = Path(tempdir())

function mktmp(parent::AbstractPath)
    fp = parent / string(uuid4())
    # touch the file in case `open` isn't implement for the path and
    # we're buffering locally.
    touch(fp)
    io = open(fp, "w+")
    return fp, io
end

function mktmpdir(parent::AbstractPath)
    fp = parent / string(uuid4())
    mkdir(fp)
    return fp
end

function mktmp(fn::Function, parent=tmpdir())
    (tmp_fp, tmp_io) = mktmp(parent)
    try
        fn(tmp_fp, tmp_io)
    finally
        close(tmp_io)
        rm(tmp_fp)
    end
end

function mktmpdir(fn::Function, parent=tmpdir())
    tmpdir = mktmpdir(parent)
    try
        fn(tmpdir)
    finally
        rm(tmpdir, recursive=true)
    end
end

# ALIASES for base filesystem API
Base.dirname(fp::AbstractPath) = parent(fp)
Base.ispath(fp::AbstractPath) = exists(fp)
Base.realpath(fp::AbstractPath) = real(fp)
Base.normpath(fp::AbstractPath) = norm(fp)
Base.abspath(fp::AbstractPath) = abs(fp)
Base.relpath(fp::AbstractPath) = relative(fp)
Base.filemode(fp::AbstractPath) = mode(fp)
Base.isabspath(fp::AbstractPath) = isabs(fp)
Base.mkpath(fp::AbstractPath) = mkdir(fp; recursive=true)

# ALIASES for now old FilePaths API
move(src::AbstractPath, dest::AbstractPath; kwargs...) = mv(src, dest; kwargs...)
remove(fp::AbstractPath; kwargs...) = rm(fp; kwargs...)
