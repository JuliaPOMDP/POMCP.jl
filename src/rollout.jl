"""
    estimate_value(pomcp::POMCPPlanner, problem::POMDPs.POMDP, start_state, h::BeliefNode)

Return an initial unbiased estimate of the value at belief node h.

By default this runs a rollout simulation
"""
function estimate_value(pomcp::POMCPPlanner, problem::POMDPs.POMDP, start_state, h::BeliefNode)
    if pomcp.solver.value_estimate_method == :value
        return POMDPs.value(pomcp.solver.rollout_policy, h.B) # this does not seem right because it needs to be given the start state
    elseif pomcp.solver.value_estimate_method == :rollout
        return rollout(pomcp, start_state, h)
    else
        error("POMCPSolver.value_estimate_method should be :value or :rollout (it was $(pomcp.solver.value_estimate_method)).")
    end
end

"""
    rollout(pomcp::POMCPPlanner, start_state, h::BeliefNode)

Perform a rollout simulation to estimate the value.
"""
function rollout(pomcp::POMCPPlanner, start_state, h::BeliefNode)
    b = extract_belief(pomcp.rollout_updater, h)
    sim = POMDPToolbox.RolloutSimulator(rng=pomcp.solver.rng,
                                        eps=pomcp.solver.eps,
                                        initial_state=start_state)
    r = POMDPs.simulate(sim,
                        pomcp.problem,
                        pomcp.rollout_policy,
                        pomcp.rollout_updater,
                        b)
    h.N += 1 # this does not seem to be in the paper. Is it right?
    return r
end

"""
    extract_belief(rollout_updater::POMDPs.Updater, node::ObsNode) = initialize_belief(rollout_updater, node.B)

Return a belief compatible with the `rollout_updater` from the belief in `node`.

When a rollout simulation is started, this method is used to create the initial belief (compatible with `rollout_updater`) based on the appropriate `BeliefNode` at the edge of the tree. By overriding this, a belief can be constructed based on the entire tree or entire observation-action history. If this is not overriden, by default it will use initialize_belief on the belief associated with the node directly, i.e. `POMDPs.initialize_belief(rollout_updater, node.B)`.
"""
extract_belief(rollout_updater::POMDPs.Updater, node::BeliefNode) = initialize_belief(rollout_updater, node.B)

# some defaults are provided
extract_belief(::POMDPToolbox.VoidUpdater, node::BeliefNode) = nothing
extract_belief{O}(::POMDPToolbox.PreviousObservationUpdater{O}, node::BeliefNode) = Nullable{O}(node.label)
extract_belief{O}(::POMDPToolbox.PreviousObservationUpdater{O}, node::RootNode) = Nullable{O}()
function extract_belief{O}(::POMDPToolbox.FastPreviousObservationUpdater{O}, node::BeliefNode)
  # XXX hack: might be a better way to check this
  if typeof(node.label) <: O
    return node.label
  end
  return node.label[1] # if it's a DPW node, this is the obs (node.label = (o,sp,r))
end
extract_belief{O}(::POMDPToolbox.FastPreviousObservationUpdater{O}, node::RootNode) = error("Observation not available from a root node.")
