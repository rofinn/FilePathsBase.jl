

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

"""
    @__PATH__ -> SystemPath

@__PATH__ expands to a path with the directory part of the absolute path
of the file containing the macro. Returns an empty Path if run from a REPL or
if evaluated by julia -e <expr>.
"""
macro __PATH__()
    p = Path(dirname(string(__source__.file)))
    return p === nothing ? :(Path()) : :($p)
end

"""
    @__FILEPATH__ -> SystemPath

@__FILEPATH__ expands to a path with the absolute file path of the file
containing the macro. Returns an empty Path if run from a REPL or if
evaluated by julia -e <expr>.
"""
macro __FILEPATH__()
    p = Path(string(__source__.file))
    return p === nothing ? :(Path()) : :($p)
end

"""
    @LOCAL(filespec)

Construct an absolute path to `filespec` relative to the source file
containing the macro call.
"""
macro LOCAL(filespec)
    p = join(Path(dirname(string(__source__.file))), Path(filespec))
    return :($p)
end

# May want to support using the registry for other constructors as well
function Path(str::AbstractString; debug=false)
    result = nothing
    types = Vector{eltype(PATH_TYPES)}()

    for P in PATH_TYPES
        r = tryparse(P, str)

        # If we successfully parsed the path then save that result
        # and break if we aren't in debug mode, otherwise record how many
        if r !== nothing
            result = r
            if debug
                push!(types, P)
            else
                break
            end
        end
    end

    if length(types) > 1
        @debug(
            string(
                "Found multiple path types that match the string specified ($types). ",
                "Please use a specific `parse` method if $(first(types)) is not the correct type."
            )
        )
    elseif result === nothing
        throw(ArgumentError("Unable to parse $str as a path type."))
    else
        return result
    end
end

Path(fp::T, segments::Tuple{Vararg{String}}) where {T<:AbstractPath} = Path(T, fp, segments)

function Path(::Type{T}, fp::AbstractPath, segments::Tuple{Vararg{String}}) where T<:AbstractPath
    T((s === :segments ? segments : getfield(fp, s) for s in fieldnames(T))...)
end

function Path(::Type{T}, fp::AbstractPath, segments::Tuple{Vararg{String}}) where T<:RelativePath
    args = map(fieldnames(T)) do s
        if s === :segments
            return segments
        elseif s === :root
            return ""  # By default relative means the root is empty.
        else
            return getfield(fp, s)
        end
    end

    return T(args...)
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
function Base.print(io::IO, fp::FilePath)
    print(io, fp.anchor * join(fp.segments, fp.separator))
end

function Base.print(io::IO, fp::DirectoryPath)
    print(io, fp.anchor * join(fp.segments, fp.separator) * fp.separator)
end

function Base.show(io::IO, fp::AbstractPath)
    get(io, :compact, false) ? print(io, fp) : print(io, "p\"$fp\"")
end

function Base.parse(::Type{P}, str::AbstractString) where P<:AbstractPath
    result = tryparse(P, str)
    result === nothing && throw(ArgumentError("$str cannot be parsed as $P"))
    return result
end

Base.convert(::Type{<:AbstractPath}, x::AbstractString) = Path(x)
Base.convert(::Type{String}, x::AbstractPath) = string(x)
Base.promote_rule(::Type{String}, ::Type{<:AbstractPath}) = String
Base.isless(a::P, b::P) where P<:AbstractPath = isless(a.segments, b.segments)
Base.broadcastable(fp::AbstractPath) = Ref(fp)

# components(fp::AbstractPath) = tuple(drive(fp), root(fp), path(fp)...)

"""
    isrelative(fp::AbstractPath) -> Bool

Returns true if `fp.root` is empty, indicating that it is a relative path.
"""
isrelative(fp::AbstractPath) = isempty(fp.root)

"""
    isabsolute(fp::AbstractPath) -> Bool

Returns true if `fp.root` is not empty, indicating that it is an absolute path.
"""
isabsolute(fp::AbstractPath) = !isempty(fp.root)

# Support immutable indexing API
Base.getindex(fp::AbstractPath, idx) = fp.segments[idx]
Base.firstindex(::AbstractPath) = 1
Base.lastindex(fp::AbstractPath) = length(fp)

