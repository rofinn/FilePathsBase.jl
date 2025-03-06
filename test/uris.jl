using URIs
using FilePathsBase

@testset "URIs" begin
    @test string(URIs.URI(p"/foo/bar")) == "file:///foo/bar"
    @test string(URIs.URI(p"/foo foo/bar")) == "file:///foo%20foo/bar"
    @test_throws ArgumentError URIs.URI(p"foo/bar")
    @test string(URIs.URI(WindowsPath("C:\\foo\\bar"))) == "file:///C:/foo/bar"
    @test string(URIs.URI(p"/foo/bar", query="querypart", fragment="fragmentpart")) == "file:///foo/bar?querypart#fragmentpart"
end
