module FilePathsBaseMmapExt
using Mmap
using FilePathsBase

Mmap.mmap(fp::FilePathsBase.SystemPath, args...; kwargs...) = Mmap.mmap(string(fp), args...; kwargs...)

end #module