# Support iteration protocol
Base.eltype(::AbstractPath) = String
Base.length(fp::AbstractPath) = length(fp.segments)
Base.iterate(fp::AbstractPath, state=1) = iterate(fp.segments, state)

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
hasparent(fp::AbstractPath) = length(fp.segments) > isrelative(fp)

"""
    parent{T<:AbstractPath}(fp::T) -> T

Returns the parent of the supplied path. If no parent exists
then either "/" or "." will be returned depending on whether the path
is absolute.

# Example
```jldoctest
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
```jldoctest
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
function parents(fp::AbstractPath)
    # Return type should match the input, but We always want to produce directories
    T = fptype(fp){form(fp), Dir}

    if hasparent(fp)
        # Iterate from 1:n-1 or 0:n-1 for relative and absolute paths respectively.
        # (i.e., include fp.root when applicable)
        return [Path(T, fp, fp.segments[1:i]) for i in isrelative(fp):length(fp.segments) - 1]
    elseif fp.segments == tuple(".") || !isempty(fp.root)
        return [fp]
    else
        return [Path(T, fp, tuple("."))]
    end
end

"""
  *(a::T, b::Union{T, AbstractString, AbstractChar}...) where {T <: AbstractPath} -> T

Concatenate paths, strings and/or characters, producing a new path.
This is equivalent to concatenating the string representations of paths and other strings
and then constructing a new path.

# Example
```jldoctest
julia> p"foo" * "bar"
p"foobar"
```
"""
function Base.:(*)(a::AbstractPath, b::Union{AbstractPath, AbstractString, AbstractChar}...)
    parse(fptype(a), *(string(a), string.(b)...))
end

"""
  /(a::AbstractPath, b::Union{AbstractPath, AbstractString}...) -> AbstractPath

Join the path components into a new full path, equivalent to calling `joinpath`.

# Example
```jldoctest
julia> p"foo" / "bar"
p"foo/bar"

julia> p"foo" / "bar" / "baz"
p"foo/bar/baz"
```
"""
/(root::AbstractPath, pieces::Union{AbstractPath, AbstractString}...) = join(root, pieces...)

"""
    join(root::AbstractPath, pieces::Union{AbstractPath, AbstractString}...) -> AbstractPath

Joins path components into a full path.

# Example
```jldoctest
julia> join(p"~/.julia/v0.6", "REQUIRE")
p"~/.julia/v0.6/REQUIRE"
```
"""
function join(prefix::AbstractPath, pieces::RelativePath...)
    segments = String[prefix.segments...]

    for p in pieces
        push!(segments, p.segments...)
    end

    # Return type should be the source prefix path with the same form, but the kind should
    # match the last piece.
    T = fptype(prefix){form(prefix), kind(last(pieces))}
    return Path(T, prefix, tuple(segments...))
end

# Fallback for string pieces
join(prefix::AbstractPath, pieces::AbstractString...) = join(prefix, Path.(pieces)...)

# Fallback for incorrect path version, so we don't accidentally call `Base.join`
join(prefix::AbstractPath, args...) = throw(MethodError(join, (prefix, args...)))

function Base.splitext(fp::AbstractPath)
    new_fp, ext = splitext(string(fp))
    return (Path(new_fp), ext)
end

Base.basename(fp::AbstractPath) = fp.segments[end]

"""
    filename(fp::AbstractPath) -> AbstractString

Extracts the `basename` without the extension.

# Example
```jldoctest
julia> filename(p"~/repos/FilePathsBase.jl/src/FilePathsBase.jl")
"FilePathsBase"

julia> filename(p"~/Downloads/julia-1.4.0-linux-x86_64.tar.gz")
"julia-1.4.0-linux-x86_64.tar"
```
"""
filename(fp::AbstractPath) = rsplit(basename(fp), "."; limit=2)[1]

"""
    extension(fp::AbstractPath) -> AbstractString

Extracts the last extension from a filename if there any, otherwise it returns an empty string.

# Example
```jldoctest
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
```jldoctest
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

