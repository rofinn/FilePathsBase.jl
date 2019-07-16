ps = PathSet()

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
        test_download,
    ]

    if isa(ps.root, PosixPath)
        append!(testsets, [test_chown, test_chmod])
    end

    # Run all of the automated tests
    test(ps)

    # TODO: Copy over specific tests that can't be tested reliably from the general case.
end
