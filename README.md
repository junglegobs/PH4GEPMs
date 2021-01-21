# PH4GEPMs
A simple implementation of progressive hedging as applied to a generation expansion planning model.

## Setup
To try it out, just clone (download) this repository and run one of the scripts:
```julia
shell> git clone https://github.com/junglegobs/PH4GEPMs.git
shell> cd PH4GEPMs
pkg> activate .
julia> include("init.jl")
julia? include(joinpath(@__DIR__, "scripts", "simplest_PH.jl"))
```
Tip: to get to the shell, type `;` in the Julia REPL. Similarly to get to the package manager, type `]`

## Distributed optimisations setup
To solve the problem distributedly (not a word) using all the cores of your computer, you need to do the following:
```julia
julia> using Distributed
shell> cd <path_to_PH4GEPMs>
julia> @everywhere include(joinpath("init.jl"))
julia> include(joinpath("scripts", "distributed_PH.jl"))
```

## References
For a reference to progressive hedging, [see here](https://pdfs.semanticscholar.org/f75f/ed76db11997b66093099f1a933e2f59e7306.pdf). For generation expansion planning models, see e.g. [this paper](https://www.mech.kuleuven.be/en/tme/research/energy-systems-integration-modeling/pdf-publications/wp-esim2020-03).

## Solver choice
Usually I would just use Gurobi, but that's paid software (though academics get free licenses). So I had a bit of an experiment with solvers, for which I give a summary here:
* `Cbc`: Good MILP solver, can't deal with quadratic objective however so unsuitable for progressive hedging.
* `Ipopt`: Takes ages to solve subproblems, don't think it's tuned for quadratic problems.
* `COSMO`: Cool that this is written in pure Julia and uses ADMM to decompose subproblems. In practice, it's really slow and often reaches the maximum iteration limit which breaks the PH algorithm. Also I'm not sure whether using ADMM on the subproblems would be a good idea anyway.
* `CSDP`: Like `Cbc`, this is from the COIN-OR project. Led to memory issues / Julia breaking.
* `SCS`: Works and was relatively fast for the linear problem if you set "eps" => 1e-3 (I think this is the relative difference between the primal and dual objectives, but not sure). Can't handle quadratic objectives though.
* `SDPA`: Broke a bunch of packages unfortunately.
* `HiGHS`: Could outperform `Cbc`, but similarly it can only handle linear problems. The wrapper for it also doesn't seem to be registered.

## Performance