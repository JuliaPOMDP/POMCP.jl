module POMCP

import POMDPs

import POMDPs: action, solve, create_policy
import Base.rand
import POMDPs: update, updater, create_belief, initialize_belief
import POMDPToolbox
import GenerativeModels

export
    POMCPSolver,
    POMCPUpdater,
    POMCPPlanner,
    BeliefNode,
    RootNode,
    ObservationNode,
    solver,
    action,
    create_policy,
    update,
    updater,
    create_belief,
    init_V,
    init_N,
    sparse_actions,
    estimate_value,
    extract_belief,
    POMCPTreeVisualizer

"""
The POMCP Solver type. Holds all the parameters
"""
type POMCPSolver <: POMDPs.Solver
    eps::Float64 # will stop simulations when discount^depth is less than this
    c::Float64 # UCB exploration constant
    tree_queries::Int
    rng::AbstractRNG
    node_belief_updater::POMDPs.Updater

    value_estimate_method::Symbol # :rollout or :value
    rollout_solver::Union{POMDPs.Solver, POMDPs.Policy}

    num_sparse_actions::Int # = 0 or less if not used
end

"""
Policy that builds a POMCP tree to determine an optimal next action.
"""
type POMCPPlanner <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    rollout_policy::POMDPs.Policy
    rollout_updater::POMDPs.Updater

    #XXX hack
    _tree_ref::Nullable{Any}

    POMCPPlanner() = new()
    POMCPPlanner(p,s,r_pol,r_up) = new(p,s,r_pol,r_up,Nullable{Any}())
end

include("tree.jl")
include("constructor.jl")
include("particle_filter.jl")
include("updater.jl")
include("actions.jl")
include("rollout.jl")
include("solver.jl")
include("visualization.jl")

"""
Return a list of methods required to use POMCP
"""
function required_methods() 
    return [
        POMDPs.iterator,
        POMDPs.actions,
        POMDPs.isterminal,
        POMDPs.discount,
        GenerativeModels.generate_sor
    ]
end
# optional: POMDPs.value

end # module
