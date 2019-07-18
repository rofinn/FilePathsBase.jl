using FilePathsBase: FileBuffer

@testset "FileBuffer Tests" begin
    @testset "read" begin
        p = p"../README.md"
        io = FileBuffer(p)
        try
            @test isreadable(io)
            @test !iswritable(io)
            @test eof(io)
            @test read(p) == read(io)
            @test eof(io)
            seekstart(io)
            @test !eof(io)
            @test read(p, String) == read(io, String)
            @test eof(io)
        finally
            close(io)
        end
    end

    @testset "write" begin
        mktmpdir() do d
            p1 = abs(p"../README.md")

            cd(d) do
                p2 = p"README.md"
                cp(p1, p2)

                io = FileBuffer(p2; read=true,write=true)
                try
                    @test isreadable(io)
                    @test iswritable(io)
                    @test eof(io)
                    @test read(p1) == read(io)
                    write(io, "\nHello")
                    write(io, " World!\n")
                    flush(io)

                    txt1 = read(p1, String)
                    txt2 = read(p2, String)
                    @test txt1 != txt2
                    @test occursin(txt1, txt2)
                    @test occursin("Hello World!", txt2)
                finally
                    close(io)
                end
            end
        end
    end
end
