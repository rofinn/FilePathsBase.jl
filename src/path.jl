

"""
    Path() -> SystemPath
    Path(fp::Tuple) -> SystemPath
    Path(fp::P) where P <: AbstractPath) -> P
    Path(fp::AbstractString) -> AbstractPath
    Path(fp::P, segments::Tuple) -> P

Responsible for creating the appropriate platform specific path
(e.g., [PosixPath](@ref) and [WindowsPath`](@ref) for Unix and
Windows systems respectively)

NOTE: `Path(::AbstractString)` can also work for custom paths if
[ispathtype](@ref) is defined for that type.
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

function Path(fp::T, segments::Tuple{Vararg{String}}) where T <: AbstractPath
    T((s === :segments ? segments : getfield(fp, s) for s in fieldnames(T))...)
end

"""
    @p_str -> Path

Constructs a [Path](@path) (platform specific subtype of [AbstractPath](@ref)),
such as `p"~/.juliarc.jl"`.
"""
macro p_str(fp)
    return :(Path($fp))
end

function Base.getproperty(fp::T, attr::Symbol) where T <: AbstractPath
    if isdefined(fp, attr)
        return getfield(fp, attr)
    elseif attr === :drive
        return ""
    elseif attr === :root
        return POSIX_PATH_SEPARATOR
    elseif attr === :anchor
        return fp.drive * fp.root
    elseif attr === :separator
        return POSIX_PATH_SEPARATOR
    else
        # Call getfield even though we know it'll error
        # so the message is consistent.
        return getfield(fp, attr)
    end
end

#=
We only want to print the macro string syntax when compact is true and
we want print to just return the string (this allows `string` to work normally)
=#
function Base.print(io::IO, fp::AbstractPath)
    print(io, fp.anchor * join(fp.segments, fp.separator))
end

function Base.show(io::IO, fp::AbstractPath)
    get(io, :compact, false) ? print(io, fp) : print(io, "p\"$fp\"")
end

Base.parse(::Type{<:AbstractPath}, x::AbstractString) = Path(x)
Base.convert(::Type{<:AbstractPath}, x::AbstractString) = Path(x)
Base.convert(::Type{String}, x::AbstractPath) = string(x)
Base.promote_rule(::Type{String}, ::Type{<:AbstractPath}) = String
Base.isless(a::P, b::P) where P<:AbstractPath = isless(a.segments, b.segments)

"""
      cwd() -> SystemPath

Get the current working directory.

# Examples
```
julia> cwd()
p"/home/JuliaUser"

julia> cd(p"/home/JuliaUser/Projects/julia")

julia> cwd()
p"/home/JuliaUser/Projects/julia"
```
"""
cwd() = Path(pwd())
home() = Path(homedir())
Base.expanduser(fp::AbstractPath) = fp

# components(fp::AbstractPath) = tuple(drive(fp), root(fp), path(fp)...)

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
hasparent(fp::AbstractPath) = length(fp.segments) > 1

"""
    parent{T<:AbstractPath}(fp::T) -> T

Returns the parent of the supplied path. If no parent exists
then either "/" or "." will be returned depending on whether the path
is absolute.

# Example
```
julia> parent(p"~/.julia/v0.6/REQUIRE")
p"~/.julia/v0.6"

julia> parent(p"/etc")
p"/"

julia> parent(p"etc")
p"."

julia> parent(p".")
p"."
```
"""
Base.parent(fp::AbstractPath) = parents(fp)[end]

"""
    parents{T<:AbstractPath}(fp::T) -> Array{T}

Return all parents of the path. If no parent exists then either "/" or "."
will be returned depending on whether the path is absolute.

# Example
```
julia> parents(p"~/.julia/v0.6/REQUIRE")
3-element Array{FilePathsBase.PosixPath,1}:
 p"~"
 p"~/.julia"
 p"~/.julia/v0.6"

julia> parents(p"/etc")
1-element Array{PosixPath,1}:
 p"/"

julia> parents(p"etc")
1-element Array{PosixPath,1}:
 p"."

julia> parents(p".")
1-element Array{PosixPath,1}:
 p"."
 ```
