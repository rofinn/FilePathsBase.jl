# FilePathsBase.jl

[![Build Status](https://travis-ci.org/rofinn/FilePathsBase.jl.svg?branch=master)](https://travis-ci.org/rofinn/FilePathsBase.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/mj0ax1822c1ldhj3/branch/master?svg=true)](https://ci.appveyor.com/project/rofinn/filepathsbase-jl/branch/master)
[![codecov.io](https://codecov.io/github/rofinn/FilePathsBase.jl/coverage.svg?branch=master)](https://codecov.io/rofinn/FilePathsBase.jl?branch=master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rofinn.github.io/FilePathsBase.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rofinn.github.io/FilePathsBase.jl/dev)

FilePathsBase.jl provides a type based approach to working with filesystem paths in julia.

## Intallation
FilePathsBase.jl is registered, so you can to use `Pkg.add` to install it.
```julia
julia> Pkg.add("FilePathsBase")
```

## Usage
```julia
julia> using FilePathsBase
```

The first important difference about working with paths in FilePathsBase.jl is that path
segments are represented as an immutable tuple of strings.

Path creation:
```julia
julia> Path("~/repos/FilePathsBase.jl/")
p"~/repos/FilePathsBase.jl/"
```
or
```julia
julia> p"~/repos/FilePathsBase.jl/"
p"~/repos/FilePathsBase.jl/"
```

Human readable file status info:
```julia
julia> stat(p"README.md")
Status(
  device = 16777220,
  inode = 48428965,
  mode = -rw-r--r--,
  nlink = 1,
  uid = 501,
  gid = 20,
  rdev = 0,
  size = 1880 (1.8K),
  blksize = 4096 (4.0K),
  blocks = 8,
  mtime = 2016-02-16T00:49:27,
  ctime = 2016-02-16T00:49:27,
)
```

Working with permissions:
```julia
julia> m = mode(p"README.md")
-rw-r--r--

julia> m - readable(:ALL)
--w-------

julia> m + executable(:ALL)
-rwxr-xr-x

julia> chmod(p"README.md", "+x")

julia> mode(p"README.md")
-rwxr-xr-x

julia> chmod(p"README.md", m)

julia> m = mode(p"README.md")
-rw-r--r--

julia> chmod(p"README.md", user=(READ+WRITE+EXEC), group=(READ+WRITE), other=READ)

julia> mode(p"README.md")
-rwxrw-r--

```

Reading and writing directly to file paths:
```julia
julia> write(p"testfile", "foobar")
6

julia> read(p"testfile")
"foobar"
```

## API

All the standard methods for working with paths in base julia exist in the FilePathsBase.jl. The following describes the rough mapping of method names. Use `?` at the REPL to get the documentation and arguments as they may be different than the base implementations.

Base | FilePathsBase.jl
--- | ---
"/home/user/docs" | `p"/home/user/docs"`
N/A | Path()
pwd() | cwd()
homedir() | home()
cd() | cd()
joinpath() | joinpath(), join, /
basename() | basename()
N/A | hasparent, parents, parent
splitext(basename())[1] | filename
splitext(basename())[2] | extension
N/A | extensions
ispath | exists
realpath | real
normpath | norm
abspath | abs
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
isabspath | isabs
splitdrive()[1] | drive
N/A | root (property)
split(p, "/") | segments (property)
expanduser | expanduser
mkdir | mkdir
mkpath | N/A (use mkdir)
symlink | symlink
cp | copy
mv | move
readdir | readdir
N/A | readpath
N/A | walkpath
rm | remove
touch | touch
tempname | tmpname
tempdir | tmpdir
mktemp | mktmp
mktempdir | mktmpdir
chmod | chmod (recursive unix-only)
chown (unix only) | chown (unix only)
read | read
write | write
@__DIR__ | @__PATH__
@__FILE__ | @__FILEPATH__


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
Base.:(/)(::AbstractPath, ::Union{AbstractPath, AbstractString}...)
Base.join(::T, ::Union{AbstractPath, AbstractString}...) where T <: AbstractPath
FilePathsBase.filename(::AbstractPath)
FilePathsBase.extension(::AbstractPath)
FilePathsBase.extensions(::AbstractPath)
Base.isempty(::AbstractPath)
LinearAlgebra.norm(::T) where {T <: AbstractPath}
Base.abs(::AbstractPath)
FilePathsBase.isabs(::AbstractPath)
FilePathsBase.relative(::T, ::T) where {T <: AbstractPath}
Base.real(::AbstractPath)
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
