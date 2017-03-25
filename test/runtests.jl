using POMCP
using Base.Test

using POMDPModels
using POMDPs
using POMDPToolbox
using ParticleFilters

using NBInclude

pc = ParticleCollection([1,2])

solver = POMCPSolver(estimate_value=RolloutEstimator(FeedWhenCrying()),
                    eps=0.01,
                    c=10.0,
                    tree_queries=50,
                    rng=MersenneTwister(2))

test_solver(solver, BabyPOMDP())

solver = POMCPSolver()
test_solver(solver, BabyPOMDP())

# test FORollout
solver = POMCPSolver(estimate_value=FORollout(FeedWhenCrying()),
                    eps=0.01,
                    c=10.0,
                    tree_queries=50,
                    rng=MersenneTwister(2))

test_solver(solver, BabyPOMDP())


# test for particle depletion
solver = POMCPSolver(estimate_value=RolloutEstimator(FeedWhenCrying()),
                     eps=0.01,
                     c=10.0,
                     tree_queries=5,
                     rng=MersenneTwister(2))

@test_throws ErrorException test_solver(solver, BabyPOMDP(), max_steps=100)

# test for DPW
solver = POMCPDPWSolver(tree_queries=100)

test_solver(solver,BabyPOMDP())

# test for enable/disable action pw
solver = POMCPDPWSolver(tree_queries=100,
                     eps=0.01,
                     c=10.0,
                     enable_action_pw=false,
                     rng=MersenneTwister(2))
test_solver(solver, BabyPOMDP())


test_solver(solver, LightDark1D(), updater=SIRParticleFilter(LightDark1D(), 100))
# test_solver(solver, TigerPOMDP(), updater=DiscreteUpdater

include("visualization.jl")
nbinclude("../notebooks/Display_Tree.ipynb")

nbinclude("../notebooks/Basic_Usage.ipynb")

nbinclude("../notebooks/Minimal_Example.ipynb")

include("Belief_and_Particle_Filter_Options.jl")
