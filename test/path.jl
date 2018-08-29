
cd(abs(parent(Path(@__FILE__)))) do
    @testset "Simple Path Usage" begin
        reg = Compat.Sys.iswindows() ? "..\\src\\FilePathsBase.jl" : "../src/FilePathsBase.jl"
        @test ispath(reg)

        p = Path(reg)

        @test p == p"../src/FilePathsBase.jl"
        @test String(p) == reg
        @test String(cwd()) == pwd()
        @test String(home()) == homedir()

        @test parts(p) == ("..", "src", "FilePathsBase.jl")
        @test hasparent(p)
        @test parent(p) == p"../src"
        @test parents(p) == [p"..", p"../src"]
        @test_throws ErrorException parents(p".")

        @test basename(p) == "FilePathsBase.jl"
        @test join(parent(p), Path(basename(p))) == p
        @test filename(p) == "FilePathsBase"

        @test extension(p) == "jl"
        @test extension(p"../REQUIRE") == ""
        @test extensions(p"foo.tar.gz") == ["tar", "gz"]
        @test length(extensions(p"../REQUIRE")) == 0

        @test exists(p)
        @test !isabs(p)
        @test String(norm(p"../src/../src/FilePathsBase.jl")) == normpath("../src/../src/FilePathsBase.jl")
        @test String(abs(p)) == abspath(String(p))
        # This works around an issue with Base.relpath: that function does not take
        # into account the paths on Windows should be compared case insensitive.
        homedir_patched = homedir()
        if Compat.Sys.iswindows()
            conv_f = isuppercase(abspath(String(p))[1]) ? uppercase : lowercase
            homedir_patched = conv_f(homedir_patched[1]) * homedir_patched[2:end]
        end
        @test String(relative(p, home())) == relpath(String(p), homedir_patched)

        @test isa(relative(Path(".")), AbstractPath)
        @test relative(Path(".")) == Path(".")

        @test endswith(p, ".jl")

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
        @test p1.parts == ("\\", "foo", "bar")
        @test p1.drive == ""
        @test p1.root == "\\"

        p2 = WindowsPath(tuple(["C:\\", "foo", "bar"]...))
        @test p2.parts == ("C:\\", "foo", "bar")
        @test p2.drive == "C:"
        @test p2.root == "\\"

        p3 = WindowsPath(tuple(["C:", "foo", "bar"]...))
        @test p3.parts == ("C:", "foo", "bar")
        @test p3.drive == "C:"
        @test p3.root == ""

        p4 = WindowsPath(tuple(["foo", "bar"]...))
        @test p4.parts == ("foo", "bar")
        @test p4.drive == ""
        @test p4.root == ""

        @test @__PATH__() == Path(@__DIR__)
        @test @__FILEPATH__() == Path(@__FILE__)
        @test FilePathsBase.@LOCAL("foo.txt") == join(@__PATH__, "foo.txt")
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

            @static if Compat.Sys.isunix()
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

            @static if Compat.Sys.isunix()
                chmod(p"newfile", user=(READ+WRITE+EXEC), group=(READ+EXEC), other=READ)
                @test String(mode(p"newfile")) == "-rwxr-xr--"
                @test isexecutable(p"newfile")
                @test iswritable(p"newfile")
                @test isreadable(p"newfile")

                chmod(p"newfile", "-x")
                @test !isexecutable(p"newfile")

                @test String(mode(p"newfile")) == "-rw-r--r--"
                chmod(p"newfile", "+x")
                write(p"newfile", "foobar")
                @test read(p"newfile") == "foobar"
                chmod(p"newfile", "u=rwx")

                chmod(new_path, mode(p"newfile"); recursive=true)
            end
        end
    end
end
