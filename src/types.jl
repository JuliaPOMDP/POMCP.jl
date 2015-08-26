type POMCPPolicy <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    rng::AbstractRNG
    #XXX hack
    _tree_ref
end
POMCPPolicy(p,s,r) = POMCPPolicy(p,s,r,nothing)

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
