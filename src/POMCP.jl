module POMCP

import POMDPs

import POMDPs.action
import POMDPs.solve

export
    POMCPSolver,
    solve,
    action

type POMCPSolver
    rollout_policy::POMDPs.Policy
    eps::Float64 # will stop simulations when discount^depth is less than this
    c::Float64
    timeout::Float64
    rng::AbstractRNG
end

include("solver.jl")

end # module
