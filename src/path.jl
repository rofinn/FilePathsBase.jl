"""
    Path()
    Path(path::AbstractPath)
    Path(path::Tuple)
    Path(path::AbstractString)

Responsible for creating the appropriate platform specific path
(e.g., `PosixPath` and `WindowsPath` for Unix and Windows systems respectively)
"""
Path() = @static Sys.isunix() ? PosixPath() : WindowsPath()
Path(path::AbstractPath) = path
Path(pieces::Tuple{Vararg{String}}) =
    @static Sys.isunix() ? PosixPath(pieces) : WindowsPath(pieces)

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

cwd() = Path(pwd())
home() = Path(homedir())

anchor(path::AbstractPath) = drive(path) * root(path)

"""
    @__PATH__ -> AbstractPath

@__PATH__ expands to a path with the directory part of the absolute path
of the file containing the macro. Returns an empty Path if run from a REPL or
if evaluated by julia -e <expr>.
"""
macro __PATH__()
    p = Path(dirname(string(__source__.file)))
    return p === nothing ? :(Path()) : :($p)
end

"""
    @__FILEPATH__ -> AbstractPath

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
    exists(path::AbstractPath) -> Bool

Returns whether the path actually exists on the system.
"""
exists(path::AbstractPath) = ispath(string(path))

"""
    real(path::AbstractPath) -> AbstractPath

Canonicalizes a path by expanding symlinks and removing "." and ".." entries.
"""
Base.real(path::AbstractPath) = Path(realpath(string(path)))

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
        str = p[end-count]

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

    pathpart = p[i+1:findlast(x -> !isempty(x), p)]
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

#=
The following a descriptive methods for paths
built around stat
=#
Base.stat(path::AbstractPath) = Status(stat(string(path)))
Base.lstat(path::AbstractPath) = Status(lstat(string(path)))

"""
    mode(path::AbstractPath) -> Mode

Returns the `Mode` for the specified path.

# Example
```
julia> mode(p"src/FilePathsBase.jl")
-rw-r--r--
```
"""
mode(path::AbstractPath) = stat(path).mode
Base.size(path::AbstractPath) = stat(path).size

"""
    modified(path::AbstractPath) -> DateTime

Returns the last modified date for the `path`.

# Example
```
julia> modified(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
modified(path::AbstractPath) = stat(path).mtime

"""
    created(path::AbstractPath) -> DateTime

Returns the creation date for the `path`.

