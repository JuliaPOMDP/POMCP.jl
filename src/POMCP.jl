__precompile__()
module POMCP

if VERSION >= v"0.6.0"
    warn("The POMCP package is deprecated. Please use BasicPOMCP (https://github.com/JuliaPOMDP/BasicPOMCP.jl) instead.")
end

import POMDPs

import POMDPs: action, solve
import Base: rand, mean
import POMDPs: update, updater, initialize_belief
import POMDPToolbox
import StatsBase: WeightVec, sample
import MCTS: RandomActionGenerator, RolloutEstimator, next_action, estimate_value, init_N, convert_to_policy
using ParticleFilters

using Compat

export
    AbstractPOMCPSolver,
    POMCPSolver,
    POMCPDPWSolver,
    POMCPPlanner,
    RootUpdater,
    BeliefNode,
    RootNode,
    ObsNode,
    AbstractActNode,
    ActNode,
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
    convert_estimator,
    add_N,

    RandomActionGenerator,
    next_action,

    RolloutEstimator,
    PORollout,
    FORollout,
    FOValue,

    ParticleCollection,
    ParticleReinvigorator,
    reinvigorate!,
    handle_unseen_observation,
    DefaultReinvigoratorStub,

    NoDecision,
    AllSamplesTerminal,
    ExceptionRethrow,
    default_action,

    # deprecated
    PORolloutEstimator

include("tree.jl")
include("particle_filter.jl")
include("exceptions.jl")

abstract type AbstractPOMCPSolver <: POMDPs.Solver end

"""
POMCP Solver type

Fields:

    eps::Float64
        Rollouts and tree expansion will stop when discount^depth is less than this.
        default: 0.01

    max_depth::Int
        Rollouts and tree expension will stop when this depth is reached.
        default: 10

    c::Float64
        UCB exploration constant - specifies how much the solver should explore.
        default: 1.0

    tree_queries::Int
        Number of iterations during each action() call.
        default: 100

    rng::AbstractRNG
        Random number generator.
        default: Base.GLOBAL_RNG

    node_belief_updater::Updater
        Calculates the belief for a new belief node (see notebooks/Belief_and_Particle_Filter_Options.ipynb for more info.)
        default: DefaultReinvigoratorStub() - this will simply keep the particles as described in the paper without doing any reinvigoration.

    estimate_value::Any (rollout policy can be specified by setting this to RolloutEstimator(policy))
        Function, object, or number used to estimate the value at the leaf nodes.
        If this is a function `f`, `f(pomdp, s, h::BeliefNode, steps)` will be called to estimate the value.
        If this is an object `o`, `estimate_value(o, pomdp, s, h::BeliefNode, steps)` will be called.
        If this is a number, the value will be set to that number
        default: RolloutEstimator(RandomSolver(rng))

    init_V::Any
        Function, object, or number used to set the initial V(h,a) value at a new node.
        If this is a function `f`, `f(pomdp, h, a)` will be called to set the value.
        If this is an object `o`, `init_V(o, pomdp, h, a)` will be called.
        If this is a number, V will be set to that number
        default: 0.0

    init_N::Any
        Function, object, or number used to set the initial N(s,a) value at a new node.
        If this is a function `f`, `f(pomdp, h, a)` will be called to set the value.
        If this is an object `o`, `init_N(o, pomdp, h, a)` will be called.
        If this is a number, N will be set to that number
        default: 0

    num_sparse_actions::Int
        Number of actions to be considered at each node.
        If <= 0, the entire action space will be considered.
        default: 0

    default_action::Any
        Function, action, or Policy used to determine the action if POMCP fails with exception `ex`.
        If this is a Function `f`, `f(belief, ex)` will be called.
        If this is a Policy `p`, `action(p, belief)` will be called.
        If it is an object `a`, `default_action(a, belief, ex) will be called, and
        if this method is not implemented, `a` will be returned directly.
"""
type POMCPSolver <: AbstractPOMCPSolver
    eps::Float64 # will stop simulations when discount^depth is less than this
    max_depth::Int
    c::Float64 # UCB exploration constant
    tree_queries::Int
    rng::AbstractRNG
    node_belief_updater::Union{POMDPs.Updater, DefaultReinvigoratorStub}

    estimate_value::Any

    init_V::Any
    init_N::Any

    num_sparse_actions::Int # = 0 or less if not used
    default_action::Any
end 