Base.expanduser(fp::AbstractPath) = fp

"""
    normalize(fp::AbstractPath) -> AbstractPath

normalizes a path by removing "." and ".." entries.
"""
function normalize(fp::T) where {T <: AbstractPath}
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
    absolute(fp::AbstractPath) -> AbstractPath

Creates an absolute path by adding the current working directory if necessary.
"""
function absolute(fp::AbstractPath)
    result = expanduser(fp)

    if isabsolute(result)
        return normalize(result)
    else
        return normalize(join(cwd(), result))
    end
end

"""
    relative{T<:AbstractPath}(fp::T, start::T=T("."))

Creates a relative path from either the current directory or an arbitrary start directory.
"""
function relative(fp::AbstractPath, start::AbstractPath)
    if fptype(fp) != fptype(start)
        throw(ArgumentError("$fp and $start must be of the same type."))
    end
    curdir = "."
    pardir = ".."

    p = absolute(fp).segments
    s = absolute(start).segments
    T = fptype(fp){Rel, kind(fp)}

    p == s && return parse(T, curdir)

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
    return isempty(relpath_) ? parse(T, curdir) : Path(T, fp, relpath_)
end

"""
    canonicalize(path::AbstractPath) -> AbstractPath

Canonicalize a path by making it absolute, `.` or `..` segments and resolving any symlinks
if applicable.

WARNING: Fallback behaviour ignores symlinks and should be extended for paths where
symlinks are permitted (e.g., `SystemPath`s).
"""
canonicalize(fp::AbstractPath) = normalize(absolute(fp))

Base.lstat(fp::AbstractPath) = stat(fp)

"""
    mode(fp::AbstractPath) -> Mode

Returns the `Mode` for the specified path.

# Example
```julia-repl
julia> mode(p"src/FilePathsBase.jl")
-rw-r--r--
```
"""
mode(fp::AbstractPath) = stat(fp).mode
Base.filesize(fp::AbstractPath) = stat(fp).size

"""
    modified(fp::AbstractPath) -> DateTime

Returns the last modified date for the `path`.

# Example
```julia-repl
julia> modified(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
modified(fp::AbstractPath) = stat(fp).mtime

"""
    created(fp::AbstractPath) -> DateTime

Returns the creation date for the `path`.

# Example
```julia-repl
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
    exists(src) || throw(ArgumentError("Source path does not exist: $src"))

    if exists(dst)
        if force
            rm(dst; force=force, recursive=true)
        else
            throw(ArgumentError("Destination already exists: $dst"))
        end
    end

    return _cp(src, dst)
end

# Internal `_cp` calls don't need to do existence checks and can dispatch by dir or file.
_cp(src::FilePath, dst::FilePath) = write(dst, read(src))

function _cp(src::DirectoryPath, dst::DirectoryPath)
    mkdir(dst)

    for fp in readdir(src)
        _cp(src / fp, dst / fp)
    end
end

# Handle some failure cases.
_cp(src::FilePath, dst::DirectoryPath) = throw(ArgumentError("$dst is not a FilePath."))
_cp(src::DirectoryPath, dst::FilePath) = throw(ArgumentError("$dst is not a DirectoryPath."))
_cp(src::AbstractPath, dst::AbstractPath) = throw(ArgumentError("$src is not a file or directory."))

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

function sync(f::Function, src::AbstractPath, dst::AbstractPath; kwargs...)
    # Throw an error if the source path doesn't exist at all
    exists(src) || throw(ArgumentError("$src does not exist"))
    return _sync(f, src, dst; kwargs...)
end

# If the top level source is just a file then try to just sync that
# without calling walkpath
function _sync(f::Function, src::FilePath, dst::FilePath; delete=false, overwrite=true)
    # If the destination exists then we should make sure it is a file and check
    # if we should copy the source over.
    if exists(dst)
        if overwrite && f(src, dst)
            cp(src, dst; force=true)
        end
    else
        cp(src, dst)
    end
end

function _sync(f::Function, src::DirectoryPath, dst::DirectoryPath; delete=false, overwrite=true)
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
            # The resulting copy type should match the original dst, but match the src `Kind`.
            T = fptype(dst){form(dst), kind(src)}
            cp(src_paths[i], Path(T, dst, tuple(dst.segments..., seg...)); force=true)
        end
    else
        cp(src, dst)
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

