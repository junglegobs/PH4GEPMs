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
To run the scripts in a distributed fashion, you need to do the following:
```julia
julia> include("<full_path_to_PH4GEPMs>/init.jl")
julia> include(joinpath(ROOT_DIR, "scripts", "distributed_PH.jl"))
```
Note that `distributed_PH.jl` calls the `init.jl` function each time (TODO: make another init script for distributed jobs).

## References
For a reference to progressive hedging, [see here](https://pdfs.semanticscholar.org/f75f/ed76db11997b66093099f1a933e2f59e7306.pdf). For generation expansion planning models, see e.g. [this paper](https://www.mech.kuleuven.be/en/tme/research/energy-systems-integration-modeling/pdf-publications/wp-esim2020-03).

## Solver choice
Usually I would just use Gurobi, but that's paid software (though academics get free licenses). So I had a bit of an experiment with solvers, for which I give a summary here:
* `Cbc`: Good MILP solver, can't deal with quadratic objective however so unsuitable for progressive hedging.
* `Ipopt`: Takes ages to solve subproblems, don't think it's tuned for quadratic problems.
* `COSMO`: Cool that this is written in pure Julia and uses ADMM to decompose subproblems. In practice, it's really slow and often reaches the maximum iteration limit which breaks the PH algorithm. Also I'm not sure whether using ADMM on the subproblems would be a good idea anyway.
* `CSDP`: Like `Cbc`, this is from the COIN-OR project. 
* `SCS`:
* `SDPA`: 
* `HiGHS`: Could outperform `Cbc`, but similarly it can only handle linear problems. The wrapper for it also doesn't seem to be registered.

## Performance
Using `optimizer_with_attributes(COSMO.Optimizer, "verbose" => true, "eps_abs" => 1e-1)` for subproblems, for 15 years of demand data, only thermal generators, 16 workers (CPUs), for master problem `rtol=1e-4`, `atol=1e-2`, I obtained the following computation time:

```
 ─────────────────────────────────────────────────────────────────────────────────────
                                              Time                   Allocations      
                                      ──────────────────────   ───────────────────────
           Tot / % measured:               1822s / 100%            1.83GiB / 85.3%    

 Section                      ncalls     time   %tot     avg     alloc   %tot      avg
 ─────────────────────────────────────────────────────────────────────────────────────
 Solution                          1    1496s  82.3%   1496s    922MiB  57.8%   922MiB
   Solve subproblems              14    1491s  82.1%    107s   1.35MiB  0.08%  98.6KiB
   Update PH Vars                 15    2.07s  0.11%   138ms   9.26MiB  0.58%   632KiB
   Update PH leaf variables        1    1.75s  0.10%   1.75s    900MiB  56.5%   900MiB
   Fix PH variables               14    658ms  0.04%  47.0ms   9.64MiB  0.60%   705KiB
 Intialization                     1     321s  17.7%    321s    673MiB  42.2%   673MiB
   Compute start values            1     302s  16.6%    302s   2.53MiB  0.16%  2.53MiB
   Submodel construction           1    16.7s  0.92%   16.7s    622MiB  39.0%   622MiB
     Create models                 1    10.6s  0.58%   10.6s   9.62MiB  0.60%  9.62MiB
     Collect variables             1    6.11s  0.34%   6.11s    613MiB  38.4%   613MiB
   Augment objectives              1    1.88s  0.10%   1.88s   6.26MiB  0.39%  6.26MiB
 ─────────────────────────────────────────────────────────────────────────────────────
```

To solve the extensive (i.e. undecomposed problem, presumably with one worker?) with default `COSMO.Optimizer` settings I got: