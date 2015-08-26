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
    action,
    to_json_file

type POMCPSolver <: POMDPs.Solver
    rollout_policy::POMDPs.Policy
    eps::Float64 # will stop simulations when discount^depth is less than this
    c::Float64
    # timeout::Float64
    tree_queries::Int
    rng::AbstractRNG
    use_particle_filter::Bool # this should probably actually be a belief wrapper property
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
    if haskey(b.tree.children, a)
        if haskey(b.tree.children[a].children, o)
            b.tree = b.tree.children[a].children[o]
        else
            # TODO this will fail for the particle filter... then what?
            new_belief = deepcopy(b.tree.B)
            update_belief!(new_belief, pomdp, a, o)
            b.tree = ObsNode(o, 0, new_belief, b.tree.children[a], Dict{Any,ActNode}())
        end
    end
end
function rand!(rng::AbstractRNG, s, d::POMCPBeliefWrapper)
    rand!(rng, s, d.tree.B)
end

include("solver.jl")
include("visualization.jl")

end # module
