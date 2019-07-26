ps = PathSet(; symlink=true)

@testset "$(typeof(ps.root))" begin
    testsets = [
        test_constructor,
        test_registration,
        test_show,
        test_parse,
        test_convert,
        test_components,
        test_parents,
        test_join,
        test_basename,
        test_filename,
        test_extensions,
        test_isempty,
        test_norm,
        test_real,
        test_relative,
        test_abs,
        test_isdir,
        test_isfile,
        test_stat,
        test_size,
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

    # Test the system path specific macros
    cd(abs(parent(Path(@__FILE__)))) do
        @test @__PATH__() == Path(@__DIR__)
        @test @__FILEPATH__() == Path(@__FILE__)
        @test FilePathsBase.@LOCAL("foo.txt") == join(@__PATH__, "foo.txt")
        @test FilePathsBase.@LOCAL("foo.txt") == joinpath(@__PATH__, "foo.txt")
    end
end
