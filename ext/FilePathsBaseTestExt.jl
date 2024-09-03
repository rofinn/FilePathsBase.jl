module FilePathsBaseTestExt
using Dates: Dates
using FilePathsBase
using FilePathsBase: /, join
using Test
using FilePathsBase.TestPaths

# NOTE: Most paths should test their own constructors as necessary.

function TestPaths.test_registration(ps::PathSet{P}) where {P<:AbstractPath}
    @testset "Path constructor" begin
        str = string(ps.root)
        @test tryparse(P, str) !== nothing
        @test Path(str) == ps.root
        @test p"foo/bar" == Path("foo/bar")
    end
end

function TestPaths.test_show(ps::PathSet)
    @testset "show" begin
        str = string(ps.root)
        # For windows paths
        str = replace(str, "\\" => "/")
        @test sprint(show, ps.root; context=:compat => true) == "p\"$str\""
        # TODO: Figure out why this is broken.
        @test_broken sprint(show, ps.root; context=:compat => false) == str
    end
end

function TestPaths.test_cmd(ps::PathSet)
    @testset "cmd" begin
        str = string(ps.root)
        @test `echo $str` == `echo $(ps.root)`
    end
end

function TestPaths.test_parse(ps::PathSet{P}) where {P<:AbstractPath}
    @testset "parsing" begin
        str = string(ps.root)
        @test parse(P, str) == ps.root
        @test tryparse(P, str) == ps.root
    end
end

function TestPaths.test_convert(ps::PathSet{P}) where {P<:AbstractPath}
    @testset "convert" begin
        str = string(ps.root)
        @test convert(P, str) == ps.root
        @test convert(String, ps.root) == str
    end
end

function TestPaths.test_components(ps::PathSet)
    @testset "components" begin
        str = string(ps.root)
        @test ps.root.anchor == ps.root.drive * ps.root.root
        @test ps.quux.segments[(end - 2):end] == ("bar", "qux", "quux.tar.gz")

        # Check that isless on the path segments works
        @test ps.bar < ps.foo
        @test sort([ps.foo, ps.bar, ps.fred]) == [ps.bar, ps.foo, ps.fred]
    end
end

function TestPaths.test_indexing(ps::PathSet)
    @test firstindex(ps.root) == 1
    @test lastindex(ps.root) == length(ps.root.segments)
    # `begin` indexing was only added in 1.4, so we'll leave this test commented
    # out for now as there isn't a compat for that syntax.
    # @test ps.root[begin] == ps.root.segments[1]
    @test ps.baz[end] == "baz.txt"
    @test ps.quux[(end - 2):end] == ("bar", "qux", "quux.tar.gz")
    @test ps.quux[:] == ps.quux.segments[:]
end

function TestPaths.test_iteration(ps::PathSet)
    @test eltype(ps.root) == String
    @test tuple(ps.quux...) == ps.quux.segments
    @test all(in(ps.quux), ("bar", "qux", "quux.tar.gz"))
end

function TestPaths.test_parents(ps::PathSet)
    @testset "parents" begin
        @test parent(ps.foo) == ps.root
        @test parent(ps.qux) == ps.bar
        @test dirname(ps.foo) == ps.root

        @test hasparent(ps.qux)
        _parents = parents(ps.qux)
        @test _parents[end] == ps.bar
        @test _parents[end - 1] == ps.root
        @test _parents[1] == Path(ps.root; segments=())

        # More abstract path tests for edge cases when no parent exists
        @test hasparent(p"/foo")
        @test hasparent(p"./foo")
        @test hasparent(p"~/foo")
        @test !hasparent(p"foo")
        @test !hasparent(p"~")
        @test !hasparent(p".")
        @test !hasparent(p"/")

        # Test that relative paths with no parents return p"."
        @test parent(Path(basename(ps.foo))) == p"."

        # Test that parent on p"." should be ===
        path = p"."
        @test parent(path) === path

        # Test that parent on p"/" should be ===
        path = p"/"
        @test parent(path) === path

        # Test inclusion of root in parents
        relparents = parents(PosixPath(ps.root.segments, ""))
        absparents = parents(PosixPath(ps.root.segments, "/"))
        @test relparents !== absparents
        @test length(absparents) == length(relparents) + 1
        @test !in(absparents[1], relparents)
        @test absparents[1] == PosixPath((), "/")
    end
