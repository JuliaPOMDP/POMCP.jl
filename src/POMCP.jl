module POMCP

import POMDPs

import POMDPs: action, solve, create_policy
import Base.rand!
import POMDPs: update, convert_belief, updater, create_belief
import POMDPToolbox


export
    POMCPSolver,
    POMCPPolicyState,
    solve,
    action,
    to_json_file,
    init_V,
    init_N

#TODO are these the things I should export?

type POMCPSolver <: POMDPs.Solver
    rollout_policy::POMDPs.Policy
    eps::Float64 # will stop simulations when discount^depth is less than this
    c::Float64
    tree_queries::Int
    rng::AbstractRNG
    updater::POMDPs.BeliefUpdater
    rollout_updater::POMDPs.BeliefUpdater
    num_sparse_actions::Int # = 0 or less if not used
end

include("types.jl")
include("constructor.jl")

type POMCPPolicyState <: POMDPs.Belief
    tree::BeliefNode
end
POMCPPolicyState() = POMCPPolicyState(RootNode(0, POMDPToolbox.EmptyBelief(), Dict{Any,ActNode}()))
function POMCPPolicyState(b::POMDPs.Belief)
    return POMCPPolicyState(RootNode(0, deepcopy(b), Dict{Any,ActNode}()))
end
type POMCPUpdater <: POMDPs.BeliefUpdater
    updater
end
updater(policy::POMCPPolicy) = POMCPUpdater(policy.solver.updater)
create_belief(updater::POMCPUpdater) = POMCPPolicyState()
convert_belief(::POMCPUpdater, b::POMDPs.Belief) = POMCPPolicyState(b)
convert_belief(::POMCPUpdater, b::POMCPPolicyState) = b

function update(updater::POMCPUpdater, b_old::POMCPPolicyState, a::POMDPs.Action, o::POMDPs.Observation, b::POMCPPolicyState=POMCPPolicyState())
    if haskey(b_old.tree.children[a].children, o)
        b.tree = b_old.tree.children[a].children[o]
    else
        # TODO this will fail for the particle filter... then what?
        new_belief = update(updater.updater, b_old.tree.B, a, o)
        b.tree = ObsNode(o, 0, new_belief, b_old.tree.children[a], Dict{Any,ActNode}())
    end
    return b
end
function rand!(rng::AbstractRNG, s::POMDPs.State, d::POMCPPolicyState)
    rand!(rng, s, d.tree.B)
end

# override this to determine how the belief for the rollout policy will look
convert_belief(rollout_updater::POMDPs.BeliefUpdater, node::BeliefNode) = convert_belief(rollout_updater, node.B)
# some defaults are provided
convert_belief(::POMDPToolbox.PreviousObservationUpdater, node::ObsNode) = POMDPToolbox.PreviousObservation(node.label)
convert_belief(::POMDPToolbox.EmptyUpdater, node::BeliefNode) = POMDPToolbox.EmptyBelief()

# override this if you want to choose specific actions (you can override based on the POMDP type at the node level, or the belief type)
function sparse_actions(pomdp::POMDPs.POMDP, s::POMDPs.State, h::BeliefNode, num_actions::Int)
    return sparse_actions(pomdp, s, h.B, num_actions)
end
function sparse_actions(pomdp::POMDPs.POMDP, s::POMDPs.State, b::POMDPs.Belief, num_actions::Int)
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
