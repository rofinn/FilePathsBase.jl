"""
    OSPath

A union of `PosixPath` and `WindowsPath` which is used for writing
methods that wrap base functionality.
"""
const OSPath = Union{PosixPath, WindowsPath}

Path() = @static Sys.isunix() ? PosixPath() : WindowsPath()
Path(pieces::Tuple{Vararg{String}}) =
    @static Sys.isunix() ? PosixPath(pieces) : WindowsPath(pieces)

"""
    @__PATH__ -> OSPath

@__PATH__ expands to a path with the directory part of the absolute path
of the file containing the macro. Returns an empty Path if run from a REPL or
if evaluated by julia -e <expr>.
"""
macro __PATH__()
    p = Path(dirname(string(__source__.file)))
    return p === nothing ? :(Path()) : :($p)
end

"""
    @__FILEPATH__ -> OSPath

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

exists(path::OSPath) = ispath(string(path))
Base.real(path::P) where {P <: OSPath} = P(realpath(string(path)))

#=
The following a descriptive methods for paths
built around stat
=#
Base.stat(path::OSPath) = Status(stat(string(path)))
Base.lstat(path::OSPath) = Status(lstat(string(path)))

"""
    mode(path::OSPath) -> Mode

Returns the `Mode` for the specified path.

# Example
```
julia> mode(p"src/FilePathsBase.jl")
-rw-r--r--
```
"""
mode(path::OSPath) = stat(path).mode
Base.size(path::OSPath) = stat(path).size

"""
    modified(path::OSPath) -> DateTime

Returns the last modified date for the `path`.

# Example
```
julia> modified(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
modified(path::OSPath) = stat(path).mtime

"""
    created(path::OSPath) -> DateTime

Returns the creation date for the `path`.

# Example
```
julia> created(p"src/FilePathsBase.jl")
2017-06-20T04:01:09
```
"""
created(path::OSPath) = stat(path).ctime
Base.isdir(path::OSPath) = isdir(mode(path))
Base.isfile(path::OSPath) = isfile(mode(path))
Base.islink(path::OSPath) = islink(lstat(path).mode)
Base.issocket(path::OSPath) = issocket(mode(path))
Base.isfifo(path::OSPath) = issocket(mode(path))
Base.ischardev(path::OSPath) = ischardev(mode(path))
Base.isblockdev(path::OSPath) = isblockdev(mode(path))

"""
    isexecutable(path::OSPath) -> Bool

Returns whether the `path` is executable for the current user.
"""
function isexecutable(path::OSPath)
    s = stat(path)
    usr = User()

    return (
        isexecutable(s.mode, :ALL) ||
        isexecutable(s.mode, :OTHER) ||
        ( usr.uid == s.user.uid && isexecutable(s.mode, :USER) ) ||
        ( usr.gid == s.group.gid && isexecutable(s.mode, :GROUP) )
    )
end

"""
    iswritable(path::AbstractPath) -> Bool

Returns whether the `path` is writable for the current user.
"""
function Base.iswritable(path::OSPath)
    s = stat(path)
    usr = User()

    return (
        iswritable(s.mode, :ALL) ||
        iswritable(s.mode, :OTHER) ||
        ( usr.uid == s.user.uid && iswritable(s.mode, :USER) ) ||
        ( usr.gid == s.group.gid && iswritable(s.mode, :GROUP) )
    )
end

"""
    isreadable(path::OSPath) -> Bool

Returns whether the `path` is readable for the current user.
"""
function Base.isreadable(path::OSPath)
    s = stat(path)
    usr = User()

    return (
        isreadable(s.mode, :ALL) ||
        isreadable(s.mode, :OTHER) ||
        ( usr.uid == s.user.uid && isreadable(s.mode, :USER) ) ||
        ( usr.gid == s.group.gid && isreadable(s.mode, :GROUP) )
    )
end

function Base.ismount(path::OSPath)
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

Base.cd(path::OSPath) = cd(string(path))
function Base.cd(fn::Function, dir::OSPath)
    old = cwd()
    try
        cd(dir)
        fn()
   finally
        cd(old)
    end
end

function Base.mkdir(path::OSPath; mode=0o777, recursive=false, exist_ok=false)
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

function Base.symlink(src::OSPath, dest::OSPath; exist_ok=false, overwrite=false)
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


function Base.copy(src::OSPath, dest::OSPath; recursive=false, exist_ok=false, overwrite=false, symlinks=false)
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

function move(src::OSPath, dest::OSPath; recursive=false, exist_ok=false, overwrite=false)
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

Base.rm(path::OSPath; kwargs...) = rm(string(path); kwargs...)
Base.touch(path::OSPath) = touch(string(path))

tmpname() = Path(tempname())
tmpdir() = Path(tempdir())

function mktmp(parent::OSPath=Path(tempdir()))
    path, io = mktemp(string(parent))
    return Path(path), io
end

mktmpdir(parent::OSPath=tmpdir()) = Path(mktempdir(string(parent)))

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
    chown(path::OSPath, user::AbstractString, group::AbstractString; recursive=false)

Change the `user` and `group` of the `path`.
"""
function Base.chown(path::OSPath, user::AbstractString, group::AbstractString; recursive=false)
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
    chmod(path::OSPath, mode::Mode; recursive=false)
    chmod(path::OSPath, mode::Integer; recursive=false)
    chmod(path::OSPath, user::UIn8=0o0, group::UInt8=0o0, other::UInt8=0o0; recursive=false)
    chmod(path::OSPath, symbolic_mode::AbstractString; recursive=false)

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
function Base.chmod(path::OSPath, mode::Mode; recursive=false)
    chmod_path = string(path)
    chmod_mode = raw(mode)

    if isdir(path) && recursive
        for p in readdir(path)
            chmod(chmod_path, chmod_mode; recursive=recursive)
        end
    end

    chmod(chmod_path, chmod_mode)
end

function Base.chmod(path::OSPath, mode::Integer; recursive=false)
    chmod(path, Mode(mode); recursive=recursive)
end

function Base.chmod(path::OSPath; user::UInt8=0o0, group::UInt8=0o0, other::UInt8=0o0, recursive=false)
    chmod(path, Mode(user=user, group=group, other=other); recursive=recursive)
end

function Base.chmod(path::OSPath, symbolic_mode::AbstractString; recursive=false)
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

Base.open(path::OSPath, args...) = open(string(path), args...)
function Base.open(f::Function, path::OSPath, args...; kwargs...)
    open(f, string(path), args...; kwargs...)
end

Base.read(path::OSPath, args...) = read(string(path), args...)
function Base.write(path::OSPath, x::Union{String, Vector{UInt8}}, mode="w")
    open(path, mode) do f
        write(f, x)
    end
end

Base.readlink(path::OSPath) = Path(readlink(string(path)))
Base.readdir(path::OSPath) = map(Path, readdir(string(path)))

function Base.download(src::AbstractString, dest::OSPath, overwrite::Bool=false)
    if !exists(dest) || overwrite
        download(src, string(dest))
    end
    return dest
end
