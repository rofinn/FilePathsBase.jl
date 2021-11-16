using FilePathsBase
using FilePathsBase: /, join
using Base.Filesystem
using Dates: datetime2unix
using JLSO
using Mmap
using Random
using Test

using FilePathsBase.TestPaths

include("testpkg.jl")

function test_mktmp_collisions(ps::PathSet)
    # https://github.com/rofinn/FilePathsBase.jl/issues/142
    @testset "mktemp collisions" begin
        temp_root = ps.root / "tmp"
        try
            mkdir(temp_root)
            # Create a set of of temp files that we don't cleanup
            # set the RNG so that they intentionally collide and trigger
            # our error conditions
            Random.seed!(FilePathsBase.RNG, 0)
            for i = 1:4
                fp, io = mktemp(temp_root)
                close(io)
            end

            Random.seed!(FilePathsBase.RNG, 0)
            @test_throws ErrorException mktemp(temp_root)
        finally
            rm(temp_root, recursive=true)
        end
    end
end

@testset "FilePathsBase" begin
    include("mode.jl")
    include("buffer.jl")
    include("system.jl")

    @static if Sys.isunix()
        # Test that our weird registered path works
        ps = PathSet(TestPkg.posix2test(tmpdir()) / "pathset_root"; symlink=true)

        @testset "`propertynames`" begin
            @test propertynames(ps.root) == (:drive, :root, :anchor, :separator)
            @test propertynames(ps.root, true) == (:drive, :root, :anchor, :separator, :segments)
        end

        @testset "$(typeof(ps.root))" begin
            testsets = [
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
                test_mktmp_collisions,
                test_mktmpdir,
                test_download,
                test_issocket,
                # These will also all work for our custom path type,
                # but many implementations won't support them.
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

            # Run all of the automated tests
            test(ps, testsets)
        end
    end
end
