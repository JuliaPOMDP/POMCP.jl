
import POMDPModels
using POMCP
import POMDPs
import POMDPToolbox.PreviousObservation

import POMCP.belief_from_node
import POMDPs.action

problem = POMDPModels.BabyPOMDP(-5, -10)
rng = MersenneTwister(1)

#=
type RandomBabyPolicy <: POMDPs.Policy
    rng::AbstractRNG
end
action(p::RandomBabyPolicy, b::POMDPs.Belief) = POMDPModels.BabyAction(rand(p.rng)>0.5)
=#

function belief_from_node(problem::POMDPModels.BabyPOMDP, node::POMCP.ObsNode)
    if node.label == :root
        #XXX Not correct
        return PreviousObservation(POMDPModels.BabyObservation(false))
    end
    return PreviousObservation(node.label)
end

solver = POMCPSolver(POMDPModels.FeedWhenCrying(),
                     0.01,
                     10,
                     1.0,
                     rng)

policy = solve(solver, problem)

sim_rng = MersenneTwister(1)

@show pomcp_reward = POMDPs.simulate(problem, policy, POMDPModels.BabyStateDistribution(0.0), rng=sim_rng, eps=.1)

#=
sim_rng = MersenneTwister(1)
pol_rng = MersenneTwister(2)

@show random_reward = POMDPs.simulate(problem, RandomBabyPolicy(pol_rng), POMDPModels.BabyStateDistribution(0.0), rng=sim_rng, eps=.1)
=#

sim_rng = MersenneTwister(1)

@show good_reward = POMDPs.simulate(problem,
                                    POMDPModels.FeedWhenCrying(),
                                    PreviousObservation(POMDPModels.BabyObservation(false)),
                                    rng=sim_rng,
                                    eps=.1,
                                    initial_state=POMDPModels.BabyState(false))
