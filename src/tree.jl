abstract BeliefNode{A,O,B}

# Note: links to parents were taken out because they hadn't been used in anything we've done so far
# Note: probably don't need the labels, but they don't seem like they would really kill performance

type ActNode{A, O, BNodeType <: BeliefNode} # Need A, O, everything in belief
    label::A # for keeping track of which action this corresponds to
    N::Int
    V::Float64
    children::Dict{O, BNodeType} # maps observations to ObsNodes
end

type ObsNode{A,O,Belief} <: BeliefNode{A,O,Belief}
    label::O
    N::Int # for dpw, this is the number of times we have transitioned from parent to this from the parent
    B::Belief # belief/state distribution
    children::Dict{A,ActNode{A,O,ObsNode{A,O,Belief}}}
end

type RootNode{RootBelief} <: BeliefNode
    N::Int
    B::RootBelief # belief/state distribution
    children::Dict{Any,ActNode} # ActNode not parameterized here to make initialize_belief more flexible
end
RootNode{RootBelief}(b::RootBelief) = RootNode{RootBelief}(0, b, Dict{Any,ActNode}())

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
