type POMCPPolicy <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    #XXX hack
    _tree_ref
    POMCPPolicy() = new()
    POMCPPolicy(p,s) = new(p,s,nothing)
end

# XXX Need to implement ==, hash
type ParticleCollection <: POMDPs.Belief
    particles::Array{POMDPs.State,1}
end
ParticleCollection() = ParticleCollection(POMDPs.State[])
function rand!(rng::AbstractRNG, sample, b::ParticleCollection)
    return b.particles[ceil(rand(rng)*length(b.particles))]
end

type ParticleCollectionUpdater
end

abstract BeliefNode

type ActNode
    label::Any # for keeping track of which action this corresponds to
    N::Int64
    V::Float64
    parent::BeliefNode
    children::Dict{POMDPs.Observation,Any} # maps observations to ObsNodes
    ActNode() = new()
    ActNode(l,N::Int64,V::Float64,p::BeliefNode,c::Dict{Any,Any}) = new(l,N,V,p,c)
end

type ObsNode <: BeliefNode
    label::Any
    N::Int64
    B::POMDPs.AbstractDistribution
    parent::ActNode
    children::Dict{POMDPs.Action,ActNode}
end

type RootNode <: BeliefNode
    N::Int64
    B::POMDPs.AbstractDistribution
    children::Dict{POMDPs.Action,ActNode}
end
