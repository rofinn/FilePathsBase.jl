module TestPkg

using FilePathsBase

import Base: ==

__init__() = FilePathsBase.register(TestPath)

# Warning: We only expect this test to work on posix systems.

struct TestPath <: AbstractPath
    parts::Tuple{Vararg{String}}
    root::String
    drive::String
end

TestPath() = TestPath(tuple(), "", "test:")

function TestPath(parts::Tuple)
    parts = map(String, Iterators.filter(!isempty, parts))

    root = ""
    drive = "test:"

    if parts[1] == "test:"
        parts = parts[2:end]
    end

    if parts[1] == ";"
        root = ";"
        parts = parts[2:end]
    end

    return TestPath(tuple(parts...), root, drive)
end

function TestPath(str::AbstractString)
    str = String(str)

    @assert startswith(str, "test:")
    drive = "test:"
    root = ""
    str = str[6:end]

    if isempty(str)
        return TestPath(tuple("."), "", drive)
    end

    tokenized = split(str, ";")
    if isempty(tokenized[1])
        root = ";"
    end

    return TestPath(tuple(map(String, filter!(!isempty, tokenized))...), root, drive)
end

# The following should be implemented in the concrete types
function ==(a::TestPath, b::TestPath)
    return parts(a) == parts(b) &&
        drive(a) == drive(b) &&
        root(a) == root(b)
end
FilePathsBase.parts(path::TestPath) = path.parts
FilePathsBase.drive(path::TestPath) = path.drive
FilePathsBase.root(path::TestPath) = path.root
FilePathsBase.ispathtype(::Type{TestPath}, str::AbstractString) = startswith(str, "test:")
function test2posix(path::TestPath)
    return PosixPath(
        parts(path),
        isempty(root(path)) ? "" : "/",
    )
end

function posix2test(path::PosixPath)
    return TestPath(
        parts(path),
        isempty(root(path)) ? "" : ";",
        "test:",
    )
end

function Base.print(io::IO, path::TestPath)
    print(io, drive(path) * root(path) * join(parts(path), ";"))
end

FilePathsBase.isabs(path::TestPath) = !isempty(drive(path)) && !isempty(root(path))
Base.expanduser(path::TestPath) = path
# We're going to implement most of the posix API, but this won't make sense for many path types
FilePathsBase.exists(path::TestPath) = exists(test2posix(path))
Base.real(path::TestPath) = posix2test(real(test2posix(path)))
FilePathsBase.stat(path::TestPath) = stat(test2posix(path))
FilePathsBase.lstat(path::TestPath) = lstat(test2posix(path))
FilePathsBase.mode(path::TestPath) = stat(path).mode
Base.size(path::TestPath) = stat(path).size
FilePathsBase.created(path::TestPath) = stat(path).ctime
FilePathsBase.modified(path::TestPath) = stat(path).mtime
FilePathsBase.isdir(path::TestPath) = isdir(mode(path))
Base.isfile(path::TestPath) = isfile(mode(path))
Base.islink(path::TestPath) = islink(lstat(path).mode)
Base.issocket(path::TestPath) = issocket(mode(path))
Base.isfifo(path::TestPath) = issocket(mode(path))
Base.ischardev(path::TestPath) = ischardev(mode(path))
Base.isblockdev(path::TestPath) = isblockdev(mode(path))
Base.ismount(path::TestPath) = ismount(test2posix(path))
FilePathsBase.isexecutable(path::TestPath) = isexecutable(test2posix(path))
Base.iswritable(path::TestPath) = iswritable(test2posix(path))
Base.isreadable(path::TestPath) = isreadable(test2posix(path))
Base.cd(path::TestPath) = cd(test2posix(path))
Base.cd(f::Function, path::TestPath) = cd(f, test2posix(path))
Base.mkdir(path::TestPath; kwargs...) = mkdir(test2posix(path); kwargs...)
Base.symlink(src::TestPath, dest::TestPath; kwargs...) = symlink(test2posix(src), test2posix(dest); kwargs...)
Base.rm(path::TestPath; kwargs...) = rm(test2posix(path); kwargs...)
Base.readdir(path::TestPath) = readdir(test2posix(path))
Base.read(path::TestPath, args...) = read(test2posix(path), args...)
Base.write(path::TestPath, x) = write(test2posix(path), x)
Base.chown(path::TestPath, args...; kwargs...) = chown(test2posix(path), args...; kwargs...)
Base.chmod(path::TestPath, args...; kwargs...) = chmod(test2posix(path), args...; kwargs...)

end
