"""
    PosixPath()
    PosixPath(str)

Represents any posix path (e.g., `/home/user/docs`)
"""
struct PosixPath{F<:Form, K<:Kind} <: SystemPath{F, K}
    segments::Tuple{Vararg{String}}
    root::String
end

PosixPath() = PosixPath{Rel, Dir}(tuple(), "")

# WARNING: We don't know if this was a directory of file at this point
PosixPath(segments::Tuple; root="") = PosixPath{Rel, Kind}(segments, root)

PosixPath(str::AbstractString) = parse(PosixPath, str)

if Sys.isunix()
    Path() = PosixPath()
    Path(pieces::Tuple) = PosixPath(pieces)
    cwd() = parse(PosixPath{Abs, Dir}, pwd() * POSIX_PATH_SEPARATOR)
    home() = parse(PosixPath{Abs, Dir}, homedir() * POSIX_PATH_SEPARATOR)
end

######### Parsing ###########
# High level tryparse for the entire type
function Base.tryparse(::Type{PosixPath}, str::AbstractString)
    # Only bother with `tryparse` if we're on a posix system.
    # NOTE: You can always bypass this behaviour by calling the lower level methods.
    Sys.isunix() || return nothing
    F = isabspath(str) ? Abs : Rel
    K = isdirpath(str) ? Dir : File
    return tryparse(PosixPath{F, K}, str)
end

# Internal tryparse methods for different expected permutations
function Base.tryparse(::Type{PosixPath{Rel, File}}, str::AbstractString)
    str = normpath(str)
    isempty(str) && return nothing

    tokenized = split(str, POSIX_PATH_SEPARATOR)

    # `str` starts or ends with separator then we don't have a valid relative file.
    isempty(first(tokenized)) || isempty(last(tokenized)) && return nothing

    return PosixPath{Rel, File}(tuple(String.(tokenized)...), "")
end

function Base.tryparse(::Type{PosixPath{Rel, Dir}}, str::AbstractString)
    str = normpath(str)
    # normpath will remove trailing separator from "./" and "../" which will break our assumption
    # that directories must end with the separator.
    isempty(str) || str == "." && return PosixPath{Rel, Dir}(tuple("."), "")
    str == ".." && return PosixPath{Rel, Dir}(tuple("..", ""))

    tokenized = split(str, POSIX_PATH_SEPARATOR)
    # `str` does not start but ends with separator or we don't have a valid relative directory.
    !isempty(first(tokenized)) && isempty(last(tokenized)) || return nothing

    return PosixPath{Rel, Dir}(tuple(String.(tokenized[1:end-1])...), "")
end

function Base.tryparse(::Type{PosixPath{Abs, File}}, str::AbstractString)
    str = normpath(str)
    isempty(str) && return nothing

    tokenized = split(str, POSIX_PATH_SEPARATOR)

    # `str` starts but doesn't end with separator or we don't have a valid absolute file.
    isempty(first(tokenized)) && !isempty(last(tokenized)) || return nothing

    return PosixPath{Abs, File}(tuple(String.(tokenized[2:end])...), POSIX_PATH_SEPARATOR)
end

function Base.tryparse(::Type{PosixPath{Abs, Dir}}, str::AbstractString)
    str = normpath(str)
    isempty(str) && return nothing

    tokenized = split(str, POSIX_PATH_SEPARATOR)

    # `str` starts and ends with separator or we don't have a valid absolute file.
    isempty(first(tokenized)) && isempty(last(tokenized)) || return nothing

    return PosixPath{Abs, Dir}(tuple(String.(tokenized[2:end-1])...), POSIX_PATH_SEPARATOR)
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
