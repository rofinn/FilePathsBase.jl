using Documenter, FilePathsBase, FilePathsBase.TestPaths

```@meta
DocTestSetup = quote
    using FilePathsBase; using FilePathsBase: /, join;
end
```

makedocs(
    modules=[FilePathsBase],
    format=Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    pages=[
        "Home" => "index.md",
        "Design" => "design.md",
        "FAQ" => "faq.md",
        "API" => "api.md",
    ],
    repo="https://github.com/rofinn/FilePathsBase.jl/blob/{commit}{path}#L{line}",
    sitename="FilePathsBase.jl",
    authors="Rory Finnegan",
    checkdocs = :exports,
    # strict = true,
)

deploydocs(
    repo = "github.com/rofinn/FilePathsBase.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