# Example
```
julia> created(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
created(path::AbstractPath) = stat(path).ctime
Base.isdir(path::AbstractPath) = isdir(mode(path))
Base.isfile(path::AbstractPath) = isfile(mode(path))
Base.islink(path::AbstractPath) = islink(lstat(path).mode)
Base.issocket(path::AbstractPath) = issocket(mode(path))
Base.isfifo(path::AbstractPath) = issocket(mode(path))
Base.ischardev(path::AbstractPath) = ischardev(mode(path))
Base.isblockdev(path::AbstractPath) = isblockdev(mode(path))

"""
    isexecutable(path::AbstractPath) -> Bool

Returns whether the `path` is executable for the current user.
"""
function isexecutable(path::AbstractPath)
    s = stat(path)
    usr = User()

    return isexecutable(s.mode, :ALL) || isexecutable(s.mode, :OTHER) ||
        ( usr.uid == s.user.uid && isexecutable(s.mode, :USER) ) ||
        ( usr.gid == s.group.gid && isexecutable(s.mode, :GROUP) )
end

"""
    iswritable(path::AbstractPath) -> Bool

Returns whether the `path` is writable for the current user.
"""
function Base.iswritable(path::AbstractPath)
    s = stat(path)
    usr = User()

    return iswritable(s.mode, :ALL) || iswritable(s.mode, :OTHER) ||
        ( usr.uid == s.user.uid && iswritable(s.mode, :USER) ) ||
        ( usr.gid == s.group.gid && iswritable(s.mode, :GROUP) )
end

"""
    isreadable(path::AbstractPath) -> Bool

Returns whether the `path` is readable for the current user.
"""
function Base.isreadable(path::AbstractPath)
    s = stat(path)
    usr = User()

    return isreadable(s.mode, :ALL) || isreadable(s.mode, :OTHER) ||
        ( usr.uid == s.user.uid && isreadable(s.mode, :USER) ) ||
        ( usr.gid == s.group.gid && isreadable(s.mode, :GROUP) )
end

function Base.ismount(path::AbstractPath)
    isdir(path) || return false
    s1 = lstat(path)
    # Symbolic links cannot be mount points
    islink(s1) && return false
    s2 = lstat(parent(path))
    # If a directory and its parent are on different devices,  then the
    # directory must be a mount point
    (s1.device != s2.device) && return true
    (s1.inode == s2.inode) && return true
    false
end

#=
Path Operations
===============================================
The following are methods for actually manipulating the
filesystem.

NOTE: Currently, we are just wrapping base julia functions,
but in the future we'll likely be handling platform specific
code in the implementation instances.

TODO: Document these once we're comfortable with them.
=#

Base.cd(path::AbstractPath) = cd(string(path))
function Base.cd(fn::Function, dir::AbstractPath)
    old = cwd()
    try
        cd(dir)
        fn()
   finally
        cd(old)
    end
end

function Base.mkdir(path::AbstractPath; mode=0o777, recursive=false, exist_ok=false)
    if exists(path)
        !exist_ok && error("$path already exists.")
    else
        if hasparent(path) && !exists(parent(path))
			if recursive
				mkdir(parent(path); mode=mode, recursive=recursive, exist_ok=exist_ok)
			else
				error(
					"The parent of $path does not exist. " *
					"Pass recursive=true to create it."
				)
			end
        end

		mkdir(string(path), mode=mode)
    end
end

function Base.symlink(src::AbstractPath, dest::AbstractPath; exist_ok=false, overwrite=false)
    if exists(src)
        if exists(dest) && exist_ok && overwrite
            remove(dest, recursive=true)
        end

        if !exists(dest)
            symlink(string(src), string(dest))
        elseif !exist_ok
            error("$dest already exists.")
        end
    else
        error("$src is not a valid path")
    end
end


function Base.copy(src::AbstractPath, dest::AbstractPath; recursive=false, exist_ok=false, overwrite=false, symlinks=false)
    if exists(src)
        if exists(dest) && exist_ok && overwrite
            remove(dest, recursive=true)
        end

        if !exists(dest)
            if hasparent(dest) && recursive
                mkdir(parent(dest); recursive=recursive, exist_ok=true)
            end

            cp(src, dest; follow_symlinks=symlinks)
        elseif !exist_ok
            error("$dest already exists.")
        end
    else
        error("$src is not a valid path")
    end
end

function move(src::AbstractPath, dest::AbstractPath; recursive=false, exist_ok=false, overwrite=false)
    if exists(src)
        if exists(dest) && exist_ok && overwrite
            remove(dest, recursive=true)
        end

        if !exists(dest)
            # If the destination is has missing parents
            # and parents is true then we'll create the necessary parent
            # directories.
            if hasparent(dest) && recursive
                mkdir(parent(dest); recursive=recursive, exist_ok=true)
            end

            mv(string(src), string(dest))
        elseif !exist_ok
            error("$dest already exists.")
        end
    else
        error("$src is not a valid path")
    end
end

function Base.cp(src::AbstractPath, dest::AbstractPath; force::Bool=false, follow_symlinks::Bool=false)
    cp(string(src), string(dest); force=force, follow_symlinks=follow_symlinks)
end

remove(path::AbstractPath; recursive=false) = rm(string(path); recursive=recursive)
Base.touch(path::AbstractPath) = touch(string(path))

tmpname() = Path(tempname())
tmpdir() = Path(tempdir())

function mktmp(parent::AbstractPath=Path(tempdir()))
    path, io = mktemp(string(parent))
    return Path(path), io
end

mktmpdir(parent::AbstractPath=tmpdir()) = Path(mktempdir(string(parent)))

function mktmp(fn::Function, parent=tmpdir())
    (tmp_path, tmp_io) = mktmp(parent)
    try
        fn(tmp_path, tmp_io)
    finally
        close(tmp_io)
        remove(tmp_path)
    end
end

function mktmpdir(fn::Function, parent=tmpdir())
    tmpdir = mktmpdir(parent)
    try
        fn(tmpdir)
    finally
        remove(tmpdir, recursive=true)
    end
end

"""
    chown(path::AbstractPath, user::AbstractString, group::AbstractString; recursive=false)

Change the `user` and `group` of the `path`.
"""
function Base.chown(path::AbstractPath, user::AbstractString, group::AbstractString; recursive=false)
    @static if Sys.isunix()
        chown_cmd = String["chown"]
        if recursive
            push!(chown_cmd, "-R")
        end
        append!(chown_cmd, String["$(user):$(group)", string(path)])

        run(Cmd(chown_cmd))
    else
        error("chown is currently not supported on windows.")
    end
end

"""
    chmod(path::AbstractPath, mode::Mode; recursive=false)
    chmod(path::AbstractPath, mode::Integer; recursive=false)
    chmod(path::AbstractPath, user::UIn8=0o0, group::UInt8=0o0, other::UInt8=0o0; recursive=false)
    chmod(path::AbstractPath, symbolic_mode::AbstractString; recursive=false)

Provides various methods for changing the `mode` of a `path`.

# Examples
```
julia> touch(p"newfile")
Base.Filesystem.File(false, RawFD(-1))

