using ASN1
using Documenter

DocMeta.setdocmeta!(ASN1, :DocTestSetup, :(using ASN1); recursive=true)

makedocs(;
    modules=[ASN1],
    authors="NegaScout",
    sitename="ASN1.jl",
    format=Documenter.HTML(;
        canonical="https://NegaScout.github.io/ASN1.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/NegaScout/ASN1.jl",
    devbranch="main",
)
