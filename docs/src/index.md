# POMCP.jl

The Partially Observable Monte Carlo Planning (POMCP) online solver for POMDPs.jl.

Described in

Silver, D., & Veness, J. (2010). Monte-Carlo Planning in Large POMDPs. In *Advances in neural information processing systems* (pp. 2164–2172). Retrieved from http://discovery.ucl.ac.uk/1347369/

## Installation

See [README.md](https://github.com/JuliaPOMDP/POMCP.jl/blob/master/README.md) on the [Github repo](https://github.com/JuliaPOMDP/POMCP.jl).

## Documentation

This implementation of the POMCP solver may be used to solve POMDPs defined according to the [POMDPs.jl](https://github.com/sisl/POMDPs.jl) interface. Note that this is an online solver, so the computation is carried out as the simulation is running (simulations take a long time, but `solve` takes no time).

For a usage example, see the [Basic Usage](https://github.com/sisl/POMCP.jl/blob/master/notebooks/Basic_Usage.ipynb) notebook. For some more (poorly documented) examples, see the [Sanity Checks](https://github.com/sisl/POMCP.jl/blob/master/notebooks/Sanity_Checks.ipynb) notebook.

Behavior is controlled through two mechanisms: [solver options](@ref Solver) and [method specializations](@ref Methods).

There is also an interactive [search tree visualizer](@ref Tree).
