
# Since a RandomPolicy needs a POMDP to be constructed, we need to wait until
# solve() is called to actually create the random policy, so a placeholder
# is used by default until then
type RandomPolicyPlaceholder <: POMDPs.Policy end
POMDPs.updater(::RandomPolicyPlaceholder) = EmptyUpdater()

## Constructor for the POMCP Solver ##
function POMCPSolver(;kwargs...)
    d = Dict(kwargs)

    return POMCPSolver(
            get(d, :eps, 0.01),
            get(d, :c, 1),
            get(d, :tree_queries, 100),
            get(d, :rng, MersenneTwister()),
            get(d, :updater, ParticleCollectionUpdater()),

            get(d, :value_estimate_method, :rollout),
            get(d, :rollout_policy, RandomPolicyPlaceholder()),
            get(d, :rollout_updater, POMDPs.updater(d[:rollout_policy])),

            get(d, :num_sparse_actions, 0)
        )
end
