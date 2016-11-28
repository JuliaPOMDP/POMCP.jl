__precompile__()
module POMCP

import POMDPs

import POMDPs: action, solve, create_policy
import Base.rand
import POMDPs: update, updater, create_belief, initialize_belief, AbstractSpace
import POMDPToolbox
import GenerativeModels
import StatsBase: WeightVec, sample
import MCTS: ActionGenerator, RandomActionGenerator, next_action

using Compat

export
    POMCPSolver,
    POMCPDPWSolver,
    POMCPPlanner,
    RootUpdater,
    BeliefNode,
    RootNode,
    ObservationNode,
    POMCPTreeVisualizer,

    solve,
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

    ActionGenerator,
    RandomActionGenerator,
    next_action,

    ParticleCollection,
    ParticleReinvigorator,
    reinvigorate!,
    handle_unseen_observation,
    DefaultReinvigoratorStub


include("tree.jl")
include("particle_filter.jl")

"""
The POMCP Solver type. Holds all the parameters
"""
type POMCPSolver <: POMDPs.Solver
    eps::Float64 # will stop simulations when discount^depth is less than this
    max_depth::Int
    c::Float64 # UCB exploration constant
    tree_queries::Int
    rng::AbstractRNG
    node_belief_updater::Union{POMDPs.Updater, DefaultReinvigoratorStub}

    value_estimate_method::Symbol # :rollout or :value
    rollout_solver::Union{POMDPs.Solver, POMDPs.Policy}

    num_sparse_actions::Int # = 0 or less if not used
end 
"""
The POMCP Double Progressive Widening solver type. Holds all the parameters
"""
type POMCPDPWSolver <: POMDPs.Solver
    eps::Float64 # will stop simulations when discount^depth is less than this
    max_depth::Int
    c::Float64
    tree_queries::Int
    rng::AbstractRNG
    node_belief_updater::Union{POMDPs.Updater, DefaultReinvigoratorStub}

    value_estimate_method::Symbol # :rollout or :value
    rollout_solver::Union{POMDPs.Solver, POMDPs.Policy}

    enable_action_pw::Bool

    alpha_observation::Float64
    k_observation::Float64
    alpha_action::Float64
    k_action::Float64
    gen::ActionGenerator
end

"""
Policy that builds a POMCP tree to determine an optimal next action.

Note, you should construct this using the create_policy function
"""
type POMCPPlanner{S, A, O, B, SolverType} <: POMDPs.Policy
    problem::POMDPs.POMDP{S,A,O}
    solver::SolverType
    node_belief_updater::POMDPs.Updater{B}
    rollout_policy::POMDPs.Policy
    rollout_updater::POMDPs.Updater

    #XXX hack
    _tree_ref::Nullable{Any}
end

include("constructor.jl")
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
