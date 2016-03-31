using Documenter, POMCP

makedocs(modules=POMCP)

deploydocs(
    repo = "github.com/JuliaPOMDP/POMCP.jl.git",
    julia = "release",
    osname = "linux"
)
