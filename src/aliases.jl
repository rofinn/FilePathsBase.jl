# Various aliases to support the Base.Filesystem API or overwrite base behaviour.

# Fallback non-filepath methods if folks explicitly import these symbols
/(args...) = Base.:/(args...)
join(args...) = Base.join(args...)

# Aliases for Base.Filesystem API
# Filesystem methods that were renamed should still have an alias for better interop.
Base.abspath(fp::AbstractPath) = absolute(fp)
Base.ctime(fp::AbstractPath) = datetime2unix(created(fp))
Base.dirname(fp::AbstractPath) = parent(fp)
Base.filemode(fp::AbstractPath) = mode(fp)
Base.isabspath(fp::AbstractPath) = isabsolute(fp)
Base.ispath(fp::AbstractPath) = exists(fp)
function Base.joinpath(root::AbstractPath, pieces::Union{AbstractPath,AbstractString}...)
    return join(root, pieces...)
end
Base.mkpath(fp::AbstractPath) = mkdir(fp; recursive=true, exist_ok=true)
Base.mtime(fp::AbstractPath) = datetime2unix(modified(fp))
Base.normpath(fp::AbstractPath) = normalize(fp)
Base.realpath(fp::AbstractPath) = canonicalize(fp)
Base.relpath(fp::AbstractPath) = relative(fp)
Base.relpath(fp::AbstractPath, src::AbstractPath) = relative(fp, src)
