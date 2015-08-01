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
    eps # will stop simulations when discount^depth is less than this
    c
    timeout
    rng
end

include("solver.jl")

end # module
