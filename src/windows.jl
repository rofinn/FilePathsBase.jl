"""
    WindowsPath()
    WindowsPath(str)

Represents a windows path (e.g., `C:\\User\\Documents`)
"""
struct WindowsPath{F<:Form, K<:Kind} <: SystemPath{F, K}
    segments::Tuple{Vararg{String}}
    root::String
    drive::String
    separator::String
end

# WARNING: We don't know if this was a directory of file at this point
function WindowsPath(
    segments::Tuple, root::String, drive::String, separator::String=WIN_PATH_SEPARATOR
)
    F = isempty(root) ? Rel : Abs
    return WindowsPath{F, Kind}(
        Tuple(Iterators.filter(!isempty, segments)), root, drive, separator
    )
end

function _win_splitdrive(fp::String)
    m = match(r"^([^\\]+:|\\\\[^\\]+\\[^\\]+|\\\\\?\\UNC\\[^\\]+\\[^\\]+|\\\\\?\\[^\\]+:|)(.*)$", fp)
    String(m.captures[1]), String(m.captures[2])
end

WindowsPath() = WindowsPath(tuple(), "", "")

function WindowsPath(segments::Tuple; root="", drive="", separator="\\")
    return WindowsPath(segments, root, drive, separator)
end

WindowsPath(str::AbstractString) = parse(WindowsPath, str)

if Sys.iswindows()
    Path() = WindowsPath()
    Path(pieces::Tuple) = WindowsPath(pieces)
    cwd() = parse(WindowsPath{Abs, Dir}, pwd() * WIN_PATH_SEPARATOR)
    home() = parse(WindowsPath{Abs, Dir}, homedir() * WIN_PATH_SEPARATOR)
end

# High level tryparse for the entire type
function Base.tryparse(::Type{WindowsPath}, str::AbstractString)
    # Only bother with `tryparse` if we're on a windows system.
    # NOTE: You can always bypass this behaviour by calling the lower level methods.
    Sys.iswindows() || return nothing
    startswith(str, "\\\\?\\") && return nothing
    startswith(str, "\\\\") && return nothing

    F = isabspath(str) ? Abs : Rel
    K = isdirpath(str) ? Dir : File
    return tryparse(WindowsPath{F, K}, str)
end

# Internal tryparse methods for different expected permutations
function Base.tryparse(::Type{WindowsPath{Rel, File}}, str::AbstractString, raise::Bool)
    str = normpath(str)
    isempty(str) && return nothing

    drive, path = _win_splitdrive(str)
    tokenized = split(path, WIN_PATH_SEPARATOR)

    # path starts or ends with separator then we don't have a valid relative file.
    isempty(first(tokenized)) || isempty(last(tokenized)) && return nothing

    return WindowsPath{Rel, File}(tuple(String.(tokenized)...), "", drive)
end

function Base.tryparse(::Type{WindowsPath{Rel, Dir}}, str::AbstractString)
    str = normpath(str)
    isempty(str) && return WindowsPath{Rel, Dir}(tuple("."), "", "")

    drive, path = _win_splitdrive(str)
    tokenized = split(path, WIN_PATH_SEPARATOR)

    # `str` does not start but ends with separator or we don't have a valid relative directory.
    !isempty(first(tokenized)) && isempty(last(tokenized)) || return nothing

    return WindowsPath{Rel, Dir}(tuple(String.(tokenized[1:end-1])...), "", drive)
end

function Base.tryparse(::Type{WindowsPath{Abs, File}}, str::AbstractString)
    str = normpath(str)
    isempty(str) && return nothing

    drive, path = _win_splitdrive(str)
    tokenized = split(path, WIN_PATH_SEPARATOR)

    # `str` starts but doesn't end with separator or we don't have a valid absolute file.
    isempty(first(tokenized)) && !isempty(last(tokenized)) || return nothing

    return WindowsPath{Abs, File}(
        tuple(String.(tokenized[2:end])...),
        WIN_PATH_SEPARATOR,
        drive,
    )
end

function Base.tryparse(::Type{WindowsPath{Abs, Dir}}, str::AbstractString)
    str = normpath(str)
    isempty(str) && return nothing

    drive, path = _win_splitdrive(str)
    tokenized = split(path, WIN_PATH_SEPARATOR)

    # `str` starts and ends with separator or we don't have a valid absolute file.
    isempty(first(tokenized)) && isempty(last(tokenized)) || return nothing

    return WindowsPath{Abs, Dir}(
        tuple(String.(tokenized[2:end-1])...),
        WIN_PATH_SEPARATOR,
        drive
    )
end

function Base.:(==)(a::WindowsPath, b::WindowsPath)
    return lowercase.(a.segments) == lowercase.(b.segments) &&
        lowercase(a.root) == lowercase(b.root) &&
        lowercase(a.drive) == lowercase(b.drive)
end

ispathtype(::Type{WindowsPath}, str::AbstractString) = Sys.iswindows()

function Base.show(io::IO, fp::WindowsPath)
    print(io, "p\"")
    if isabsolute(fp)
        print(io, replace(fp.anchor, "\\" => "/"))
    end
    print(io, join(fp.segments, "/"))
    print(io, "\"")
end

isabsolute(fp::WindowsPath) = (!isempty(fp.drive) || !isempty(fp.root))
