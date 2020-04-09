# API

All the standard methods for working with paths in base julia exist in the FilePathsBase.jl. The following describes the rough mapping of method names. Use `?` at the REPL to get the documentation and arguments as they may be different than the base implementations.

Base | FilePathsBase.jl
--- | ---
"/home/user/docs" | `p"/home/user/docs"`
N/A | Path()
pwd() | pwd(::Type{<:AbstractPath}) (or cwd())
homedir() | homedir(::Type{<:AbstractPath}) (or home())
cd() | cd()
joinpath() | joinpath(), join, /
basename() | basename()
N/A | hasparent, parents, parent
splitext | splitext
N/A | filename
N/A | extension
N/A | extensions
ispath | exists
realpath | real
normpath | normalize
abspath | absolute
relpath | relative
stat | stat
lstat | lstat
filemode | mode
mtime | modified
ctime | created
isdir | isdir
isfile | isfile
islink | islink
issocket | issocket
isfifo | isfifo
ischardev | ischardev
isblockdev | isblockdev
isexecutable (deprecated) | isexecutable
iswritable (deprecated) | iswritable
isreadable (deprecated) | isreadable
ismount | ismount
isabspath | isabsolute
splitdrive()[1] | drive
N/A | root (property)
split(p, "/") | segments (property)
expanduser | expanduser
mkdir | mkdir
mkpath | N/A (use mkdir)
symlink | symlink
cp | cp
mv | mv
download | download
readdir | readdir
N/A | readpath
N/A | walkpath
rm | rm
touch | touch
tempname() | tempname(::Type{<:AbstractPath}) (or tmpname)
tempdir() | tempdir(::Type{<:AbstractPath}) (or tmpdir)
mktemp() | mktemp(::Type{<:AbstractPath}) (or mktmp)
mktempdir() | mktempdir(::Type{<:AbstractPath}) (or mktmpdir)
chmod | chmod (recursive unix-only)
chown (unix only) | chown (unix only)
read | read
write | write
@__DIR__ | @__PATH__
@__FILE__ | @__FILEPATH__


```@meta
DocTestSetup = quote
    using FilePathsBase
    using FilePathsBase: /
end
```

```@docs
FilePathsBase.AbstractPath
FilePathsBase.Path
FilePathsBase.SystemPath
FilePathsBase.PosixPath
FilePathsBase.WindowsPath
FilePathsBase.Mode
FilePathsBase.@p_str
FilePathsBase.@__PATH__
FilePathsBase.@__FILEPATH__
FilePathsBase.@LOCAL
FilePathsBase.cwd
FilePathsBase.home
FilePathsBase.hasparent
FilePathsBase.parents
FilePathsBase.parent
Base.:(*)(::P, ::Union{P, AbstractString, Char}...) where P <: AbstractPath
FilePathsBase.:(/)(::AbstractPath, ::Union{AbstractPath, AbstractString}...)
FilePathsBase.join(::T, ::Union{AbstractPath, AbstractString}...) where T <: AbstractPath
FilePathsBase.filename(::AbstractPath)
FilePathsBase.extension(::AbstractPath)
FilePathsBase.extensions(::AbstractPath)
Base.isempty(::AbstractPath)
normalize(::T) where {T <: AbstractPath}
absolute(::AbstractPath)
FilePathsBase.isabsolute(::AbstractPath)
FilePathsBase.relative(::T, ::T) where {T <: AbstractPath}
Base.readlink(::AbstractPath)
FilePathsBase.canonicalize(::AbstractPath)
FilePathsBase.mode(::AbstractPath)
FilePathsBase.modified(::AbstractPath)
FilePathsBase.created(::AbstractPath)
FilePathsBase.isexecutable
Base.iswritable(::PosixPath)
Base.isreadable(::PosixPath)
Base.cp(::AbstractPath, ::AbstractPath)
Base.mv(::AbstractPath, ::AbstractPath)
Base.download(::AbstractString, ::AbstractPath)
FilePathsBase.readpath
FilePathsBase.walkpath
Base.open(::AbstractPath)
FilePathsBase.tmpname
FilePathsBase.tmpdir
FilePathsBase.mktmp
FilePathsBase.mktmpdir
Base.chown(::PosixPath, ::AbstractString, ::AbstractString)
Base.chmod(::PosixPath, ::Mode)
FilePathsBase.TestPaths
FilePathsBase.TestPaths.PathSet
```
