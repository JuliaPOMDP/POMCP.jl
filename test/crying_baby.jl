import POMDPModels
using POMCP
import POMDPs
import POMDPToolbox.PreviousObservation

import POMCP.belief_from_node
import POMCP.init_V
import POMDPs.action

problem = POMDPModels.BabyPOMDP(-5, -10)

using Debug

#=
type RandomBabyPolicy <: POMDPs.Policy
    rng::AbstractRNG
end
action(p::RandomBabyPolicy, b::POMDPs.Belief) = POMDPModels.BabyAction(rand(p.rng)>0.5)
=#

# init_V(::POMDPModels.BabyPOMDP, node::POMCP.BeliefNode, a) = -30.0

function belief_from_node(problem::POMDPModels.BabyPOMDP, node::POMCP.ObsNode)
    return PreviousObservation(node.label)
end

N = 5000
eps = 0.01

# rng = MersenneTwister(1)
# 
# solver = POMCPSolver(POMDPModels.FeedWhenCrying(),
#                      0.01,
#                      10,
#                      1000, 
#                      rng,
#                      false)
# 
# policy = solve(solver, problem)
#
# @debug begin
#     rng_seed = 2
#     sim_rng = MersenneTwister(rng_seed)
#     pomcp_result = POMDPs.simulate(problem,
#                     policy,
#                     POMCPBeliefWrapper(POMDPModels.BabyStateDistribution(0.0)),
#                     rng=sim_rng,
#                     eps=.1,
#                     initial_state=POMDPModels.BabyState(false))
#     
#     sim_rng = MersenneTwister(rng_seed)
#     fwc_result = POMDPs.simulate(problem,
#                     POMDPModels.FeedWhenCrying(),
#                     PreviousObservation(POMDPModels.BabyObservation(false)),
#                     rng=sim_rng,
#                     eps=.1,
#                     initial_state=POMDPModels.BabyState(false))
# end

@time pomcp_sum = @parallel (+) for i in 1:N
    sim_rng = MersenneTwister(i)

    rng = MersenneTwister(i+1000)

    solver = POMCPSolver(POMDPModels.FeedWhenCrying(),
                         0.01,
                         10,
                         500, 
                         rng,
                         false)

    policy = solve(solver, problem)


    POMDPs.simulate(problem,
                    policy,
                    # POMDPModels.BabyStateDistribution(0.0),
                    POMCPBeliefWrapper(POMDPModels.BabyStateDistribution(0.0)),
                    rng=sim_rng,
                    eps=eps,
                    initial_state=POMDPModels.BabyState(false))

end

fwc_sum = @parallel (+) for i in 1:N
    sim_rng = MersenneTwister(i)

    POMDPs.simulate(problem,
                    POMDPModels.FeedWhenCrying(),
                    PreviousObservation(POMDPModels.BabyObservation(false)),
                    rng=sim_rng,
                    eps=eps,
                    initial_state=POMDPModels.BabyState(false))
end

@show pomcp_avg = pomcp_sum/N 
@show fwc_rewards = fwc_sum/N
