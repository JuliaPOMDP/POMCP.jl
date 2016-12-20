"""
The default Updater for a POMCPPlanner.

When a new observation is recieved from the main simulation, a RootUpdater simply updates the
root node for the action decision on the next time step to the child of the current root node
corresponding to the observation. That way, all the information from the tree is preserved.
"""
type RootUpdater{U<:POMDPs.Updater} <: POMDPs.Updater{BeliefNode}
    node_belief_updater::U # updates the belief between nodes if necessary
end

# version with a particle reinvigorator
function update{R<:ParticleReinvigorator,A,O}(updater::RootUpdater{R}, b_old::BeliefNode, a::A, o::O, b=nothing)
    if !haskey(b_old.children[a].children, o)
        new_collection = handle_unseen_observation(updater.node_belief_updater,
                                                   b_old, a, o)
        new_node = ObsNode(o, 0, new_collection, Dict{A,ActNode{A,O,ObsNode{typeof(new_collection),A,O}}}())
        b_old.children[a].children[o] = new_node
    end
    b_new = b_old.children[a].children[o]

    reinvigorate!(b_new.B,
                  updater.node_belief_updater,
                  b_old, a, o)

    return b_new
end

# version with a user-supplied belief updater
function update{A,O}(updater::RootUpdater, b_old::BeliefNode, a::A, o::O, b=nothing)
    if !haskey(b_old.children[a].children, o)
        # if there is no node for the observation, attempt to create one
        new_belief = update(updater.node_belief_updater, b_old.B, a, o)
        new_node = ObsNode(o, 0, new_belief, Dict{A,ActNode{A,O,ObsNode{typeof(new_belief),A,O}}}())
        b_old.children[a].children[o] = new_node
    end

    return b_old.children[a].children[o]
end

updater(policy::POMCPPlanner) = RootUpdater(policy.node_belief_updater)
create_belief(updater::RootUpdater) = RootNode(0, create_belief(updater.node_belief_updater), Dict{Any,ActNode}())
create_belief{R<:ParticleReinvigorator}(updater::RootUpdater{R}) = RootNode(0, nothing, Dict{Any,ActNode}())

initialize_belief(up::RootUpdater, b, new_belief::BeliefNode) = new_belief
initialize_belief(up::RootUpdater, b) = RootNode(0, b, Dict{Any,ActNode}())
initialize_belief(::RootUpdater, n::RootNode) = n

function rand(rng::AbstractRNG, d::BeliefNode, s)
    rand(rng, d.B, s)
end

function rand(rng::AbstractRNG, d::BeliefNode)
    rand(rng, d.B)
end
