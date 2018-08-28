struct UNCPath <: AbstractPath
  parts::Tuple{Vararg{String}}
end

UNC_PATH_START = "\\\\"

UNCPath() = UNCPath(tuple())

function UNCPath(str::AbstractString)
    if isempty(str)
        return UNCPath(tuple())
    end

    if startswith(str, "\\\\")
        tokenized = split(str, WIN_PATH_SEPARATOR)

        return UNCPath(tuple(UNC_PATH_START, String.(tokenized[3:end])...))
    else
        error("UNC path not formatted correctly.")
    end
end

==(a::UNCPath, b::UNCPath) = lowercase.(parts(a)) == lowercase.(parts(b))

function Base.String(path::UNCPath)
    if parts(path)[1] == UNC_PATH_START
        return UNC_PATH_START * joinpath(parts(path)[2:end]...)
    else
        return joinpath(parts(path)...)
    end
end

parts(path::UNCPath) = path.parts

function Base.show(io::IO, path::UNCPath)
    print(io, "p\"")
    if isabs(path)
        print(io, join(parts(path)[2:end], "/"))
    else
        print(io, join(parts(path), "/"))
    end
    print(io, "\"")
    
end

function isabs(path::UNCPath)
    if parts(path)[1] == UNC_PATH_START
        return true
    else
        return false
    end
end

drive(path::UNCPath) = ""

function root(path::UNCPath)
    if parts(path)[1] == UNC_PATH_START
        return UNC_PATH_START
    else
        return ""
    end
end

# expanduser(path::UNCPath) = path







