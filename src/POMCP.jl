module POMCP

import POMDPs

import POMDPs: action, solve, create_policy
import Base.rand!
import POMDPs.belief
import POMDPToolbox


export
    POMCPSolver,
    POMCPBeliefWrapper,
    solve,
    action,
    to_json_file,
    NodeBeliefConverter,
    FullBeliefConverter,
    EmptyConverter,
    PreviousObservationConverter

#TODO are these the things I should export?

abstract NodeBeliefConverter

type POMCPSolver <: POMDPs.Solver
    rollout_policy::POMDPs.Policy
    eps::Float64 # will stop simulations when discount^depth is less than this
    c::Float64
    tree_queries::Int
    rng::AbstractRNG
    use_particle_filter::Bool # this should probably actually be a belief wrapper property
    node_converter::NodeBeliefConverter
    num_sparse_actions::Int # = 0 or less if not used
end
# TODO: make a constructor that will asign sensible defaults

include("types.jl")

type POMCPBeliefWrapper <: POMDPs.Belief
    tree::BeliefNode
end
POMCPBeliefWrapper() = POMCPBeliefWrapper(RootNode(0, POMDPToolbox.EmptyBelief(), Dict{Any,ActNode}()))
function POMCPBeliefWrapper(b::POMDPs.Belief)
    return POMCPBeliefWrapper(RootNode(0, deepcopy(b), Dict{Any,ActNode}()))
end
function belief(pomdp::POMDPs.POMDP, b_old::POMCPBeliefWrapper, a, o, b::POMCPBeliefWrapper=POMCPBeliefWrapper())
    if haskey(b_old.tree.children[a].children, o)
        b.tree = b_old.tree.children[a].children[o]
    else
        # TODO this will fail for the particle filter... then what?
        new_belief = belief(pomdp, b_old.tree.B, a, o)
        b.tree = ObsNode(o, 0, new_belief, b_old.tree.children[a], Dict{Any,ActNode}())
    end
    return b
end
function rand!(rng::AbstractRNG, s, d::POMCPBeliefWrapper)
    rand!(rng, s, d.tree.B)
end

# override this if you want to choose specific actions (you can override based on the POMDP type at the node level, or the belief type)
function sparse_actions(pomdp::POMDPs.POMDP, s, h::BeliefNode, num_actions::Int)
    return sparse_actions(pomdp, s, h.B, num_actions)
end
function sparse_actions(pomdp::POMDPs.POMDP, s, b::POMDPs.Belief, num_actions::Int)
    as = POMDPs.actions(pomdp, s)
    if num_actions > 0
        return as[1:min(length(as),num_actions)]
    else
        return as
    end
end

include("solver.jl")
include("visualization.jl")

end # module
