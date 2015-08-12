
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
    return PreviousObservation(node.label)
end

solver = POMCPSolver(POMDPModels.FeedWhenCrying(),
                     0.01,
                     10,
                     500,
                     rng,
                     false)

policy = solve(solver, problem)

N = 100
pomcp_rewards = Array(Float64, N)
fwc_rewards = Array(Float64, N)

for i in 1:N
    sim_rng = MersenneTwister(i)

    pomcp_rewards[i] = POMDPs.simulate(problem,
                                       policy,
                                       POMCPBeliefWrapper(POMDPModels.BabyStateDistribution(0.0)),
                                       rng=sim_rng,
                                       eps=.1,
                                       initial_state=POMDPModels.BabyState(false))

    #=
    sim_rng = MersenneTwister(1)
    pol_rng = MersenneTwister(2)

    @show random_reward = POMDPs.simulate(problem, RandomBabyPolicy(pol_rng), POMDPModels.BabyStateDistribution(0.0), rng=sim_rng, eps=.1)
    =#

    sim_rng = MersenneTwister(i)

    fwc_rewards[i] = POMDPs.simulate(problem,
                                     POMDPModels.FeedWhenCrying(),
                                     PreviousObservation(POMDPModels.BabyObservation(false)),
                                     rng=sim_rng,
                                     eps=.1,
                                     initial_state=POMDPModels.BabyState(false))
end

@show pomcp_avg = mean(pomcp_rewards)
@show fwc_rewards = mean(fwc_rewards)
