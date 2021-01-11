# PH4GEPMs
A simple implementation of progressive hedging as applied to a generation expansion planning model.

To try it out, just clone (download) this repository and run one of the scripts:
```julia
shell> git clone https://github.com/junglegobs/PH4GEPMs.git
shell> cd PH4GEPMs
pkg> activate .
julia> include("init.jl")
julia? include(joinpath(@__DIR__, "scripts", "simplest_PH.jl"))
```
Tip: to get to the shell, type `;` in the Julia REPL. Similarly to get to the package manager, type `]`

Then you should be able 

For a reference to progressive hedging, [see here](https://pdfs.semanticscholar.org/f75f/ed76db11997b66093099f1a933e2f59e7306.pdf). For generation expansion planning models, see e.g. [this paper](https://www.mech.kuleuven.be/en/tme/research/energy-systems-integration-modeling/pdf-publications/wp-esim2020-03).
