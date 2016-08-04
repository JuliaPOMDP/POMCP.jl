"""
Constructor for the POMCP Solver

POMCPSolver properties are:

- `eps` - Rollout simulations are terminated once the discount factor raised to the current step power is below this (see paper). default: 0.01
- `max_depth` - Rollout simulations and tree expansion are terminated at this depth. default: typemax(Int)
- `c` - UCB tuning parameter (see paper). default: 1
- `tree_queries` - Number of nodes created in the tree per action decision.
- `rng` - Random number generator.
- `node_belief_updater` - A `POMDPs.Updater` to be used to update the belief in the nodes of the belief tree. By default the particle filter described in the paper will be used.
- `value_estimate_method` - Either `:value` to use the `POMDPs.value()` function or `:rollout` to use a rollout simulation.
- `rollout_solver` - This should be a `POMDPs.Solver` or `POMDPs.Policy` that will be used in rollout simulations. If it is a `Solver`, `solve` will be called to determine the rollout policy. By default a random policy is used.
- `num_sparse_actions` - If only a limited number of actions are to be considered, set this. If it is 0, all actions will be considered.
"""
function POMCPSolver(;eps=0.01,
                      max_depth=typemax(Int),
                      c=1.,
                      tree_queries=100,
                      rng=MersenneTwister(),
                      node_belief_updater=DefaultReinvigoratorStub(),
                      value_estimate_method=:rollout,
                      rollout_solver=POMDPToolbox.RandomSolver(),
                      num_sparse_actions=0)

    return POMCPSolver(eps,
                       max_depth,
                       c,
                       tree_queries,
                       rng,
                       node_belief_updater,
                       value_estimate_method,
                       rollout_solver,
                       num_sparse_actions)
end

"""
Constructor for the POMCP DPW Solver

POMCPSolver properties are:

- `eps` - Rollout simulations are terminated once the discount factor raised to the current step power is below this (see paper). default: 0.01
- `max_depth` - Rollout simulations and tree expansion are terminated at this depth. default: typemax(Int)
- `c` - UCB tuning parameter (see paper). default: 1
- `tree_queries` - Number of nodes created in the tree per action decision.
- `rng` - Random number generator.
- `node_belief_updater` - A `POMDPs.Updater` to be used to update the belief in the nodes of the belief tree. By default the particle filter described in the paper will be used.
- `value_estimate_method` - Either `:value` to use the `POMDPs.value()` function or `:rollout` to use a rollout simulation.
- `rollout_solver` - This should be a `POMDPs.Solver` or `POMDPs.Policy` that will be used in rollout simulations. If it is a `Solver`, `solve` will be called to determine the rollout policy. By default a random policy is used.
- `num_sparse_actions` - If only a limited number of actions are to be considered, set this. If it is 0, all actions will be considered.
"""
function POMCPDPWSolver(;eps=0.01,
                      max_depth=typemax(Int),
                      c=1.,
                      tree_queries=100,
                      rng=MersenneTwister(),
                      node_belief_updater=DefaultReinvigoratorStub(),
                      value_estimate_method=:rollout,
                      rollout_solver=POMDPToolbox.RandomSolver(),
                      alpha_observation::Float64=0.5,
                      k_observation::Float64=10.,
                      alpha_action::Float64=0.5,
                      k_action::Float64=10.,
                      gen::ActionGenerator=RandomActionGenerator())

    return POMCPDPWSolver(eps,
                       max_depth,
                       c,
                       tree_queries,
                       rng,
                       node_belief_updater,
                       value_estimate_method,
                       rollout_solver,
                       alpha_observation,
                       k_observation,
                       alpha_action,
                       k_action,
                       gen)
end
