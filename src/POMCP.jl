module POMCP

import POMDPs

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