julia> mode(p"newfile")
-rw-r--r--

julia> chmod(p"newfile", 0o755)

julia> mode(p"newfile")
-rwxr-xr-x

julia> chmod(p"newfile", "-x")

julia> mode(p"newfile")
-rw-r--r--

julia> chmod(p"newfile", user=(READ+WRITE+EXEC), group=(READ+EXEC), other=READ)

julia> mode(p"newfile")
-rwxr-xr--

julia> chmod(p"newfile", mode(p"src/FilePathsBase.jl"))

julia> mode(p"newfile")
-rw-r--r--
```
"""
function Base.chmod(path::AbstractPath, mode::Mode; recursive=false)
    chmod_path = string(path)
    chmod_mode = raw(mode)

    if isdir(path) && recursive
        for p in readdir(path)
            chmod(chmod_path, chmod_mode; recursive=recursive)
        end
    end

    chmod(chmod_path, chmod_mode)
end

function Base.chmod(path::AbstractPath, mode::Integer; recursive=false)
    chmod(path, Mode(mode); recursive=recursive)
end

function Base.chmod(path::AbstractPath; user::UInt8=0o0, group::UInt8=0o0, other::UInt8=0o0, recursive=false)
    chmod(path, Mode(user=user, group=group, other=other); recursive=recursive)
end

function Base.chmod(path::AbstractPath, symbolic_mode::AbstractString; recursive=false)
    who_char = ['u', 'g', 'o']
    who_actual = [:USER, :GROUP, :OTHER]
    act_char = ['+', '-', '=']
    perm_char = ['r', 'w', 'x']
    perm_actual = [READ, WRITE, EXEC]
    unsupported_perm_char = ['s', 't', 'X', 'u', 'g', 'o']

    tokenized = split(symbolic_mode, act_char)
    if length(tokenized) != 2
        error("Invalid symbolic string expected format <who><action><perm>.")
    end

    who_raw = tokenized[1]
    perm_raw = tokenized[2]

    who = [:ALL]
    perm = 0o0

    for i in 1:3
        if who_char[i] in who_raw
            push!(who, who_actual[i])
        end
    end

    for i in 1:3
        if perm_char[i] in perm_raw
            perm += perm_actual[i]
        end
    end

    for x in unsupported_perm_char
        if x in perm_raw
            error("$x is currently an unsupported permission char for symbolic modes.")
        end
    end

    m = mode(path)
    new_m = Mode(perm, who...)

    if '+' in symbolic_mode
        chmod(path, m + new_m; recursive=recursive)
    elseif '-' in symbolic_mode
        chmod(path, m - new_m; recursive=recursive)
    elseif '=' in symbolic_mode
        chmod(path, new_m; recursive=recursive)
    else
        error("No valid action found in symbolic mode string.")
    end
end

Base.open(path::AbstractPath, args...) = open(string(path), args...)
function Base.open(f::Function, path::AbstractPath, args...; kwargs...)
    open(f, string(path), args...; kwargs...)
end

Base.read(path::AbstractPath, args...) = read(string(path), args...)
function Base.write(path::AbstractPath, x::Union{String, Vector{UInt8}}, mode="w")
    open(path, mode) do f
        write(f, x)
    end
end

Base.readlink(path::AbstractPath) = Path(readlink(string(path)))
Base.readdir(path::AbstractPath) = map(Path, readdir(string(path)))

function Base.download(src::AbstractString, dest::AbstractPath, overwrite::Bool=false)
    if !exists(dest) || overwrite
        download(src, string(dest))
    end
    return dest
end
