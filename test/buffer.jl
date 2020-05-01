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

        io = FileBuffer(p)
        try
            for b in read(p)
                @test read(io, UInt8) == b
            end
            @test eof(io)
        finally
            close(io)
        end
    end

    @testset "write" begin
        mktmpdir() do d
            p1 = absolute(p"../README.md")

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

                rm(p2)

                io = FileBuffer(p2; read=true,write=true)
                try
                    write(io, read(p1))
                    flush(io)

                    seekstart(io)
                    for b in read(p1)
                        write(io, b)
                    end
                    flush(io)
                    @test read(p1) == read(p2)
                finally
                    close(io)
                end
            end
        end
    end

    @testset "Custom Types" begin
        jlso = JLSOFile(:msg => "Hello World!")
        mktmpdir() do d
            cd(d) do
                write(p"hello_world.jlso", jlso)
                new_jlso = read(p"hello_world.jlso", JLSOFile)
                @test new_jlso[:msg] == "Hello World!"

                rm(p"hello_world.jlso")
                data = IOBuffer()
                write(data, jlso)
                open(p"hello_world.jlso", "w") do io
                    for x in take!(data)
                        write(io, x)
                    end
                end


                open(p"hello_world.jlso") do io
                    data = UInt8[]
                    push!(data, read(io, UInt8))

                    while !eof(io)
                        push!(data, read(io, UInt8))
                    end

                    new_jlso = read(IOBuffer(data), JLSOFile)
                    @test new_jlso[:msg] == "Hello World!"
                end
            end
        end
    end
end
