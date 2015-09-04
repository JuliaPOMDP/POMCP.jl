type POMCPPolicy <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    #XXX hack
    _tree_ref
end
POMCPPolicy(p,s) = POMCPPolicy(p,s,nothing)

# XXX Need to implement ==, hash
type ParticleCollection <: POMDPs.Belief
    particles::Array{Any,1}
end
ParticleCollection() = ParticleCollection({})
function rand!(rng::AbstractRNG, sample, b::ParticleCollection)
    return b.particles[ceil(rand(rng)*length(b.particles))]
end

abstract BeliefNode

type ActNode
    label::Any # for keeping track of which action this corresponds to
    N::Int64
    V::Float64
    parent::BeliefNode
    children::Dict{Any,Any} # maps observations to ObsNodes
end

type ObsNode <: BeliefNode
    label::Any
    N::Int64
    B::POMDPs.AbstractDistribution
    parent::ActNode
    children::Dict{Any,ActNode}
end

type RootNode <: BeliefNode
    N::Int64
    B::POMDPs.AbstractDistribution
    children::Dict{Any,ActNode}
end

type FullBeliefConverter <: NodeBeliefConverter
end
function belief_from_node(converter::FullBeliefConverter, node::BeliefNode)
    return node.B
end

type EmptyConverter <: NodeBeliefConverter
end
function belief_from_node(converter::EmptyConverter, node::BeliefNode)
    return POMDPToolbox.EmptyBelief()
end

# returns the previous observation except at the root node, where it returns a copy of the belief
type PreviousObservationConverter <: NodeBeliefConverter
end
function belief_from_node(converter::PreviousObservationConverter, node::POMCP.ObsNode)
    return POMDPToolbox.PreviousObservation(node.label)
end
function belief_from_node(converter::PreviousObservationConverter, node::POMCP.RootNode)
    return deepcopy(node.B)
end
