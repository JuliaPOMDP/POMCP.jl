using POMCP
using Base.Test

using POMDPModels
using POMDPs
using POMDPToolbox

solver = POMCPSolver(rollout_solver=FeedWhenCrying(),
                    eps=0.01,
                    c=10.0,
                    tree_queries=50, 
                    rng=MersenneTwister(2))

test_solver(solver, BabyPOMDP())