"""
function parents(fp::T) where {T <: AbstractPath}
    if hasparent(fp)
        return [Path(fp, fp.segments[1:i]) for i in 1:length(fp.segments)-1]
    elseif fp.segments == tuple(".") || isempty(fp.segments)
        return [fp]
    else
        return [isempty(fp.root) ? Path(fp, tuple(".")) : Path(fp, ())]
    end
end

"""
  *(a::T, b::Union{T, AbstractString, AbstractChar}...) where {T <: AbstractPath} -> T

Concatenate paths, strings and/or characters, producing a new path.
This is equivalent to concatenating the string representations of paths and other strings
and then constructing a new path.

# Example
```
julia> p"foo" * "bar"
p"foobar"
```
"""
function Base.:(*)(a::T, b::Union{T, AbstractString, AbstractChar}...) where T <: AbstractPath
    T(*(string(a), string.(b)...))
end

"""
  /(a::AbstractPath, b::Union{AbstractPath, AbstractString}...) -> AbstractPath

Join the path components into a new fulll path, equivalent to calling `joinpath`

# Example
```
julia> p"foo" / "bar"
p"foo/bar"

julia> p"foo" / "bar" / "baz"
p"foo/bar/baz"
```
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
    segments = String[prefix.segments...]

    for p in pieces
        if isa(p, AbstractPath)
            push!(segments, p.segments...)
        else
            push!(segments, Path(p).segments...)
        end
    end

    return Path(prefix, tuple(segments...))
end

function Base.joinpath(root::AbstractPath, pieces::Union{AbstractPath, AbstractString}...)
    return join(root, pieces...)
end

Base.basename(fp::AbstractPath) = fp.segments[end]

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
Base.isempty(fp::AbstractPath) = isempty(fp.segments)

"""
    norm(fp::AbstractPath) -> AbstractPath

Normalizes a path by removing "." and ".." entries.
"""
function LinearAlgebra.norm(fp::T) where {T <: AbstractPath}
    p = fp.segments
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

    return Path(fp, tuple(fill("..", del)..., reverse(result)...))
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
    return !isempty(fp.drive) && !isempty(fp.root)
end

"""
    relative{T<:AbstractPath}(fp::T, start::T=T("."))

Creates a relative path from either the current directory or an arbitrary start directory.
"""
function relative(fp::T, start::T=T(".")) where {T <: AbstractPath}
    curdir = "."
    pardir = ".."

    p = abs(fp).segments
    s = abs(start).segments

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
        relpath_ = tuple(pathpart...)
    end
    return isempty(relpath_) ? T(curdir) : Path(fp, relpath_)
end

"""
    real(path::AbstractPath) -> AbstractPath

Canonicalize a path by expanding symbolic links and removing "." and ".." entries.
"""
Base.real(fp::AbstractPath) = fp

Base.read(fp::AbstractPath, ::Type{String}) = String(read(fp))

Base.lstat(fp::AbstractPath) = stat(fp)

"""
    mode(fp::AbstractPath) -> Mode

Returns the `Mode` for the specified path.

# Example
```
julia> mode(p"src/FilePathsBase.jl")
-rw-r--r--
```
"""
mode(fp::AbstractPath) = stat(fp).mode
Base.size(fp::AbstractPath) = stat(fp).size

"""
    modified(fp::AbstractPath) -> DateTime

Returns the last modified date for the `path`.

# Example
```
julia> modified(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
modified(fp::AbstractPath) = stat(fp).mtime

"""
    created(fp::AbstractPath) -> DateTime

Returns the creation date for the `path`.

