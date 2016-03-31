# Since a RandomPolicy needs a POMDP to be constructed, we need to wait until
# solve() is called to actually create the random policy, so a placeholder
# is used by default until then
type RandomPolicyPlaceholder <: POMDPs.Policy end
POMDPs.updater(::RandomPolicyPlaceholder) = POMDPToolbox.EmptyUpdater()

"""
Constructor for the POMCP Solver

POMCPSolver properties are:

- `eps` - Rollout simulations are terminated once the discount factor raised to the current step power is below this (see paper). default: 0.01
- `c` - UCB tuning parameter (see paper). default: 1
- `tree_queries` - Number of nodes created in the tree per action decision.
- `rng` - Random number generator.
- `updater` - A `POMDPs.BeliefUpdater` to be used to update the belief within the policy state. By default the particle filter described in the paper will be used.
- `value_estimate_method` - Either `:value` to use the `POMDPs.value()` function or `rollout` to use a rollout simulation.
- `rollout_policy` - This should be a `POMDPs.Policy` that will be used in rollout simulations. By default a random policy is used.
- `rollout_updater` - The belief updater that will be used in the rollout simulations. default: `updater(rollout_policy)`.
- `num_sparse_actions` - If only a limited number of actions are to be considered, set this. If it is 0, all actions will be considered.
"""
function POMCPSolver(;kwargs...)
    d = Dict(kwargs)
    if !haskey(d, :rollout_policy)
        d[:rollout_policy] = RandomPolicyPlaceholder()
    end

    return POMCPSolver(
            get(d, :eps, 0.01),
            get(d, :c, 1),
            get(d, :tree_queries, 100),
            get(d, :rng, MersenneTwister()),
            get(d, :updater, ParticleCollectionUpdater()),

            get(d, :value_estimate_method, :rollout),
                d[ :rollout_policy],
            get(d, :rollout_updater, POMDPs.updater(d[:rollout_policy])),

            get(d, :num_sparse_actions, 0)
        )
end