"""
POMCP Solver type

Fields:

    eps::Float64
        Rollouts and tree expansion will stop when discount^depth is less than this.
        default: 0.01

    max_depth::Int
        Rollouts and tree expension will stop when this depth is reached.
        default: 10

    c::Float64
        UCB exploration constant - specifies how much the solver should explore.
        default: 1.0

    tree_queries::Int
        Number of iterations during each action() call.
        default: 100

    rng::AbstractRNG
        Random number generator.
        default: Base.GLOBAL_RNG

    node_belief_updater::Updater
        Calculates the belief for a new belief node (see notebooks/Belief_and_Particle_Filter_Options.ipynb for more info.)
        default: DefaultReinvigoratorStub() - this will simply keep the particles as described in the paper without doing any reinvigoration.

    estimate_value::Any (rollout policy can be specified by setting this to RolloutEstimator(policy))
        Function, object, or number used to estimate the value at the leaf nodes.
        If this is a function `f`, `f(pomdp, s, h::BeliefNode, steps)` will be called to estimate the value.
        If this is an object `o`, `estimate_value(o, pomdp, s, h::BeliefNode, steps)` will be called.
        If this is a number, the value will be set to that number
        default: RolloutEstimator(RandomSolver(rng))

    enable_action_pw::Bool
        Turn progressive widening of the number of actions considered on or off.
        If false, all actions will be considered.
        default: true

    k_action::Float64
    alpha_action::Float64
    k_observation::Float64
    alpha_observation::Float64
        These constants control the double progressive widening. A new observation
        or action will be added if the number of children is less than or equal to kN^alpha.
        defaults: k:10, alpha:0.5

    init_V::Any
        Function, object, or number used to set the initial V(h,a) value at a new node.
        If this is a function `f`, `f(pomdp, h, a)` will be called to set the value.
        If this is an object `o`, `init_V(o, pomdp, h, a)` will be called.
        If this is a number, V will be set to that number
        default: 0.0

    init_N::Any
        Function, object, or number used to set the initial N(s,a) value at a new node.
        If this is a function `f`, `f(pomdp, h, a)` will be called to set the value.
        If this is an object `o`, `init_N(o, pomdp, h, a)` will be called.
        If this is a number, N will be set to that number
        default: 0

    next_action::Any
        Function or object used to choose the next action to be considered for progressive widening.
        The next action is determined based on the POMDP, the belief, `b`, and the current `BeliefNode`, `h`.
        If this is a function `f`, `f(pomdp, b, h)` will be called to set the value.
        If this is an object `o`, `next_action(o, pomdp, b, h)` will be called.
        default: RandomActionGenerator(rng)

    default_action::Any
        Function, action, or Policy used to determine the action if POMCP fails with exception `ex`.
        If this is a Function `f`, `f(belief, ex)` will be called.
        If this is a Policy `p`, `action(p, belief)` will be called.
        If it is an object `a`, `default_action(a, belief, ex) will be called, and
        if this method is not implemented, `a` will be returned directly.

For more information on the k and alpha parameters, see Couëtoux, A., Hoock, J.-B., Sokolovska, N., Teytaud, O., & Bonnard, N. (2011). Continuous Upper Confidence Trees. In Learning and Intelligent Optimization. Rome, Italy. Retrieved from http://link.springer.com/chapter/10.1007/978-3-642-25566-3_32
"""
type POMCPDPWSolver <: AbstractPOMCPSolver
    eps::Float64 # will stop simulations when discount^depth is less than this
    max_depth::Int
    c::Float64
    tree_queries::Int
    rng::AbstractRNG
    node_belief_updater::Union{POMDPs.Updater, DefaultReinvigoratorStub}

    estimate_value::Any

    enable_action_pw::Bool

    alpha_observation::Float64
    k_observation::Float64
    alpha_action::Float64
    k_action::Float64
    init_V::Any
    init_N::Any
    next_action::Any
    default_action::Any
end

"""
Policy that builds a POMCP tree to determine an optimal next action.

Note, you should construct this using the create_policy function
"""
type POMCPPlanner{S, A, O, B, SolverType<:AbstractPOMCPSolver} <: POMDPs.Policy
    problem::POMDPs.POMDP{S,A,O}
    solver::SolverType
    node_belief_updater::POMDPs.Updater{B}
    solved_estimate::Any

    #XXX hack
    _tree_ref::Nullable{Any}
end

include("constructor.jl")
include("updater.jl")
include("actions.jl")
include("rollout.jl")
include("solver.jl")
include("visualization.jl")

end # module
