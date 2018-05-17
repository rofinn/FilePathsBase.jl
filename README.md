# FilePathsBase.jl

[![Build Status](https://travis-ci.org/rofinn/FilePathsBase.jl.svg?branch=master)](https://travis-ci.org/rofinn/FilePathsBase.jl)
[![codecov.io](https://codecov.io/github/rofinn/FilePathsBase.jl/coverage.svg?branch=master)](https://codecov.io/rofinn/FilePathsBase.jl?branch=master)

FilePathsBase.jl provides a type based approach to working with filesystem paths in julia.

## Intallation:
FilePathsBase.jl is registered, so you can to use `Pkg.add` to install it.
```julia
julia> Pkg.add("FilePaths")
```

## Usage:
```julia
julia> using FilePathsBase
```

The first important difference about working with paths in FilePathsBase.jl is that a path is an immutable list (Tuple) of strings, rather than simple a string.

Path creation:
```julia
julia> Path("~/repos/FilePathsBase.jl/")
Paths.PosixPath(("~","repos","FilePathsBase.jl",""))
```
or
```julia
julia> p"~/repos/FilePathsBase.jl/"
Paths.PosixPath(("~","repos","FilePathsBase.jl",""))
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

All the standard methods for working with paths in base julia exist in the FilePathsBase.jl. The following describes the rough mapping of method names. Use `?` at the REPL to get the documentation and arguments as they may be different than the base implementations.

Base | FilePathsBase.jl
--- | ---
pwd() | cwd()
homedir() | home()
cd() | cd()
joinpath() | joinpath()
basename() | basename()
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
N/A | root
expanduser | expanduser
mkdir | mkdir
mkpath | N/A (use mkdir)
symlink | symlink
cp | copy
mv | move
rm | remove
touch | touch
tempname | tmpname
tempdir | tmpdir
mktemp | mktmp
mktempdir | mktmpdir
chmod | chmod (recursive unix-only)
chown (unix only) | chown (unix only)
N/A | read
N/A | write
@__DIR__ | @__PATH__
@__FILE__ | @__FILEPATH__

## TODO:
* cross platform chmod and chown


