"""
Constructor for the POMCPSolver.

Use keyword arguments to specify any field values.

For documentation of each field, see the docstring for the POMCPSolver type.
"""
function POMCPSolver(;eps=0.01,
                      max_depth=typemax(Int),
                      c=1.,
                      tree_queries=100,
                      rng=Base.GLOBAL_RNG,
                      node_sr_belief_updater=DefaultReinvigoratorStub(),
                      estimate_value=RolloutEstimator(POMDPToolbox.RandomSolver()),
                      init_V=0.0,
                      init_N=0,
                      num_sparse_actions=0,
                      default_action=ExceptionRethrow())

    return POMCPSolver(eps,
                       max_depth,
                       c,
                       tree_queries,
                       rng,
                       node_sr_belief_updater,
                       estimate_value,
                       init_V,
                       init_N,
                       num_sparse_actions,
                       default_action)
end

"""
Constructor for the POMCPDPWSolver.

Use keyword arguments to specify any field values.

For documentation of each field, see the docstring for POMCPDPWSolver type.
"""
function POMCPDPWSolver(;eps=0.01,
                      max_depth=typemax(Int),
                      c=1.,
                      tree_queries=100,
                      rng=Base.GLOBAL_RNG,
                      node_sr_belief_updater=DefaultReinvigoratorStub(),
                      estimate_value=RolloutEstimator(POMDPToolbox.RandomSolver()),
                      enable_action_pw=true,
                      alpha_observation::Float64=0.5,
                      k_observation::Float64=10.,
                      alpha_action::Float64=0.5,
                      k_action::Float64=10.,
                      init_V=0.0,
                      init_N=0,
                      next_action=RandomActionGenerator(),
                      default_action=ExceptionRethrow())

    return POMCPDPWSolver(eps,
                       max_depth,
                       c,
                       tree_queries,
                       rng,
                       node_sr_belief_updater,
                       estimate_value,
                       enable_action_pw,
                       alpha_observation,
                       k_observation,
                       alpha_action,
                       k_action,
                       init_V,
                       init_N,
                       next_action,
                       default_action)
end
