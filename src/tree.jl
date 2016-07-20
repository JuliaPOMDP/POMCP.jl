abstract BeliefNode{S,A,O,B}

# Note: links to parents were taken out because they hadn't been used in anything we've done so far
# Note: the label is really only important for visualization

type ActNode{A, O, BNodeType <: BeliefNode} # Need A, O, everything in belief
    label::A # for keeping track of which action this corresponds to
    N::Int64
    V::Float64
    children::Dict{O, BNodeType} # maps observations to ObsNodes
end

type DPWObsNode{S,A,O,Belief} <: BeliefNode{S,A,O,Belief}
    label::O
    state::S
    reward::Float64
    N::Int64
    B::Belief # belief/state distribution
    children::Dict{A,ActNode{A,O,DPWObsNode{S,A,O,Belief}}}
end

type ObsNode{S,A,O,Belief} <: BeliefNode{S,A,O,Belief}
    label::O
    N::Int64
    B::Belief # belief/state distribution
    children::Dict{A,ActNode{A,O,ObsNode{S,A,O,Belief}}}
end

type RootNode{RootBelief} <: BeliefNode
    N::Int64
    B::RootBelief # belief/state distribution
    children::Dict{Any,ActNode} # ActNode not parameterized here to make initialize_belief more flexible
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
