using FilePathsBase
using FilePathsBase: /, join
using Base.Filesystem
using Dates: datetime2unix
using JLSO
using Test

using FilePathsBase.TestPaths

include("testpkg.jl")

@testset "FilePathsBase" begin
    include("mode.jl")
    include("buffer.jl")
    include("system.jl")

    @static if Sys.isunix()
        # Test that our weird registered path works
        ps = PathSet(TestPkg.posix2test(tmpdir()) / "pathset_root"; symlink=true)

        @testset "$(typeof(ps.root))" begin
            testsets = [
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
                test_symlink,
                test_touch,
                test_tmpname,
                test_tmpdir,
                test_mktmp,
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
