"""
Policy that builds a POMCP tree to determine an optimal next action.
"""
type POMCPPolicy <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    rollout_policy::POMDPs.Policy
    rollout_updater::POMDPs.Updater

    #XXX hack
    _tree_ref::Nullable{Any}

    POMCPPolicy() = new()
    POMCPPolicy(p,s,r_pol,r_up) = new(p,s,r_pol,r_up,Nullable{Any}())
end

# XXX Need to implement ==, hash ?
"""
Belief represented by an unweighted collection of particles
"""
type ParticleCollection{S} <: POMDPs.AbstractDistribution{S}
    particles::Vector{S}
    ParticleCollection(particles) = new(particles)
    ParticleCollection() = new(S[])
end
function rand(rng::AbstractRNG, b::ParticleCollection, sample=nothing)
    # return b.particles[ceil(rand(rng)*length(b.particles))]
    return b.particles[rand(rng, 1:length(b.particles))]
end

type ParticleCollectionUpdater <: POMDPs.Updater end

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

# XXX might be faster if I know the exact belief type and obs type -> should parameterize
type ObsNode <: BeliefNode
    label::Any
    N::Int64
    B::Any # belief/state distribution
    parent::ActNode
    children::Dict{Any,ActNode}

    ObsNode() = new()
    ObsNode(l,N,B,p,c) = new(l,N,B,p,c)
end

type RootNode <: BeliefNode
    N::Int64
    B::Any # belief/state distribution
    children::Dict{Any,ActNode}
end
