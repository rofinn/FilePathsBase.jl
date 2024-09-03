"""
    TestPaths

This module is intended to be used for testing new path types to
ensure that they are adhering to the AbstractPath API.

# Example

```julia
# Create a PathSet
ps = PathSet(; symlink=true)

# Select the subset of tests to run
# Inspect TestPaths.TESTALL to see full list
testsets = [
    test_registration,
    test_show,
    test_cmd,
    test_parse,
    test_convert,
    test_components,
    test_parents,
    test_join,
    test_splitext,
    test_basename,
    test_splitdir,
    test_filename,
    test_extensions,
    test_isempty,
    test_normalize,
    test_canonicalize,
    test_relative,
    test_absolute,
    test_isdir,
    test_isfile,
    test_stat,
    test_filesize,
    test_modified,
    test_created,
    test_cd,
    test_readpath,
    test_walkpath,
    test_read,
    test_write,
    test_mkdir,
    test_cp,
    test_mv,
    test_sync,
    test_symlink,
    test_touch,
    test_tmpname,
    test_tmpdir,
    test_mktmp,
    test_mktmpdir,
    test_download,
    test_include,
]

# Run all the tests
test(ps, testsets)
```
"""
module TestPaths
using Dates: Dates
using FilePathsBase
using FilePathsBase: /, join

export PathSet,
    TESTALL,
    test,
    test_registration,
    test_show,
    test_cmd,
    test_parse,
    test_convert,
    test_components,
    test_indexing,
    test_iteration,
    test_parents,
    test_descendants_and_ascendants,
    test_join,
    test_splitext,
    test_basename,
    test_splitdir,
    test_filename,
    test_extensions,
    test_isempty,
    test_normalize,
    test_canonicalize,
    test_relative,
    test_absolute,
    test_isdir,
    test_isfile,
    test_stat,
    test_filesize,
    test_modified,
    test_created,
    test_issocket,
    test_isfifo,
    test_ischardev,
    test_isblockdev,
    test_ismount,
    test_isexecutable,
    test_isreadable,
    test_iswritable,
    test_cd,
    test_readpath,
    test_walkpath,
    test_read,
    test_write,
    test_mkdir,
    test_cp,
    test_mv,
    test_sync,
    test_symlink,
    test_touch,
    test_tmpname,
    test_tmpdir,
    test_mktmp,
    test_mktmpdir,
    test_chown,
    test_chmod,
    test_download,
    test_include

"""
    PathSet(root::AbstractPath=tmpdir(); symlink=false)

Constructs a common test path hierarchy to running shared API tests.

Hierarchy:

```
root
|-- foo
|   |-- baz.txt
|-- bar
|   |-- qux
|       |-- quux.tar.gz
|-- fred
|   |-- plugh
```
"""
struct PathSet{P<:AbstractPath}
    root::P
    foo::P
    baz::P
    bar::P
    qux::P
    quux::P
    fred::P
    plugh::P
    link::Bool
end

function PathSet(root=tmpdir() / "pathset_root"; symlink=false)
    root = absolute(root)

    return PathSet(
        root,
        root / "foo",
        root / "foo" / "baz.txt",
        root / "bar",
        root / "bar" / "qux",
        root / "bar" / "qux" / "quux.tar.gz",
        root / "fred",
        root / "fred" / "plugh",
        symlink,
    )
end

function initialize(ps::PathSet)
    @info "Initializing $(typeof(ps))"
    mkdir.([ps.foo, ps.qux, ps.fred]; recursive=true, exist_ok=true)
    write(ps.baz, "Hello World!")
    write(ps.quux, "Hello Again!")

    # If link is true then plugh is a symlink to foo
    if ps.link
        symlink(ps.foo, ps.plugh)
    else
        touch(ps.plugh)
    end
end

# NOTE: Most paths should test their own constructors as necessary.

function test_registration end
function test_show end
function test_cmd end
function test_parse end
function test_convert end
function test_components end
function test_indexing end
function test_iteration end
function test_parents end
function test_descendants_and_ascendants end
function test_join end
function test_splitext end
function test_basename end
function test_splitdir end
function test_filename end
function test_extensions end
function test_isempty end
function test_normalize end
function test_canonicalize end
function test_relative end
function test_absolute end
function test_isdir end
function test_isfile end
function test_stat end

# Minimal testing of issocket, isfifo, ischardev, isblockdev and ismount which
# people won't typically include.
function test_issocket end
function test_isfifo end
function test_ischardev end
function test_isblockdev end
function test_ismount end
function test_filesize end
function test_modified end
function test_created end
function test_isexecutable end
function test_isreadable end
function test_iswritable end
function test_cd end
function test_readpath end
function test_walkpath end
function test_read end
function test_write end
function test_mkdir end
function test_cp end
function test_mv end
function test_sync end
function test_symlink end
function test_touch end
function test_tmpname end
function test_tmpdir end
function test_mktmp end
function test_mktmpdir end
function test_chown end
function test_chmod end
function test_download end
function test_include end

TESTALL = [
    test_registration,
    test_show,
    test_cmd,
    test_parse,
    test_convert,
    test_components,
    test_indexing,
    test_iteration,
    test_parents,
    test_descendants_and_ascendants,
    test_join,
    test_splitext,
    test_basename,
    test_filename,
    test_extensions,
    test_isempty,
    test_normalize,
    test_canonicalize,
    test_relative,
    test_absolute,
    test_isdir,
    test_isfile,
    test_stat,
    test_filesize,
    test_modified,
    test_created,
    test_issocket,
    test_isfifo,
    test_ischardev,
    test_isblockdev,
    test_ismount,
    test_isexecutable,
    test_isreadable,
    test_iswritable,
    test_cd,
    test_readpath,
    test_walkpath,
    test_read,
    test_write,
    test_mkdir,
    test_cp,
    test_mv,
    test_symlink,
    test_touch,
    test_tmpname,
    test_tmpdir,
    test_mktmp,
    test_mktmpdir,
    test_chown,
    test_chmod,
    test_download,
    test_include,
]

function test(ps::PathSet, test_sets=TESTALL)
    try
        initialize(ps)

        for ts in test_sets
            ts(ps)
        end
    finally
        rm(ps.root; recursive=true, force=true)
    end
end
end #module
