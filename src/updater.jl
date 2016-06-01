"""
Chooses a child node based on the observation.
"""
type NextNodeSelector <: POMDPs.Updater{BeliefNode}
    node_belief_updater::POMDPs.Updater # updates the belief between nodes if necessary
end

function update(updater::NextNodeSelector, b_old::BeliefNode, a, o, b=nothing)
    if !haskey(b_old.children[a].children, o)
        # if there is no node for the observation, attempt to create one
        new_belief = update(updater.node_belief_updater, b_old.B, a, o)
        new_node = ObsNode(o, 0, new_belief, b_old.children[a], Dict{Any,ActNode}())
        b_old.children[a].children[o] = new_node
    end
    return b_old.children[a].children[o]
end

updater(policy::POMCPPolicy) = NextNodeSelector(policy.solver.node_belief_updater)
create_belief(updater::NextNodeSelector) = ObsNode()

initialize_belief(up::NextNodeSelector, b::POMDPs.AbstractDistribution, new_belief::BeliefNode=RootNode(0, b, Dict{Any,ActNode}())) = new_belief
initialize_belief(up::NextNodeSelector, b::POMDPs.AbstractDistribution) = RootNode(0, b, Dict{Any,ActNode}())
initialize_belief(::NextNodeSelector, n::RootNode, ::ObsNode) = n

function rand(rng::AbstractRNG, d::BeliefNode, s)
    rand(rng, d.B, s)
end

function rand(rng::AbstractRNG, d::BeliefNode)
    rand(rng, d.B)
end
