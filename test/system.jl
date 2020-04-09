ps = PathSet(; symlink=true)

@testset "$(typeof(ps.root))" begin
    testsets = [
        test_constructor,
        test_registration,
        test_show,
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
    ]

    if isa(ps.root, PosixPath)
        append!(
            testsets,
            [
                test_issocket,
                test_isfifo,
                test_ischardev,
                test_isblockdev,
                test_ismount,
                test_isexecutable,
                test_isreadable,
                test_iswritable,
                test_chown,
                test_chmod,
            ]
        )
    end

    # Run all of the automated tests
    test(ps, testsets)

    # Test the system path specific macros, behaviour and properties
    cd(absolute(parent(Path(@__FILE__)))) do
        @testset "Simple System Path Usage" begin
            reg = Sys.iswindows() ? "..\\src\\FilePathsBase.jl" : "../src/FilePathsBase.jl"
            @test ispath(reg)

            p = Path(reg)

            @test p == p"../src/FilePathsBase.jl"
            @test string(p) == reg
            @test string(cwd()) == pwd()
            @test string(home()) == homedir()

            @test p.segments == ("..", "src", "FilePathsBase.jl")
            @test hasparent(p)
            @test parent(p) == p"../src"
            @test parents(p) == [p"..", p"../src"]
            @test parents(p".") == [p"."]

            @test basename(p) == "FilePathsBase.jl"
            @test join(parent(p), Path(basename(p))) == p
            @test joinpath(parent(p), Path(basename(p))) == p
            @test parent(p) / basename(p) == p
            @test parent(p) * "/" * basename(p) == p
            @test p"foo" / "bar" * ".txt" == p"foo/bar.txt"
            @test filename(p) == "FilePathsBase"

            @test extension(p) == "jl"
            @test extension(p"../REQUIRE") == ""
            @test extensions(p"foo.tar.gz") == ["tar", "gz"]
            @test length(extensions(p"../REQUIRE")) == 0

            @test exists(p)
            @test !isabsolute(p)
            @test string(normalize(p"../src/../src/FilePathsBase.jl")) == normpath("../src/../src/FilePathsBase.jl")
            @test string(absolute(p)) == abspath(string(p))
            @test sprint(show, p"../README.md") == "p\"../README.md\""

            # This works around an issue with Base.relpath: that function does not take
            # into account the paths on Windows should be compared case insensitive.
            homedir_patched = homedir()
            if Sys.iswindows()
                conv_f = isuppercase(abspath(string(p))[1]) ? uppercase : lowercase
                homedir_patched = conv_f(homedir_patched[1]) * homedir_patched[2:end]
            elseif Sys.isunix()
                contracted_path = p"~/opt/foo/bar.jl"
                expanded_path = joinpath(home(), "opt/foo/bar.jl")
                @test expanduser(contracted_path) == expanded_path
                @test contractuser(expanded_path) == contracted_path
            end

            @test string(relative(p, home())) == relpath(string(p), homedir_patched)

            @test isa(relative(Path(".")), AbstractPath)
            @test relative(Path(".")) == Path(".")

            @test canonicalize(p"../test/mode.jl") == Path(realpath("../test/mode.jl"))

            s = stat(p)
            lstat(p)

            show_str = sprint(show, s)
            #@test "device" in show_str
            #@test "blocks" in show_str

            @test filesize(p) == stat(p).size
            @test modified(p) == stat(p).mtime
            @test created(p) == stat(p).ctime

            @test isfile(p)
            @test isdir(parent(p))
            @test !islink(p)
            @test !issocket(p)
            @test !isfifo(p)
            @test !ischardev(p)
            @test !isblockdev(p)

            p1 = WindowsPath(("foo", "bar"))
            @test p1.segments == ("foo", "bar")
            @test p1.drive == ""
            @test p1.root == ""

            p2 = WindowsPath(("foo", "bar"); root="\\", drive="C:")
            @test p2.segments == ("foo", "bar")
            @test p2.drive == "C:"
            @test p2.root == "\\"

            p3 = WindowsPath(("foo", "bar"); drive="C:")
            @test p3.segments == ("foo", "bar")
            @test p3.drive == "C:"
            @test p3.root == ""

            p4 = WindowsPath("C:\\User\\Documents")
            @test p4.segments == ("User", "Documents")
            @test p4.drive == "C:"
            @test p4.root == "\\"

            @test @__PATH__() == Path(@__DIR__)
            @test @__FILEPATH__() == Path(@__FILE__)
            @test FilePathsBase.@LOCAL("foo.txt") == join(@__PATH__, "foo.txt")
            @test FilePathsBase.@LOCAL("foo.txt") == joinpath(@__PATH__, "foo.txt")
        end
    end
end
