module TestPkg

using FilePathsBase
using FilePathsBase: path

import Base: ==

__init__() = FilePathsBase.register(TestPath)

# Warning: We only expect this test to work on posix systems.

struct TestPath <: AbstractPath
    path::Tuple{Vararg{String}}
    root::String
    drive::String
end

TestPath() = TestPath(tuple(), "", "test:")

function TestPath(components::Tuple)
    components = map(String, Iterators.filter(!isempty, components))

    root = ""
    drive = "test:"

    if components[1] == "test:"
        components = components[2:end]
    end

    if components[1] == ";"
        root = ";"
        components = components[2:end]
    end

    return TestPath(tuple(components...), root, drive)
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

FilePathsBase.path(fp::TestPath) = fp.path
FilePathsBase.drive(fp::TestPath) = fp.drive
FilePathsBase.root(fp::TestPath) = fp.root
FilePathsBase.ispathtype(::Type{TestPath}, str::AbstractString) = startswith(str, "test:")
function test2posix(fp::TestPath)
    return PosixPath(path(fp), isempty(root(fp)) ? "" : "/")
end

function posix2test(fp::PosixPath)
    return TestPath(path(fp), isempty(root(fp)) ? "" : ";", "test:")
end

function Base.print(io::IO, fp::TestPath)
    print(io, drive(fp) * root(fp) * join(path(fp), ";"))
end

FilePathsBase.isabs(fp::TestPath) = !isempty(drive(fp)) && !isempty(root(fp))
Base.expanduser(fp::TestPath) = fp
# We're going to implement most of the posix API, but this won't make sense for many path types
FilePathsBase.exists(fp::TestPath) = exists(test2posix(fp))
Base.real(fp::TestPath) = posix2test(real(test2posix(fp)))
FilePathsBase.stat(fp::TestPath) = stat(test2posix(fp))
FilePathsBase.lstat(fp::TestPath) = lstat(test2posix(fp))
FilePathsBase.mode(fp::TestPath) = stat(fp).mode
Base.size(fp::TestPath) = stat(fp).size
FilePathsBase.created(fp::TestPath) = stat(fp).ctime
FilePathsBase.modified(fp::TestPath) = stat(fp).mtime
FilePathsBase.isdir(fp::TestPath) = isdir(mode(fp))
Base.isfile(fp::TestPath) = isfile(mode(fp))
Base.islink(fp::TestPath) = islink(lstat(fp).mode)
Base.issocket(fp::TestPath) = issocket(mode(fp))
Base.isfifo(fp::TestPath) = issocket(mode(fp))
Base.ischardev(fp::TestPath) = ischardev(mode(fp))
Base.isblockdev(fp::TestPath) = isblockdev(mode(fp))
Base.ismount(fp::TestPath) = ismount(test2posix(fp))
FilePathsBase.isexecutable(fp::TestPath) = isexecutable(test2posix(fp))
Base.iswritable(fp::TestPath) = iswritable(test2posix(fp))
Base.isreadable(fp::TestPath) = isreadable(test2posix(fp))
Base.cd(fp::TestPath) = cd(test2posix(fp))
Base.cd(f::Function, fp::TestPath) = cd(f, test2posix(fp))
Base.mkdir(fp::TestPath; kwargs...) = mkdir(test2posix(fp); kwargs...)
Base.symlink(src::TestPath, dest::TestPath; kwargs...) = symlink(test2posix(src), test2posix(dest); kwargs...)
Base.rm(fp::TestPath; kwargs...) = rm(test2posix(fp); kwargs...)
Base.readdir(fp::TestPath) = readdir(test2posix(fp))
Base.read(fp::TestPath, args...) = read(test2posix(fp), args...)
Base.write(fp::TestPath, x) = write(test2posix(fp), x)
Base.chown(fp::TestPath, args...; kwargs...) = chown(test2posix(fp), args...; kwargs...)
Base.chmod(fp::TestPath, args...; kwargs...) = chmod(test2posix(fp), args...; kwargs...)

end
