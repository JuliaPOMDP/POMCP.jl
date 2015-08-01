
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
                     0.1,
                     rng)

policy = POMCP.solve(solver, problem)

@show pomcp_reward = POMDPs.simulate(problem, policy, POMDPModels.BabyStateDistribution(0.0), rng=rng, eps=.1)

@show random_reward = POMDPs.simulate(problem, RandomBabyPolicy(rng), POMDPModels.BabyStateDistribution(0.0), rng=rng, eps=.1)
