struct WindowsPath <: AbstractPath
    parts::Tuple{Vararg{String}}
    root::String
    drive::String

    function WindowsPath(parts::Tuple, root::String, drive::String)
        return new(Tuple(Iterators.filter(!isempty, parts)), root, drive)
    end
end

function _win_splitdrive(path::String)
    m = match(r"^([^\\]+:|\\\\[^\\]+\\[^\\]+|\\\\\?\\UNC\\[^\\]+\\[^\\]+|\\\\\?\\[^\\]+:|)(.*)$", path)
    String(m.captures[1]), String(m.captures[2])
end

WindowsPath() = WindowsPath(tuple(), "", "")

function WindowsPath(parts::Tuple)
    # @show parts
    if occursin(":", parts[1])
        drive, root = _win_splitdrive(parts[1])
        return WindowsPath(parts[2:end], root, drive)
    elseif parts[1] == WIN_PATH_SEPARATOR
        return WindowsPath(parts[2:end], WIN_PATH_SEPARATOR, "")
    else
        WindowsPath(parts, "", "")
    end
end

function WindowsPath(str::AbstractString)
    if isempty(str)
        return WindowsPath(tuple("."), "", "")
    end

    if startswith(str, "\\\\?\\")
        error("The \\\\?\\ prefix is currently not supported.")
    end

    str = replace(str, POSIX_PATH_SEPARATOR => WIN_PATH_SEPARATOR)

    if startswith(str, "\\\\")
        error("UNC paths are currently not supported.")
    elseif startswith(str, "\\")
        tokenized = split(str, WIN_PATH_SEPARATOR)

        return WindowsPath(tuple(String.(tokenized[2:end])...), WIN_PATH_SEPARATOR, "")
    elseif occursin(":", str)
        l_drive, l_path = _win_splitdrive(str)

        tokenized = split(l_path, WIN_PATH_SEPARATOR)

        l_root = isempty(tokenized[1]) ? WIN_PATH_SEPARATOR : ""

        if isempty(tokenized[1])
            tokenized = tokenized[2:end]
        end

        if !isempty(l_drive) || !isempty(l_root)
            tokenized = tuple(tokenized...)
        end

        return WindowsPath(tuple(String.(tokenized)...), l_root, l_drive)
    else
        tokenized = split(str, WIN_PATH_SEPARATOR)

        return WindowsPath(tuple(String.(tokenized)...), "", "")
    end
end

function ==(a::WindowsPath, b::WindowsPath)
    return lowercase.(parts(a)) == lowercase.(parts(b)) &&
        lowercase(drive(a)) == lowercase(drive(b)) &&
        lowercase(root(a)) == lowercase(root(b))
end
parts(path::WindowsPath) = path.parts
drive(path::WindowsPath) = path.drive
root(path::WindowsPath) = path.root
ispathtype(::Type{WindowsPath}, str::AbstractString) = Sys.iswindows()

function Base.show(io::IO, path::WindowsPath)
    print(io, "p\"")
    if isabs(path)
        print(io, replace(anchor(path), "\\" => "/"))
    end
    print(io, join(parts(path), "/"))
    print(io, "\"")
end

function isabs(path::WindowsPath)
    return !isempty(drive(path)) || !isempty(root(path))
end

Base.expanduser(path::WindowsPath) = path
