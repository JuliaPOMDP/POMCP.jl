module POMCP

import POMDPs

import POMDPs.action
import POMDPs.solve
import Base.rand!
import POMDPs.update_belief!
import POMDPToolbox


export
    POMCPSolver,
    POMCPBeliefWrapper,
    solve,
    action

type POMCPSolver <: POMDPs.Solver
    rollout_policy::POMDPs.Policy
    eps::Float64 # will stop simulations when discount^depth is less than this
    c::Float64
    # timeout::Float64
    tree_queries::Int
    rng::AbstractRNG
    use_particle_filter::Bool 
end
# TODO: make a constructor that will asign sensible defaults

include("types.jl")

type POMCPBeliefWrapper <: POMDPs.Belief
    tree::BeliefNode
end
function POMCPBeliefWrapper(b::POMDPs.Belief)
    return POMCPBeliefWrapper(RootNode(0, deepcopy(b), Dict{Any,ActNode}()))
end
function update_belief!(b::POMCPBeliefWrapper, pomdp::POMDPs.POMDP, a, o)
    b.tree = b.tree.children[a].children[o]
end
function rand!(rng::AbstractRNG, s, d::POMCPBeliefWrapper)
    rand!(rng, s, d.tree.B)
end

include("solver.jl")

end # module
