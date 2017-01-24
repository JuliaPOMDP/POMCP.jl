using Documenter, POMCP

makedocs(modules=[POMCP])

deploydocs(
    deps = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/JuliaPOMDP/POMCP.jl.git",
    julia = "0.5",
    osname = "linux"
)
