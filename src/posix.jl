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
PosixPath(str::AbstractString) = parse(PosixPath, str; force=true)

function Base.tryparse(::Type{PosixPath}, str::AbstractString; debug=false, force=false)
    # Since windows and posix paths can overlap we default to checking the host system
    # unless force is passed in for testing purposes.
    force || Sys.isunix() || return nothing
    str = string(str)
    isempty(str) && return PosixPath(tuple("."))

    tokenized = split(str, POSIX_PATH_SEPARATOR)
    root = isempty(tokenized[1]) ? POSIX_PATH_SEPARATOR : ""
    return PosixPath(tuple(map(String, filter!(!isempty, tokenized))...), root)
end

function Base.expanduser(fp::PosixPath)::PosixPath
    p = fp.segments

    if p[1] == "~"
        return length(p) > 1 ? joinpath(home(), p[2:end]...) : home()
    end

    return fp
end

function Base.Filesystem.contractuser(fp::PosixPath)
    h = home()
    if isdescendant(fp, h)
        if fp == h
            return PosixPath("~")
        else
            n = length(h.segments)
            return PosixPath(("~", fp.segments[n+1:end]...))
        end
    end

    return fp
end
