using Documenter, SolarLEDs

makedocs(
    modules = [SolarLEDs],
    format = Documenter.HTML(),
    checkdocs = :exports,
    sitename = "SolarLEDs.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/yakir12/SolarLEDs.jl.git",
)
