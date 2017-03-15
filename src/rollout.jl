"""
    estimate_value(estimator, problem::POMDPs.POMDP, start_state, h::BeliefNode, steps::Int)

Return an initial unbiased estimate of the value at belief node h.

By default this runs a rollout simulation
"""
function estimate_value end
estimate_value(f::Function, pomdp::POMDPs.POMDP, start_state, h::BeliefNode, steps::Int) = f(pomdp, start_state, h, steps)
estimate_value(n::Number, pomdp::POMDPs.POMDP, start_state, h::BeliefNode, steps::Int) = convert(Float64, n)

type PORolloutEstimator
    solver::Union{POMDPs.Solver,POMDPs.Policy,Function}
    updater::POMDPs.Updater
end

type SolvedPORolloutEstimator{P<:POMDPs.Policy,U<:POMDPs.Updater,RNG<:AbstractRNG}
    policy::P
    updater::U
    rng::RNG
end

convert_estimator(ev::Any, solver::AbstractPOMCPSolver, pomdp::POMDPs.POMDP) = ev
function convert_estimator(ev::RolloutEstimator, solver::AbstractPOMCPSolver, pomdp::POMDPs.POMDP)
    policy = convert_to_policy(ev.solver, pomdp)
    SolvedPORolloutEstimator(policy, updater(policy), solver.rng)
end
function convert_estimator(ev::PORolloutEstimator, solver::AbstractPOMCPSolver, pomdp::POMDPs.POMDP)
    policy = convert_to_policy(ev.solver, pomdp)
    SolvedPORolloutEstimator(policy, ev.updater, solver.rng)
end

function estimate_value(estimator::SolvedPORolloutEstimator, pomdp::POMDPs.POMDP, start_state, h::BeliefNode, steps::Int)
    rollout(estimator, pomdp, start_state, h, steps)
end

"""
    rollout(pomcp::POMCPPlanner, start_state, h::BeliefNode)

Perform a rollout simulation to estimate the value.
"""
function rollout(est::SolvedPORolloutEstimator, pomdp::POMDPs.POMDP, start_state, h::BeliefNode, steps::Int)
    b = extract_belief(est.updater, h)
    sim = POMDPToolbox.RolloutSimulator(est.rng,
                                        Nullable{Any}(start_state),
                                        Nullable{Float64}(),
                                        Nullable{Int}(steps))
    return POMDPs.simulate(sim, pomdp, est.policy, est.updater, b)
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
extract_belief{O}(::POMDPToolbox.FastPreviousObservationUpdater{O}, node::BeliefNode) = node.label
extract_belief{O}(::POMDPToolbox.FastPreviousObservationUpdater{O}, node::RootNode) = error("Observation not available from a root node.")
