struct PosixPath <: AbstractPath
    parts::Tuple{Vararg{String}}
    root::String
end

PosixPath() = PosixPath(tuple(), "")

function PosixPath(parts::Tuple)
    parts = map(String, Iterators.filter(!isempty, parts))

    if parts[1]==POSIX_PATH_SEPARATOR
        return PosixPath(tuple(parts[2:end]...), POSIX_PATH_SEPARATOR)
    else
        return PosixPath(tuple(parts...), "")
    end
end

function PosixPath(str::AbstractString)
    str = string(str)
    root = ""

    if isempty(str)
        return PosixPath(tuple("."))
    end

    tokenized = split(str, POSIX_PATH_SEPARATOR)
    if isempty(tokenized[1])
        root = POSIX_PATH_SEPARATOR
    end
    return PosixPath(tuple(map(String, filter!(!isempty, tokenized))...), root)
end

# The following should be implemented in the concrete types
function ==(a::PosixPath, b::PosixPath)
    return parts(a) == parts(b) && root(a) == root(b)
end

parts(path::PosixPath) = path.parts
root(path::PosixPath) = path.root
drive(path::PosixPath) = ""
ispathtype(::Type{PosixPath}, str::AbstractString) = Sys.isunix()
isabs(path::PosixPath) = !isempty(root(path))

function Base.expanduser(path::PosixPath)
    p = parts(path)

    if p[1] == "~"
        if length(p) > 1
            return PosixPath(tuple(homedir(), p[2:end]...))
        else
            return PosixPath(tuple(homedir()))
        end
    end

    return path
end
