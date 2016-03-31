## Methods for Specialization

The following methods can be overridden to change the behavior of the solver:

    {docs}
    convert_belief(rollout_updater, node)
    init_V(problem, parent, action)
    init_N(problem, parent, action)
    sparse_actions(pomdp, state, belief, num_actions)
    estimate_value(pomcp, problem, start_state, h)
