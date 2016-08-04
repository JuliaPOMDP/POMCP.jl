# POMCP.jl

The Partially Observable Monte Carlo Planning (POMCP) online solver for POMDPs.jl.

Described in

Silver, D., & Veness, J. (2010). Monte-Carlo Planning in Large POMDPs. In *Advances in neural information processing systems* (pp. 2164–2172). Retrieved from http://discovery.ucl.ac.uk/1347369/

## Installation

See [README.md](https://github.com/JuliaPOMDP/POMCP.jl/blob/master/README.md) on the [Github repo](https://github.com/JuliaPOMDP/POMCP.jl).

## Documentation

### Basics

This implementation of the POMCP solver may be used to solve POMDPs defined according to the [POMDPs.jl](https://github.com/sisl/POMDPs.jl) interface. Note that this is an online solver, so the computation is carried out as the simulation is running (simulations take a long time, but `solve` takes no time).

For a usage example, see the [Basic Usage](https://github.com/sisl/POMCP.jl/blob/master/notebooks/Basic_Usage.ipynb) notebook. For some more (poorly documented) examples, see the [Sanity Checks](https://github.com/sisl/POMCP.jl/blob/master/notebooks/Sanity_Checks.ipynb) notebook.

Behavior is controlled through two mechanisms: [solver options](@ref Solver) and [method specializations](@ref Methods).

### Belief Updates

By default, POMCP uses an unweighted particle filter for belief updates as discussed in the original paper describing it. However, this implementation can use any Updater to keep track of the belief. A notebook describing the various belief updater options and features can be viewed here: [http://nbviewer.jupyter.org/github/JuliaPOMDP/POMCP.jl/blob/master/notebooks/Belief_and_Particle_Filter_Options.ipynb](http://nbviewer.jupyter.org/github/JuliaPOMDP/POMCP.jl/blob/master/notebooks/Belief_and_Particle_Filter_Options.ipynb)

### [Tree Visualization](@id Tree)

Interactive visualization of the POMCP tree is available in Jupyter notebooks. Run the Display Tree notebook in the notebooks folder for a demonstration, or view it here: [http://nbviewer.jupyter.org/github/JuliaPOMDP/POMCP.jl/blob/master/notebooks/Display_Tree.ipynb](http://nbviewer.jupyter.org/github/JuliaPOMDP/POMCP.jl/blob/master/notebooks/Display_Tree.ipynb)

In order to display a tree, create a POMCPTreeVisualizer with any BeliefNode. If the last line of a cell in a Jupyter notebook returns a POMCPTreeVisualizer, the output cell will be populated with html and javascript that display the tree. See the documentation for MCTS.jl for more detailed information about the tree and instructions describing how to customize its appearance. In particular, the `node_tag` and `tooltip_tag` functions can be overridden to customize how actions and observations are displayed.
