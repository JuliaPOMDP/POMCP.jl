
import POMDPModels
import POMCP
import POMDPs

import POMDPs.action

problem = POMDPModels.BabyPOMDP(-0.1, -1)

type RandomBabyPolicy <: POMDPs.Policy
    rng::AbstractRNG
end

action(p::RandomBabyPolicy, b::POMDPs.Belief) = POMDPModels.BabyAction(rand(p.rng)>0.5)

rng = MersenneTwister(1)

solver = POMCP.POMCPSolver(RandomBabyPolicy(rng),
                     0.01,
                     10,
                     0.01,
                     rng)

policy = POMCP.solve(solver, problem)

sim_rng = MersenneTwister(1)

@show pomcp_reward = POMDPs.simulate(problem, policy, POMDPModels.BabyStateDistribution(0.0), rng=sim_rng, eps=.1)

sim_rng = MersenneTwister(1)
pol_rng = MersenneTwister(2)

@show random_reward = POMDPs.simulate(problem, RandomBabyPolicy(pol_rng), POMDPModels.BabyStateDistribution(0.0), rng=sim_rng, eps=.1)

sim_rng = MersenneTwister(1)
pol_rng = MersenneTwister(2)

@show random_reward = POMDPs.simulate(problem, RandomBabyPolicy(pol_rng), POMDPModels.BabyStateDistribution(0.0), rng=sim_rng, eps=.1)