end

function TestPaths.test_descendants_and_ascendants(ps::PathSet)
    @testset "descendants and ascendants" begin
        # Test base cases
        @test isdescendant(p"/a/b", p"/")
        @test isdescendant(p"/a/b", p"/a")
        @test isdescendant(p"/a/b/c", p"/a")
        @test isdescendant(p"/a/b", p"/a/b")
        @test !isdescendant(p"/a/b", p"/a/b/c")
        @test !isdescendant(p"/a/b", p"/c")
        @test isascendant(p"/a", p"/a/b")
        @test !isascendant(p"/a/b", p"/a")

        # Test without our path types
        @test isdescendant(ps.foo, ps.root)
        @test isdescendant(ps.qux, ps.root)
        @test isdescendant(ps.foo, ps.foo)
        @test !isdescendant(ps.root, ps.foo)
        @test !isdescendant(ps.root, ps.qux)
        @test isascendant(ps.root, ps.foo)
        @test isascendant(ps.root, ps.quux)
        @test !isascendant(ps.qux, ps.root)
    end
end

function TestPaths.test_join(ps::PathSet)
    @testset "join" begin
        @test join(ps.root, "bar") == ps.bar
        @test ps.root / "foo" / "baz.txt" == ps.baz
        @test ps.root / "foobaz.txt" == ps.root / "foo" * "baz.txt"
        @test ps.root ./ ["foo", "bar"] == [ps.foo, ps.bar]
        @test ps.root / "foo/baz.txt" == ps.baz
        @test ps.root / p"foo/baz.txt" == ps.baz
        @test ps.root / p"foo" / p"baz.txt" == ps.baz
        @test ps.root / p"foo" / "baz.txt" == ps.baz

        # TODO: Maybe normalize this case for the user? {ps.root}/foo/./baz.txt
        @test normalize(ps.root / p"foo" / "" / "baz.txt") == ps.baz

        # Check that joining absolute paths matches base
        @test ps.root / p"/foo/baz.txt" == p"/foo/baz.txt"
    end
end

function TestPaths.test_splitext(ps::PathSet)
    @testset "splitext" begin
        @test splitext(ps.foo) == (ps.foo, "")
        @test splitext(ps.baz) == (ps.foo / "baz", ".txt")
        @test splitext(ps.quux) == (ps.qux / "quux.tar", ".gz")
    end
end
function TestPaths.test_basename(ps::PathSet)
    @testset "basename" begin
        @test basename(ps.foo) == "foo"
        @test basename(ps.baz) == "baz.txt"
        @test basename(ps.quux) == "quux.tar.gz"
    end
end
function TestPaths.test_splitdir(ps::PathSet)
    @testset "splitdir" begin
        @test splitdir(ps.foo) == (ps.root, "foo")
        @test splitdir(ps.baz) == (ps.root / "foo", "baz.txt")
        @test splitdir(ps.quux) == (ps.root / "bar" / "qux", "quux.tar.gz")
    end
end

function TestPaths.test_filename(ps::PathSet)
    @testset "filename" begin
        @test filename(ps.foo) == "foo"
        @test filename(ps.baz) == "baz"
        @test filename(ps.quux) == "quux.tar"
    end
end

function TestPaths.test_extensions(ps::PathSet)
    @testset "extensions" begin
        @test extension(ps.foo) == ""
        @test extension(ps.baz) == "txt"
        @test extension(ps.quux) == "gz"
        @test extensions(ps.foo) == []
        @test extensions(ps.baz) == ["txt"]
        @test extensions(ps.quux) == ["tar", "gz"]
    end
end

function TestPaths.test_isempty(ps::PathSet{P}) where {P<:AbstractPath}
    @testset "isempty" begin
        @test !isempty(ps.foo)
        @test isempty(P())
    end
end

function TestPaths.test_normalize(ps::PathSet)
    @testset "normalize" begin
        @test normalize(ps.bar / ".." / "foo") == ps.foo
        @test normalize(ps.bar / ".") == ps.bar
        @test normpath(ps.bar / ".") == ps.bar
    end
end

