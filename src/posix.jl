struct PosixPath <: AbstractPath
    path::Tuple{Vararg{String}}
    root::String
end

PosixPath() = PosixPath(tuple(), "")

function PosixPath(components::Tuple)
    components = map(String, Iterators.filter(!isempty, components))

    if components[1]==POSIX_PATH_SEPARATOR
        return PosixPath(tuple(components[2:end]...), POSIX_PATH_SEPARATOR)
    else
        return PosixPath(tuple(components...), "")
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

path(fp::PosixPath) = fp.path
root(fp::PosixPath) = fp.root
drive(fp::PosixPath) = ""
ispathtype(::Type{PosixPath}, str::AbstractString) = Sys.isunix()
isabs(fp::PosixPath) = !isempty(root(fp))

function Base.expanduser(fp::PosixPath)
    p = path(fp)

    if p[1] == "~"
        if length(p) > 1
            return PosixPath(tuple(homedir(), p[2:end]...))
        else
            return PosixPath(tuple(homedir()))
        end
    end

    return fp
end
