using POMCP
using Base.Test

using POMDPModels
using POMDPs
using POMDPToolbox

rng = MersenneTwister(2)

problem = BabyPOMDP(-5, -10)
solver = POMCPSolver(rollout_solver=FeedWhenCrying(),
                    eps=0.01,
                    c=10.0,
                    tree_queries=50, 
                    rng=rng,
                    updater=updater(problem))


policy = solve(solver, problem)

a = action(policy, initial_state_distribution(problem))
