abstract BeliefNode

type ActNode
    label::Any # for keeping track of which action this corresponds to
    N::Int64
    V::Float64
    parent::BeliefNode
    children::Dict{Any,Any} # maps observations to ObsNodes

    ActNode() = new()
    ActNode(l,N::Int64,V::Float64,p::BeliefNode,c::Dict{Any,Any}) = new(l,N,V,p,c)
end

# XXX might be faster if I know the exact belief type and obs type -> should parameterize
type ObsNode <: BeliefNode
    label::Any
    N::Int64
    B::Any # belief/state distribution
    parent::ActNode
    children::Dict{Any,ActNode}

    ObsNode() = new()
    ObsNode(l,N,B,p,c) = new(l,N,B,p,c)
end

type RootNode <: BeliefNode
    N::Int64
    B::Any # belief/state distribution
    children::Dict{Any,ActNode}
end

"""
    init_V(problem::POMDPs.POMDP, h::BeliefNode, action)

Return the initial value (V) associated with a new action node when it is created. This can be used in concert with `init_N` to incorporate prior experience into the solver.
"""
function init_V(problem::POMDPs.POMDP, h::BeliefNode, action)
    return 0.0
end

"""
    init_N(problem::POMDPs.POMDP, h::BeliefNode, action)

Return the initial number of queries (N) associated with a new action node when it is created.
"""
function init_N(problem::POMDPs.POMDP, h::BeliefNode, action)
    return 0
end

