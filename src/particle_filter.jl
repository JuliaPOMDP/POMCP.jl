"""
Belief represented by an unweighted collection of particles
"""
type ParticleCollection{S} <: POMDPs.AbstractDistribution{S}
    particles::Vector{S}
    ParticleCollection(particles) = new(particles)
    ParticleCollection() = new(S[])
end

function rand(rng::AbstractRNG, b::ParticleCollection, sample=nothing)
    return b.particles[rand(rng, 1:length(b.particles))]
end

type ParticleCollectionUpdater <: POMDPs.Updater end

# update(Particle
