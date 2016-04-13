"""
Constructor for the POMCP Solver

POMCPSolver properties are:

- `eps` - Rollout simulations are terminated once the discount factor raised to the current step power is below this (see paper). default: 0.01
- `c` - UCB tuning parameter (see paper). default: 1
- `tree_queries` - Number of nodes created in the tree per action decision.
- `rng` - Random number generator.
- `updater` - A `POMDPs.BeliefUpdater` to be used to update the belief within the policy state. By default the particle filter described in the paper will be used.
- `value_estimate_method` - Either `:value` to use the `POMDPs.value()` function or `rollout` to use a rollout simulation.
- `rollout_solver` - This should be a `POMDPs.Solver` or `POMDPs.Policy` that will be used in rollout simulations. If it is a `Solver`, `solve` will be called to determine the rollout policy. By default a random policy is used.
- `rollout_updater` - The belief updater that will be used in the rollout simulations. default: `updater(rollout_policy)`.
- `num_sparse_actions` - If only a limited number of actions are to be considered, set this. If it is 0, all actions will be considered.
"""
function POMCPSolver(;eps=0.01,
                      c=1,
                      tree_queries=100,
                      rng=MersenneTwister(),
                      updater=ParticleCollectionUpdater(),
                      value_estimate_method=:rollout,
                      rollout_solver=POMDPToolbox.RandomSolver(),
                      num_sparse_actions=0)

    return POMCPSolver(eps,
                       c,
                       tree_queries,
                       rng,
                       updater,
                       value_estimate_method,
                       rollout_solver,
                       num_sparse_actions)
end