Download a file from the remote `url` and save it to the `localfile` path.

NOTE: Not downloading into a `localfile` directory matches the base Julia behaviour.
https://github.com/rofinn/FilePathsBase.jl/issues/48
"""
function Base.download(url::AbstractString, localfile::P) where P <: AbstractPath
    mktemp(P) do fp, io
        download(url, fp)
        cp(fp, localfile; force=false)
    end
end

Base.download(url::AbstractPath, localfile::AbstractPath) = cp(url, localfile; force=true)

function Base.download(url::AbstractPath, localfile::AbstractString)
    download(url, Path(localfile))
    return localfile
end

"""
    readpath(fp::AbstractPath) -> Vector{AbstractPath}
"""
readpath(p::AbstractPath)  = p ./ readdir(p)

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
  open(filename::FilePath; keywords...) -> FileBuffer
  open(filename::FilePath, mode="r) -> FileBuffer

Return a default FileBuffer for `open` calls to paths which only support `read` and `write`
methods. See base `open` docs for details on valid keywords.0
"""
Base.open(fp::FilePath; kwargs...) = FileBuffer(fp; kwargs...)

function Base.open(fp::FilePath, mode)
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


# Fallback read write methods
Base.read(fp::FilePath, ::Type{T}) where {T} = open(io -> read(io, T), fp)
Base.write(fp::FilePath, x) = open(io -> write(io, x), fp, "w")

# Default `touch` will just write an empty string to a file
Base.touch(fp::FilePath) = write(fp, "")

Base.tempname(::Type{<:AbstractPath}) = Path(tempname())
tmpname() = tempname(SystemPath)

Base.tempdir(::Type{<:AbstractPath}) = Path(tempdir())
tmpdir() = tempdir(SystemPath)

Base.mktemp(P::Type{<:AbstractPath}) = mktemp(tempdir(P))
mktmp() = mktemp(SystemPath)

Base.mktemp(fn::Function, P::Type{<:AbstractPath}) = mktemp(fn, tempdir(P))
mktmp(fn::Function) = mktemp(fn, SystemPath)

Base.mktempdir(P::Type{<:AbstractPath}) = mktempdir(tempdir(P))
mktmpdir() = mktempdir(SystemPath)

Base.mktempdir(fn::Function, P::Type{<:AbstractPath}) = mktempdir(fn, tempdir(P))
mktmpdir(fn::Function) = mktempdir(fn, SystemPath)

function Base.mktemp(parent::AbstractPath)
    fp = parent / string(uuid4())
    # touch the file in case `open` isn't implement for the path and
    # we're buffering locally.
    touch(fp)
    io = open(fp, "w+")
    return fp, io
end

function Base.mktempdir(parent::AbstractPath)
    fp = parent / string(uuid4())
    mkdir(fp)
    return fp
end

function Base.mktemp(fn::Function, parent::AbstractPath)
    (tmp_fp, tmp_io) = mktmp(parent)
    try
        fn(tmp_fp, tmp_io)
    finally
        close(tmp_io)
        rm(tmp_fp)
    end
end

function Base.mktempdir(fn::Function, parent::AbstractPath)
    tmpdir = mktmpdir(parent)
    try
        fn(tmpdir)
    finally
        rm(tmpdir, recursive=true)
    end
end

mktmp(arg1, args...) = mktemp(arg1, args...)
mktmpdir(arg1, args...) = mktempdir(arg1, args...)

"""
	isdescendant(fp::P, asc::P) where {P <: AbstractPath} -> Bool

Returns `true` if `fp` is within the directory tree of the `asc`.
"""
isdescendant(fp::P, asc::P) where {P <: AbstractPath} = fp == asc || asc in parents(fp)

"""
	isascendant(fp::P, desc::P) where {P <: AbstractPath} -> Bool

Returns `true` if `fp` is a directory containing `desc`.
"""
isascendant(fp::P, desc::P) where {P <: AbstractPath} = isdescendant(desc, fp)