function TestPaths.test_canonicalize(ps::PathSet)
    @testset "canonicalize" begin
        # NOTE: We call `canonicalize` on ps.bar in the `normalize` case because on
        # macOS the temp directory may include a symlink.
        @test canonicalize(ps.bar / ".." / "foo") ==
            normalize(canonicalize(ps.bar) / ".." / "foo")
        @test canonicalize(ps.bar / ".") == normalize(canonicalize(ps.bar) / ".")
        @test realpath(ps.bar / ".") == canonicalize(ps.bar / ".")

        if ps.plugh !== nothing
            if isa(ps.plugh, WindowsPath) && VERSION < v"1.2"
                @test_broken canonicalize(ps.plugh) == canonicalize(ps.foo)
            else
                @test canonicalize(ps.plugh) == canonicalize(ps.foo)
            end
        end
    end
end

function TestPaths.test_relative(ps::PathSet)
    @testset "relative" begin
        @test relative(ps.foo, ps.qux).segments == ("..", "..", "foo")
    end
end

function TestPaths.test_absolute(ps::PathSet)
    @testset "absolute" begin
        @test isabsolute(ps.root) || isabsolute(absolute(ps.root))
        @test absolute(ps.root) == abspath(ps.root)
    end
end

function TestPaths.test_isdir(ps::PathSet)
    @testset "isdir" begin
        @test isdir(ps.foo)
        @test !isdir(ps.baz)
    end
end

function TestPaths.test_isfile(ps::PathSet)
    @testset "isfile" begin
        @test isfile(ps.baz)
        @test !isfile(ps.foo)
    end
end

function TestPaths.test_stat(ps::PathSet)
    @testset "stat" begin
        s = stat(ps.root)
        fields = fieldnames(typeof(s))

        @test :size in fields
        @test :ctime in fields
        @test :mtime in fields
        @test :user in fields
        @test :mode in fields

        if ps.link
            @test lstat(ps.plugh) != stat(ps.plugh)
        end

        str = sprint(show, s)
    end
end

# Minimal testing of issocket, isfifo, ischardev, isblockdev and ismount which
# people won't typically include.
function TestPaths.test_issocket(ps::PathSet)
    @test !issocket(ps.root)
end

function TestPaths.test_isfifo(ps::PathSet)
    @test !isfifo(ps.root)
end

function TestPaths.test_ischardev(ps::PathSet)
    @test !ischardev(ps.root)
end

function TestPaths.test_isblockdev(ps::PathSet)
    @test !isblockdev(ps.root)
end

function TestPaths.test_ismount(ps::PathSet)
    @test !ismount(ps.root)
end

function TestPaths.test_filesize(ps::PathSet)
    @testset "filesize" begin
        @test filesize(ps.baz) > 0
    end
end

function TestPaths.test_modified(ps::PathSet)
    @testset "modified" begin
        @test isa(modified(ps.baz), Dates.AbstractDateTime)
        @test modified(ps.baz) >= modified(ps.root)
    end
end

function TestPaths.test_created(ps::PathSet)
    @testset "created" begin
        @test isa(created(ps.baz), Dates.AbstractDateTime)
        @test created(ps.baz) >= created(ps.root)
    end
end

function TestPaths.test_isexecutable(ps::PathSet{P}) where {P<:AbstractPath}
    @testset "isexecutable" begin
        # I'm not entirely sure how to test this generally
        @test !isexecutable(ps.baz)

        # Directories should be executable for system paths
        if P <: SystemPath
            @test isexecutable(ps.foo)
        end
    end
end

function TestPaths.test_isreadable(ps::PathSet)
    @testset "isreadable" begin
        # Our test files should be readable by default
        @test isreadable(ps.baz)
        @test isreadable(ps.quux)

        # Our test directories should also be readable by default
        @test isreadable(ps.foo)
        @test isreadable(ps.qux)
    end
end

function TestPaths.test_iswritable(ps::PathSet)
    @testset "iswritable" begin
        # Our test files should be writable by default
        @test iswritable(ps.baz)
        @test iswritable(ps.quux)

        # Our test directories should also be writable by default
        @test iswritable(ps.foo)
        @test iswritable(ps.qux)
    end
end

