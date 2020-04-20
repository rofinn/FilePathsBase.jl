# FilePathsBase.jl

[![Build Status](https://travis-ci.com/rofinn/FilePathsBase.jl.svg?branch=master)](https://travis-ci.com/rofinn/FilePathsBase.jl)
[![codecov.io](https://codecov.io/github/rofinn/FilePathsBase.jl/coverage.svg?branch=master)](https://codecov.io/rofinn/FilePathsBase.jl?branch=master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rofinn.github.io/FilePathsBase.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rofinn.github.io/FilePathsBase.jl/dev)

FilePathsBase.jl provides a type based approach to working with filesystem paths in julia.

## Intallation

FilePathsBase.jl is registered, so you can to use `Pkg.add` to install it.
```julia
julia> Pkg.add("FilePathsBase")
```

## Getting Started
```julia
julia> using FilePathsBase; using FilePathsBase: /
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
