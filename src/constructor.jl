

function POMCPSolver(;kwargs...)
    d = Dict(kwargs)
    if !haskey(d, :rollout_policy)
        error("You must specify a rollout_policy when creating a POMCPSolver.")
    end

    return POMCPSolver(
            d[:rollout_policy],
            get(d, :eps, 0.01),
            get(d, :c, 1),
            get(d, :tree_queries, 100),
            get(d, :rng, MersenneTwister()),
            get(d, :updater, ParticleCollectionUpdater()),
            get(d, :rollout_updater, POMDPs.updater(d[:rollout_policy])),
            get(d, :num_sparse_actions, 0)
        )
end
