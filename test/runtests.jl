using POMCP
using Base.Test

using POMDPModels
using POMDPs
using POMDPToolbox

POMCP.required_methods()

pc = ParticleCollection([1,2])

solver = POMCPSolver(rollout_solver=FeedWhenCrying(),
                    eps=0.01,
                    c=10.0,
                    tree_queries=50,
                    rng=MersenneTwister(2))

test_solver(solver, BabyPOMDP())

solver = POMCPSolver()
test_solver(solver, BabyPOMDP())

# test for particle depletion
solver = POMCPSolver(rollout_solver=FeedWhenCrying(),
                     eps=0.01,
                     c=10.0,
                     tree_queries=5,
                     rng=MersenneTwister(2))

@test_throws ErrorException test_solver(solver, BabyPOMDP(), max_steps=100)

solver = POMCPDPWSolver(tree_queries=100)

test_solver(solver,BabyPOMDP())

include("visualization.jl")