# Example
```
julia> created(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
created(fp::AbstractPath) = stat(fp).ctime
Base.isdir(fp::AbstractPath) = isdir(mode(fp))
Base.isfile(fp::AbstractPath) = isfile(mode(fp))
Base.islink(fp::AbstractPath) = islink(lstat(fp).mode)
Base.issocket(fp::AbstractPath) = issocket(mode(fp))
Base.isfifo(fp::AbstractPath) = issocket(mode(fp))
Base.ischardev(fp::AbstractPath) = ischardev(mode(fp))
Base.isblockdev(fp::AbstractPath) = isblockdev(mode(fp))

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
    sync([f::Function,] src::AbstractPath, dst::AbstractPath; delete=false, overwrite=true)

Recursively copy new and updated files from the source path to the destination.
If delete is true then files at the destination that don't exist at the source will be removed.
By default, source files are sent to the destination if they have different sizes or the source has newer
last modified date.

Optionally, you can specify a function `f` which will take a `src` and `dst` path and return
true if the `src` should be sent. This may be useful if you'd like to use a checksum for
comparison.
"""
function sync(src::AbstractPath, dst::AbstractPath; kwargs...)
    sync(should_sync, src, dst; kwargs...)
end

function sync(f::Function, src::AbstractPath, dst::AbstractPath; delete=false, overwrite=true)
    # Throw an error if the source path doesn't exist at all
    exists(src) || throw(ArgumentError("$src does not exist"))

    # If the top level source is just a file then try to just sync that
    # without calling walkpath
    if isfile(src)
        # If the destination exists then we should make sure it is a file and check
        # if we should copy the source over.
        if exists(dst)
            isfile(dst) || throw(ArgumentError("$dst is not a file"))
            if overwrite && f(src, dst)
                cp(src, dst; force=true)
            end
        else
            cp(src, dst)
        end
    else
        isdir(src) || throw(ArgumentError("$src is neither a file or directory."))
        if exists(dst) && !isdir(dst)
            throw(ArgumentError("$dst is not a directory while $src is"))
        end

        # Create an index of all of the source files
        src_paths = collect(walkpath(src))
        index = Dict(
            Tuple(setdiff(p.segments, src.segments)) => i for (i, p) in enumerate(src_paths)
        )

        if exists(dst)
            for p in walkpath(dst)
                k = Tuple(setdiff(p.segments, dst.segments))

                if haskey(index, k)
                    src_path = src_paths[index[k]]
                    if overwrite && f(src_path, p)
                        cp(src_path, p; force=true)
                    end

                    delete!(index, k)
                elseif delete
                    rm(p; recursive=true)
                end
            end

            # Finally, copy over files that don't exist at the destination
            # But we need to iterate through it in a way that respects the original
            # walkpath order otherwise we may end up trying to copy a file before its parents.
            index_pairs = collect(pairs(index))
            index_pairs = index_pairs[sortperm(last.(index_pairs))]
            for (seg, i) in index_pairs
                cp(src_paths[i], Path(dst, tuple(dst.segments..., seg...)); force=true)
            end
        else
            cp(src, dst)
        end
    end
end

function should_sync(src::AbstractPath, dst::AbstractPath)
    src_stat = stat(src)
    dst_stat = stat(dst)

    if src_stat.size != dst_stat.size || src_stat.mtime > dst_stat.mtime
        @debug(
            "syncing: $src -> $dst, " *
            "size: $(src_stat.size) -> $(dst_stat.size), " *
            "modified_time: $(src_stat.mtime) -> $(dst_stat.mtime)"
        )
        return true
    else
        return false
    end
end

"""
    download(url::Union{AbstractString, AbstractPath}, localfile::AbstractPath)

Download a file from the remote url and save it to the localfile path.
"""
function Base.download(url::AbstractString, localfile::AbstractPath)
    mktmp() do fp, io
        download(url, fp)
        cp(fp, localfile; force=true)
    end
end

Base.download(url::AbstractPath, localfile::AbstractPath) = cp(url, localfile; force=true)

function Base.download(url::AbstractPath, localfile::AbstractString)
    download(url, Path(localfile))
    return localfile
end

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
