
cd(abs(parent(Path(@__FILE__)))) do
    @testset "Simple Path Usage" begin
        reg = Sys.iswindows() ? "..\\src\\FilePathsBase.jl" : "../src/FilePathsBase.jl"
        @test ispath(reg)

        p = Path(reg)

        @test p == p"../src/FilePathsBase.jl"
        @test string(p) == reg
        @test string(cwd()) == pwd()
        @test string(home()) == homedir()

        @test path(p) == ("..", "src", "FilePathsBase.jl")
        @test hasparent(p)
        @test parent(p) == p"../src"
        @test parents(p) == [p"..", p"../src"]
        @test_throws ErrorException parents(p".")

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
        @test !isabs(p)
        @test string(norm(p"../src/../src/FilePathsBase.jl")) == normpath("../src/../src/FilePathsBase.jl")
        @test string(abs(p)) == abspath(string(p))
        @test sprint(show, p"../README.md") == "p\"../README.md\""

        # This works around an issue with Base.relpath: that function does not take
        # into account the paths on Windows should be compared case insensitive.
        homedir_patched = homedir()
        if Sys.iswindows()
            conv_f = isuppercase(abspath(string(p))[1]) ? uppercase : lowercase
            homedir_patched = conv_f(homedir_patched[1]) * homedir_patched[2:end]
        end
        @test string(relative(p, home())) == relpath(string(p), homedir_patched)

        @test isa(relative(Path(".")), AbstractPath)
        @test relative(Path(".")) == Path(".")

        @test real(p"../test/mode.jl") == Path(realpath("../test/mode.jl"))

        s = stat(p)
        lstat(p)

        show_str = sprint(show, s)
        #@test "device" in show_str
        #@test "blocks" in show_str

        @test size(p) == stat(p).size
        @test modified(p) == stat(p).mtime
        @test created(p) == stat(p).ctime

        @test isfile(p)
        @test isdir(parent(p))
        @test !islink(p)
        @test !issocket(p)
        @test !isfifo(p)
        @test !ischardev(p)
        @test !isblockdev(p)

        p1 = WindowsPath(tuple(["\\", "foo", "bar"]...))
        @test p1.path == ("foo", "bar")
        @test p1.drive == ""
        @test p1.root == "\\"

        p2 = WindowsPath(tuple(["C:\\", "foo", "bar"]...))
        @test p2.path == ("foo", "bar")
        @test p2.drive == "C:"
        @test p2.root == "\\"

        p3 = WindowsPath(tuple(["C:", "foo", "bar"]...))
        @test p3.path == ("foo", "bar")
        @test p3.drive == "C:"
        @test p3.root == ""

        p4 = WindowsPath(tuple(["foo", "bar"]...))
        @test p4.path == ("foo", "bar")
        @test p4.drive == ""
        @test p4.root == ""

        @test @__PATH__() == Path(@__DIR__)
        @test @__FILEPATH__() == Path(@__FILE__)
        @test FilePathsBase.@LOCAL("foo.txt") == join(@__PATH__, "foo.txt")
        @test FilePathsBase.@LOCAL("foo.txt") == joinpath(@__PATH__, "foo.txt")

        @testset "path nesting" begin
            @test true == isdescendent(p"/a/b", p"/")
            @test true == isdescendent(p"/a/b", p"/a")
            @test true == isdescendent(p"/a/b", p"/a/b")
            @test false == isdescendent(p"/a/b", p"/a/b/c")
            @test false == isdescendent(p"/a/b", p"/c")

            @test true == isascendant(p"/a", p"/a/b")
            @test false == isascendant(p"/a/b", p"/a")
        end

    end
end

mktmpdir() do d
    cd(d) do
        @testset "Modifying Path Usage" begin
            new_path = p"foo"

            mkdir(new_path)
            @test_throws ErrorException mkdir(new_path)
            remove(new_path)

            new_path = p"foo/bar"
            @test_throws ErrorException mkdir(new_path)
            mkdir(new_path; recursive=true)
			@test exists(new_path)
            mkdir(new_path; recursive=true, exist_ok=true)

            other_path = p"car/bar"
            copy(new_path, other_path; recursive=true)
            copy(new_path, other_path; exist_ok=true, overwrite=true)
            @test_throws ErrorException copy(new_path, other_path)
            @test_throws ErrorException copy(p"badpath", other_path; exist_ok=true, overwrite=true)
            remove(p"car"; recursive=true)

            move(new_path, other_path; recursive=true)
            mkdir(new_path; recursive=true)
            move(new_path, other_path; exist_ok=true, overwrite=true)
            @test_throws ErrorException move(new_path, other_path)
            @test_throws ErrorException move(p"badpath", other_path; exist_ok=true, overwrite=true)
            remove(p"car"; recursive=true)

            mkdir(new_path; recursive=true)

            symlink(new_path, p"mysymlink")
            symlink(new_path, p"mysymlink"; exist_ok=true, overwrite=true)
            @test_throws ErrorException symlink(new_path, p"mysymlink")
            @test_throws ErrorException symlink(p"badpath", p"mysymlink"; exist_ok=true, overwrite=true)

            touch(p"newfile")
            mktmp(d) do f, io
                println(f)
                println(io)
            end

            @static if Sys.isunix()
                if haskey(ENV, "USER")
                    if ENV["USER"] == "root"
                        chown(p"newfile", "nobody", "nogroup"; recursive=true)
                    else
                        @test_throws ErrorException chown(p"newfile", "nobody", "nogroup"; recursive=true)
                    end
                end
            else
                @test_throws ErrorException chown(p"newfile", "nobody", "nogroup"; recursive=true)
            end

            @static if Sys.isunix()
                chmod(p"newfile", user=(READ+WRITE+EXEC), group=(READ+EXEC), other=READ)
                @test string(mode(p"newfile")) == "-rwxr-xr--"
                @test isexecutable(p"newfile")
                @test iswritable(p"newfile")
                @test isreadable(p"newfile")

                chmod(p"newfile", "-x")
                @test !isexecutable(p"newfile")

                @test string(mode(p"newfile")) == "-rw-r--r--"
                chmod(p"newfile", "+x")
                write(p"newfile", "foobar")
                @test read(p"newfile", String) == "foobar"
                chmod(p"newfile", "u=rwx")

                open(p"newfile") do io
                    @test read(io, String) == "foobar"
                end

                chmod(new_path, mode(p"newfile"); recursive=true)
            end

            download(
                "https://github.com/rofinn/FilePathsBase.jl/blob/master/README.md",
                p"./README.md"
            )

            @test exists(p"./README.md")
        end
    end
end