function TestPaths.test_cd(ps::PathSet{P}) where {P<:AbstractPath}
    if P <: SystemPath
        @testset "cd" begin
            init_path = canonicalize(cwd())

            cd(ps.foo) do
                cd_path = canonicalize(cwd())
                @test cd_path != init_path
                @test cd_path == canonicalize(ps.foo)
            end

            @test canonicalize(cwd()) == init_path

            cd(ps.qux)
            cd_path = canonicalize(cwd())
            @test cd_path != init_path
            @test cd_path == canonicalize(ps.qux)
            cd(init_path)
            @test canonicalize(cwd()) == init_path
        end
    end
end

function TestPaths.test_readpath(ps::PathSet)
    @testset "readpath" begin
        @test readdir(ps.root) == ["bar", "foo", "fred"]
        @test readdir(ps.qux) == ["quux.tar.gz"]
        @test readpath(ps.root) == [ps.bar, ps.foo, ps.fred]
        @test readpath(ps.qux) == [ps.quux]
    end
end

function TestPaths.test_walkpath(ps::PathSet{P}) where {P}
    @testset "walkpath" begin
        topdown = [ps.bar, ps.qux, ps.quux, ps.foo, ps.baz, ps.fred, ps.plugh]
        bottomup = [ps.quux, ps.qux, ps.bar, ps.baz, ps.foo, ps.plugh, ps.fred]

        @test collect(walkpath(ps.root; topdown=true)) == topdown
        @test collect(walkpath(ps.root; topdown=false)) == bottomup

        @test eltype(walkpath(ps.root)) == P  # should return a typed collection

        # tests consistency of definition, assume network usage acceptable
        @test diskusage(ps.root) == mapreduce(filesize, +, walkpath(ps.root))
        @test diskusage(ps.baz) == ncodeunits("Hello World!")
    end
end

function TestPaths.test_read(ps::PathSet)
    @testset "read" begin
        @test read(ps.baz, String) == "Hello World!"
        open(ps.quux, "r") do io
            @test read(io, String) == "Hello Again!"
        end
    end
end

function TestPaths.test_write(ps::PathSet)
    @testset "write" begin
        write(ps.baz, "Goodbye World!")
        @test read(ps.baz, String) == "Goodbye World!"

        @testset "truncate" begin
            open(ps.quux, "w") do io
                write(io, "Hello?")
            end
            @test read(ps.quux, String) == "Hello?"
        end

        @testset "append" begin
            open(ps.quux, "a") do io
                write(io, " Did you need something?")
            end
            @test read(ps.quux, String) == "Hello? Did you need something?"
        end

        @testset "read/write" begin
            open(ps.quux, "w+") do io
                write(io, "Goodnight!")
                seekstart(io)
                @test read(io, String) == "Goodnight!"
            end

            open(ps.quux, "a+") do io
                write(io, " Zzzz")
                seekstart(io)
                @test read(io, String) == "Goodnight! Zzzz"
            end
        end
    end
end

function TestPaths.test_mkdir(ps::PathSet)
    @testset "mkdir" begin
        garply = ps.root / "corge" / "grault" / "garply"
        @test_throws ErrorException mkdir(garply)
        @test mkdir(garply; recursive=true) == garply
        @test exists(garply)
        @test_throws ErrorException mkdir(garply; recursive=true)
        @test mkdir(garply; recursive=true, exist_ok=true) == garply
        rm(ps.root / "corge"; recursive=true)
        @test !exists(garply)
    end
end

function TestPaths.test_cp(ps::PathSet)
    @testset "cp" begin
        cp(ps.foo, ps.qux / "foo"; force=true)
        @test exists(ps.qux / "foo" / "baz.txt")
        @test_throws ArgumentError cp(ps.foo, ps.qux / "foo")
        cp(ps.foo, ps.qux / "foo"; force=true)
        rm(ps.qux / "foo"; recursive=true)

        @testset "non-existent destination parent" begin
            # Test consistency with `cp` (e.g., destination parent must exist)
            dest = ps.root / "non-existent" / "destination"

            # The base behaviour can only be tested on system paths.
            if isa(dest, SystemPath)
                if VERSION >= v"1.2"    # Error type changed in Julia 1.2
                    @test_throws ProcessFailedException run(`cp -r $(ps.foo) $dest`)
                else
                    @test_throws ErrorException run(`cp -r $(ps.foo) $dest`)
                end

                if VERSION >= v"1.4"
                    @test_throws Base.IOError cp(string(ps.foo), string(dest))
                else
                    @test_throws SystemError cp(string(ps.foo), string(dest))
                end
            end

            # TODO: Use a more specific error type
            @test_throws ErrorException cp(ps.foo, dest)
        end
    end
