"""
Chooses a child node based on the observation.
"""
type NodeUpdater{U<:POMDPs.Updater} <: POMDPs.Updater{BeliefNode}
    node_belief_updater::U # updates the belief between nodes if necessary
end
NodeUpdater{U<:POMDPs.Updater}(node_belief_updater::U) = NodeUpdater{U}(node_belief_updater)

# version with a particle reinvigorator
function update{R<:ParticleReinvigorator,A,O}(updater::NodeUpdater{R}, b_old::BeliefNode, a::A, o::O, b=nothing)
    if !haskey(b_old.children[a].children, o)
        new_collection = handle_unseen_observation(updater.node_belief_updater,
                                                   b_old, a, o)
        new_node = ObsNode(o, 0, new_collection, b_old.children[a], Dict{A,ActNode}())
        b_old.children[a].children[o] = new_node
    end
    b_new = b_old.children[a].children[o]

    reinvigorate!(b_new.B,
                  updater.node_belief_updater,
                  b_old, a, o)
    return b_new
end

# version with a user-supplied belief updater
function update{A,O}(updater::NodeUpdater, b_old::BeliefNode, a::A, o::O, b=nothing)
    if !haskey(b_old.children[a].children, o)
        # if there is no node for the observation, attempt to create one
        new_belief = update(update.node_belief_updater, b_old.B, a, o)
        new_node = ObsNode(o, 0, new_belief, b_old.children[a], Dict{A,ActNode}())
        b_old.children[a].children[o] = new_node
    end

    return b_old.children[a].children[o]
end

updater(policy::POMCPPlanner) = NodeUpdater(policy.solver.node_belief_updater)
# TODO fix VVV
create_belief(updater::NodeUpdater) = nothing#ObsNode()

initialize_belief(up::NodeUpdater, b::POMDPs.AbstractDistribution, new_belief::BeliefNode=RootNode(0, b, Dict{Any,ActNode}())) = new_belief
initialize_belief(up::NodeUpdater, b::POMDPs.AbstractDistribution) = RootNode(0, b, Dict{Any,ActNode}())
initialize_belief(::NodeUpdater, n::RootNode, ::ObsNode) = n

function rand(rng::AbstractRNG, d::BeliefNode, s)
    rand(rng, d.B, s)
end

function rand(rng::AbstractRNG, d::BeliefNode)
    rand(rng, d.B)
end
