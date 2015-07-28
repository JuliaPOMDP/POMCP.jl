
import POMDPModels
import POMCP
import POMDPs

problem = POMDPModels.BabyPOMDP(-0.1, -1)

type RandomBabyPolicy <: POMDPs.Policy
    rng::AbstractRNG
end

action(p::RandomBabyPolicy, b::POMDPs.Belief) = BabyAction(rand(p.rng)>0.5)

rng = MersenneTwister(1)

solver = POMCP.POMCPSolver(RandomBabyPolicy(rng),
                     0.01,
                     10,
                     10,
                     rng)

POMCP.solve(solver, problem)