end

function TestPaths.test_mv(ps::PathSet)
    @testset "mv" begin
        garply = ps.root / "corge" / "grault" / "garply"
        mkdir(garply; recursive=true, exist_ok=true)
        @test exists(garply)
        mv(ps.root / "corge", ps.foo / "corge"; force=true)
        @test exists(ps.foo / "corge" / "grault" / "garply")
        rm(ps.foo / "corge"; recursive=true)
    end
end

function TestPaths.test_sync(ps::PathSet)
    @testset "sync" begin
        @testset "empty destination" begin
            sync(ps.foo, ps.qux / "foo")
            @test exists(ps.qux / "foo" / "baz.txt")

            # Test that the copied baz file has a newer modified time
            baz_t = modified(ps.qux / "foo" / "baz.txt")
            @test modified(ps.baz) < baz_t
        end

        @testset "empty source" begin
            @test_throws ArgumentError sync(ps.root / "quux", ps.foo)
        end

        @testset "new source" begin
            # Don't cp unchanged files when a new file is added
            # NOTE: sleep before we make a new file, so it's clear that the
            # modified time has changed.
            baz_t = modified(ps.qux / "foo" / "baz.txt")
            sleep(1)
            write(ps.foo / "test.txt", "New src")
            sync(ps.foo, ps.qux / "foo")
            @test exists(ps.qux / "foo" / "test.txt")
            @test read(ps.qux / "foo" / "test.txt", String) == "New src"
            @test modified(ps.qux / "foo" / "baz.txt") == baz_t
            @test modified(ps.qux / "foo" / "test.txt") > baz_t
        end

        @testset "new destination" begin
            # Newer file of the same size is likely the result of an upload which
            # will always have a newer last modified time.
            test_t = modified(ps.foo / "test.txt")
            sleep(1)
            write(ps.qux / "foo" / "test.txt", "New dst")
            @test modified(ps.qux / "foo" / "test.txt") > test_t
            sync(ps.foo, ps.qux / "foo")
            @test read(ps.qux / "foo" / "test.txt", String) == "New dst"
            @test modified(ps.qux / "foo" / "test.txt") > test_t
        end

        @testset "no delete" begin
            # Test not deleting a file on sync
            rm(ps.foo / "test.txt")
            sync(ps.foo, ps.qux / "foo")
            @test exists(ps.qux / "foo" / "test.txt")
        end

        @testset "delete" begin
            # Test passing delete flag
            sync(ps.foo, ps.qux / "foo"; delete=true)
            @test !exists(ps.qux / "foo" / "test.txt")
            rm(ps.qux / "foo"; recursive=true)
        end

        @testset "mixed types" begin
            @testset "directory -> file" begin
                @test_throws ArgumentError sync(ps.foo, ps.quux)
            end

            @testset "file -> directory" begin
                @test_throws ArgumentError sync(ps.quux, ps.foo)
            end
        end

        @testset "walkpath order" begin
            # Test a condtion where the index could reorder the walkpath order.
            tmp_src = ps.root / "tmp-src"
            mkdir(tmp_src)
            src_file = tmp_src / "file1"
            write(src_file, "Hello World!")

            src_folder = tmp_src / "folder1"
            mkdir(src_folder)
            src_folder_file = src_folder / "file2"
            write(src_folder_file, "") # empty file

            src_folder2 = src_folder / "folder2"  # nested folders
            mkdir(src_folder2)
            src_folder2_file = src_folder2 / "file3"
            write(src_folder2_file, "Test")

            tmp_dst = ps.root / "tmp_dst"
            mkdir(tmp_dst)
            sync(tmp_src, tmp_dst)
            @test exists(tmp_dst / "folder1" / "folder2" / "file3")
            rm(tmp_src; recursive=true)
            rm(tmp_dst; recursive=true)
        end

        @testset "non-existent destination parent" begin
            # Test consistency with `cp` (e.g., destination parent must exist)
            # See full `cp` comparison tests above
            dest = ps.root / "non-existent" / "destination"

            # TODO: Use a more specific error type
            @test_throws ErrorException sync(ps.foo, dest)
        end
    end
