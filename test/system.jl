ps = TestPaths.PathSet()

@testset "$(typeof(ps.root))" begin
    # Run all of the automated tests
    TestPaths.test(ps)

    # TODO: Copy over specific tests that can't be tested reliably from the general case.
end
