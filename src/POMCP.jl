module POMCP

import POMDPs

import POMDPs: action, solve, create_policy
import Base.rand
import POMDPs: update, updater, create_belief, initialize_belief, AbstractSpace
import POMDPToolbox
import GenerativeModels
import StatsBase: WeightVec, sample

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
    POMCPTreeVisualizer,
    POMCPDPWSolver

abstract ActionGenerator #TODO import from MCTS


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

type POMCPDPWSolver <: POMDPs.Solver
    eps::Float64 # will stop simulations when discount^depth is less than this
    c::Float64
    tree_queries::Int
    rng::AbstractRNG
    updater::POMDPs.Updater

    value_estimate_method::Symbol # :rollout or :value
    rollout_solver::Union{POMDPs.Solver, POMDPs.Policy}

    num_sparse_actions::Int # = 0 or less if not used
    # DPW stuff
    alpha_observation::Float64
    k_observation::Float64
    alpha_action::Float64
    k_action::Float64
end

"""
Policy that builds a POMCP tree to determine an optimal next action.
"""
type POMCPPlanner <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::Union{POMCPSolver,POMCPDPWSolver}
    rollout_policy::POMDPs.Policy
    rollout_updater::POMDPs.Updater

    #XXX hack
    _tree_ref::Nullable{Any}

    gen::ActionGenerator

    POMCPPlanner() = new()
    POMCPPlanner(p,s,r_pol,r_up) = new(p,s,r_pol,r_up,Nullable{Any}(),RandomActionGenerator())
end



#### MISC CONVENIENCE FUNCTIONS ###
# XXX kinda sloppy, not sure what a better place is

function sample(rng::AbstractRNG, wv::WeightVec)
    t = rand(rng) * sum(wv)
    w = values(wv)
    n = length(w)
    i = 1
    cw = w[1]
    while cw < t && i < n
        i += 1
        @inbounds cw += w[i]
    end
    return i
end

sample(rng::AbstractRNG, a::AbstractArray, wv::WeightVec) = a[sample(rng,wv)]

include("tree.jl")
include("constructor.jl")
include("particle_filter.jl")
include("updater.jl")
include("actions.jl")
include("rollout.jl")
include("solver.jl")
include("visualization.jl")

end # module