end

function TestPaths.test_symlink(ps::PathSet)
    if ps.link
        @testset "symlink" begin
            @test_throws ErrorException symlink(ps.foo, ps.plugh)
            symlink(ps.foo, ps.plugh; exist_ok=true, overwrite=true)
            symlink(ps.foo, ps.plugh; exist_ok=true)
            @test_throws ErrorException symlink(
                ps.foo / "thud", ps.plugh; exist_ok=true, overwrite=true
            )
        end
    end
end

function TestPaths.test_touch(ps::PathSet)
    @testset "touch" begin
        newfile = ps.root / "newfile"
        touch(newfile)
        @test exists(newfile)
        @test ispath(newfile)
        rm(newfile)
    end
end

function TestPaths.test_tmpname(ps::PathSet)
    @testset "tmpname" begin
        @test isa(tmpname(), AbstractPath)
        @test hasparent(tmpname())
        @test exists(parent(tmpname()))
    end
end

function TestPaths.test_tmpdir(ps::PathSet)
    @testset "tmpname" begin
        @test isa(tmpdir(), AbstractPath)
        @test exists(tmpdir())
        @test isdir(tmpdir())
    end
end

function TestPaths.test_mktmp(ps::PathSet)
    @testset "mktmp" begin
        mktmp(ps.root) do path, io
            @test exists(path)
            @test iswritable(io)
            write(io, "Foobar")
            seekstart(io)
            @test read(io, String) == "Foobar"
        end
    end
end

function TestPaths.test_mktmpdir(ps::PathSet)
    @testset "mktmpdir" begin
        mktmpdir(ps.root) do path
            @test exists(path)
            write(path / "test.txt", "Foobar")
            @test read(path / "test.txt", String) == "Foobar"
        end
    end
end

function TestPaths.test_chown(ps::PathSet)
    @testset "chown" begin
        newfile = ps.root / "newfile"
        touch(newfile)

        if haskey(ENV, "USER")
            if ENV["USER"] == "root"
                chown(newfile, "nobody", "nogroup"; recursive=true)
            elseif VERSION >= v"1.2"    # Error type changed in Julia 1.2
                @test_throws ProcessFailedException chown(
                    newfile, "nobody", "nogroup"; recursive=true
                )
            else
                @test_throws ErrorException chown(
                    newfile, "nobody", "nogroup"; recursive=true
                )
            end
        end

        rm(newfile)
    end
end

function TestPaths.test_chmod(ps::PathSet)
    @testset "chmod" begin
        newfile = ps.root / "newfile"
        newpath = ps.root / "thud"

        touch(newfile)
        mkdir(newpath)
        chmod(newfile; user=(READ + WRITE + EXEC), group=(READ + EXEC), other=READ)
        @test string(mode(newfile)) == "-rwxr-xr--"
        @test isexecutable(newfile)
        @test iswritable(newfile)
        @test isreadable(newfile)

        chmod(newfile, "-x")
        @test !isexecutable(newfile)

        @test string(mode(newfile)) == "-rw-r--r--"
        chmod(newfile, "+x")
        write(newfile, "foobar")
        @test read(newfile, String) == "foobar"
        chmod(newfile, "u=rwx")

        open(newfile, "r") do io
            @test read(io, String) == "foobar"
        end

        chmod(newpath, mode(newfile); recursive=true)
    end
end

function TestPaths.test_download(ps::PathSet)
    @testset "download" begin
        rm(ps.foo / "README.md"; force=true)
        download(
            "https://github.com/rofinn/FilePathsBase.jl/blob/master/README.md",
            ps.foo / "README.md",
        )
        @test exists(ps.foo / "README.md")

        # Test downloading from another path
        download(ps.foo / "README.md", ps.qux / "README.md")
        @test exists(ps.qux / "README.md")

        # Test downloading to a string
        download(ps.foo / "README.md", string(ps.fred / "README.md"))
        @test exists(ps.fred / "README.md")
        rm.([ps.foo / "README.md", ps.qux / "README.md", ps.fred / "README.md"])
    end
end

function TestPaths.test_include(ps::PathSet)
    @testset "include" begin
        write(ps.quux, "2 + 2\n")
        res = include(ps.quux)
        @test res == 4
    end
end
end
