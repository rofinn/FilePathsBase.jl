"""
    PosixPath()
    PosixPath(str)

Represents any posix path (e.g., `/home/user/docs`)
"""
struct PosixPath <: AbstractPath
    segments::Tuple{Vararg{String}}
    root::String
end

PosixPath() = PosixPath(tuple(), "")
PosixPath(segments::Tuple; root="") = PosixPath(segments, root)

function PosixPath(str::AbstractString)
    str = string(str)
    root = ""

    isempty(str) && return PosixPath(tuple("."))

    tokenized = split(str, POSIX_PATH_SEPARATOR)
    if isempty(tokenized[1])
        root = POSIX_PATH_SEPARATOR
    end
    return PosixPath(tuple(map(String, filter!(!isempty, tokenized))...), root)
end

ispathtype(::Type{PosixPath}, str::AbstractString) = Sys.isunix()
isabs(fp::PosixPath) = !isempty(fp.root)

function Base.expanduser(fp::PosixPath)
    p = fp.segments

    if p[1] == "~"
        if length(p) > 1
            return PosixPath(tuple(homedir(), p[2:end]...))
        else
            return PosixPath(tuple(homedir()))
        end
    end

    return fp
end
