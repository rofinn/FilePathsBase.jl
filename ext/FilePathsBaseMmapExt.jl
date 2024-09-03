module FilePathsBaseMmapExt
using Mmap
using FilePathsBase

function Mmap.mmap(fp::FilePathsBase.SystemPath, args...; kwargs...)
    return Mmap.mmap(string(fp), args...; kwargs...)
end

end #module
