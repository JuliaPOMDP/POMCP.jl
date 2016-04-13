"""
Policy that builds a POMCP tree to determine an optimal next action.
"""
type POMCPPolicy <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    rollout_policy::POMDPs.Policy
    rollout_updater::POMDPs.BeliefUpdater

    #XXX hack
    _tree_ref::Nullable{Any}

    POMCPPolicy() = new()
    POMCPPolicy(p,s,r_pol,r_up) = new(p,s,r_pol,r_up,Nullable{Any}())
end

# XXX Need to implement ==, hash ?
"""
Belief represented by an unweighted collection of particles
"""
type ParticleCollection{S} <: POMDPs.Belief{S}
    particles::Vector{S}
    ParticleCollection(particles) = new(particles)
    ParticleCollection() = new(S[])
end
function rand(rng::AbstractRNG, b::ParticleCollection, sample=nothing)
    # return b.particles[ceil(rand(rng)*length(b.particles))]
    return b.particles[rand(rng, 1:length(b.particles))]
end

type ParticleCollectionUpdater <: POMDPs.BeliefUpdater end

abstract BeliefNode

type ActNode
    label::Any # for keeping track of which action this corresponds to
    N::Int64
    V::Float64
    parent::BeliefNode
    children::Dict{Any,Any} # maps observations to ObsNodes
    ActNode() = new()
    ActNode(l,N::Int64,V::Float64,p::BeliefNode,c::Dict{Any,Any}) = new(l,N,V,p,c)
end

type ObsNode <: BeliefNode
    label::Any
    N::Int64
    B::POMDPs.Belief
    parent::ActNode
    children::Dict{Any,ActNode}
end

type RootNode <: BeliefNode
    N::Int64
    B::POMDPs.Belief
    children::Dict{Any,ActNode}
end
