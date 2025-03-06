module FilePathsBaseURIsExt
using URIs
using FilePathsBase

const absent = SubString("absent", 1, 0)

function URIs.URI(p::AbstractPath; query=absent, fragment=absent)
    if isempty(p.root)
        throw(ArgumentError("$p is not an absolute path"))
    end

    b = IOBuffer()
    print(b, "file://")

    if !isempty(p.drive)
        print(b, "/")
        print(b, p.drive)
    end

    for s in p.segments
        print(b, "/")
        print(b, URIs.escapeuri(s))
    end

    return URIs.URI(URIs.URI(String(take!(b))); query=query, fragment=fragment)
end

end #module
