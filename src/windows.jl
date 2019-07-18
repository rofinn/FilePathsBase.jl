struct WindowsPath <: AbstractPath
    path::Tuple{Vararg{String}}
    root::String
    drive::String

    function WindowsPath(path::Tuple, root::String, drive::String)
        return new(Tuple(Iterators.filter(!isempty, path)), root, drive)
    end
end

function _win_splitdrive(fp::String)
    m = match(r"^([^\\]+:|\\\\[^\\]+\\[^\\]+|\\\\\?\\UNC\\[^\\]+\\[^\\]+|\\\\\?\\[^\\]+:|)(.*)$", fp)
    String(m.captures[1]), String(m.captures[2])
end

WindowsPath() = WindowsPath(tuple(), "", "")

function WindowsPath(components::Tuple)
    drive = ""
    root = ""
    path = collect(components)

    if occursin(":", first(path))
        drive, root  = _win_splitdrive(popfirst!(path))
    end

    if isempty(root) && first(path) == WIN_PATH_SEPARATOR
        root = WIN_PATH_SEPARATOR
        popfirst!(path)
    end

    return WindowsPath(tuple(path...), root, drive)
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

==(a::WindowsPath, b::WindowsPath) = lowercase.(components(a)) == lowercase.(components(b))

path(fp::WindowsPath) = fp.path
drive(fp::WindowsPath) = fp.drive
root(fp::WindowsPath) = fp.root
ispathtype(::Type{WindowsPath}, str::AbstractString) = Sys.iswindows()

function Base.print(io::IO, fp::WindowsPath)
    print(io, drive(fp) * root(fp) * join(path(fp), WIN_PATH_SEPARATOR))
end

function Base.show(io::IO, fp::WindowsPath)
    print(io, "p\"")
    if isabs(fp)
        print(io, replace(anchor(fp), "\\" => "/"))
    end
    print(io, join(path(fp), "/"))
    print(io, "\"")
end

function isabs(fp::WindowsPath)
    return !isempty(drive(fp)) || !isempty(root(fp))
end

Base.expanduser(fp::WindowsPath) = fp
