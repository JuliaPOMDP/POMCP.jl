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
    init_N,
    sparse_actions

#TODO are these the things I should export?

type POMCPSolver <: POMDPs.Solver
    eps::Float64 # will stop simulations when discount^depth is less than this
    c::Float64
    tree_queries::Int
    rng::AbstractRNG
    updater::POMDPs.BeliefUpdater

    value_estimate_method::Symbol # :rollout or :value
    rollout_policy::POMDPs.Policy
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
convert_belief(up::POMCPUpdater, b::POMDPs.Belief) = POMCPPolicyState(b)
convert_belief(::POMCPUpdater, b::POMCPPolicyState) = b

function update(updater::POMCPUpdater, b_old::POMCPPolicyState, a::POMDPs.Action, o::POMDPs.Observation, b::POMCPPolicyState=POMCPPolicyState())
    if !haskey(b_old.tree.children[a].children, o)
        # if there is no node for the observation, attempt to create one
        # TODO this will fail for the particle filter... then what?
        new_belief = update(updater.updater, b_old.tree.B, a, o)
        new_node = ObsNode(o, 0, new_belief, b_old.tree.children[a], Dict{Any,ActNode}())
        b_old.tree.children[a].children[o] = new_node
    end
    b.tree = b_old.tree.children[a].children[o]
    return b
end
function rand!(rng::AbstractRNG, s::POMDPs.State, d::POMCPPolicyState)
    rand!(rng, s, d.tree.B)
end

## Methods for specialization

# override this to determine how the belief for the rollout policy will look
convert_belief(rollout_updater::POMDPs.BeliefUpdater, node::BeliefNode) = convert_belief(rollout_updater, node.B)
# some defaults are provided
convert_belief(::POMDPToolbox.PreviousObservationUpdater, node::ObsNode) = POMDPToolbox.PreviousObservation(node.label)
convert_belief(::POMDPToolbox.EmptyUpdater, node::BeliefNode) = POMDPToolbox.EmptyBelief()

# override this if you want to choose specific actions (you can override based on the POMDP type at the node level, or the belief type)
function sparse_actions(pomcp::POMCPPolicy, pomdp::POMDPs.POMDP, h::BeliefNode, num_actions::Int)
    return sparse_actions(pomcp, pomdp, h.B, num_actions)
end
function sparse_actions(pomcp::POMCPPolicy, pomdp::POMDPs.POMDP, b::POMDPs.Belief, num_actions::Int)
    if num_actions > 0
        all_act = collect(POMDPs.iterator(POMDPs.actions(pomdp, b)))
        selected_act = Array(Any, min(num_actions, length(all_act)))
        len = length(selected_act)
        for i in 1:len
            j = rand(pomcp.solver.rng, 1:length(all_act))
            selected_act[i] = all_act[j]
            deleteat!(all_act, j)
        end
        return selected_act
    else
        return POMDPs.iterator(POMDPs.actions(pomdp, b))
    end
end

# TODO: Document
# TODO: Not sure if the arguments for this are right
function init_V(problem::POMDPs.POMDP, h::BeliefNode, action)
    return 0.0
end

# TODO: Document
# TODO: Not sure if the arguments for this are exactly what's needed
function init_N(problem::POMDPs.POMDP, h::BeliefNode, action)
    return 0
end

# the problem argument is there so that users may specialize this for their problem
function estimate_value(pomcp::POMCPPolicy, problem::POMDPs.POMDP, start_state::POMDPs.State, h::BeliefNode)
    if pomcp.solver.value_estimate_method == :value
        return POMDPs.value(pomcp.solver.rollout_policy, h.B)
    elseif pomcp.solver.value_estimate_method == :rollout
        return rollout(pomcp, start_state, h)
    else
        error("POMCPSolver.value_estimate_method should be :value or :rollout (it was $(pomcp.solver.value_estimate_method)).")
    end
end

include("solver.jl")
include("visualization.jl")

end # module
