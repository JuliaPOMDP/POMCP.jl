# XXX things to possibly speed this up
# replace recursion with while loop
# cache simulation results

type POMCPPolicy <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    rng::AbstractRNG
end

type ParticleCollection{S} <: POMDPs.Belief
    particles::Set{S}
end
ParticleCollection{S}() = ParticleCollection(S[])
function rand!{S}(rng::AbstractRNG, sample, b::ParticleCollection{S})
    return b[ceil(rand(rng)*length(b))]
end

type ActNode
    label::Any # for keeping track of which action this corresponds to
    N::Int64
    V::Float64
    children::Vector{Any} # should be Vector{ObsNode}, but there is a circular reference
end

type ObsNode
    label::Any
    N::Int64
    B::POMDPs.AbstractDistribution
    children::Vector{Any} # should be Vector{ActNode}, but there is a circular reference
end

# do all the computation necessary to pick the next action
function action(policy::POMCPPolicy, belief::POMDPs.Belief)
    return search(policy, belief)
end

# just return a properly constructed POMCP policy object
function solve(solver::POMCPSolver, pomdp::POMDPs.POMDP)
    return POMCPPolicy(pomdp, solver, MersenneTwister(0))
end

# Search for the best next move
function search(pomcp::POMCPPolicy, belief::POMDPs.Belief, timeout) 
	finish_time = time() + timeout
	num_sim = 0
	# cache = SimulateCache{S}()
    #XXX need some way to get the state type
    s = create_state(pomcp.problem)
	while time() < finish_time
		rand!(pomcp.rng, s, belief)
        root = Node("root", 0, -Inf, belief, Node[])
		simulate(pomcp, copy(s), root, 0) # cache)
		num_sim += 1
	end
	best_ind = indmax([action.V for action in root.children])
    return root.children[best_ind].label, num_sim
end

function simulate(pomcp::POMCPPolicy, h::ObsNode, s, depth) # cache::SimulateCache)

    if discount(pomcp.problem)^depth < pomcp.solver.eps
        return 0
    end
	if length(h.children) == 0
        action_space = actions(pomcp.problem)
		h.children = Array(ActNode, length(action_space))
		for i in 1:length(h.children)
			h.children[i] = ActNode(action_space[i], 0, -Inf)
		end

		return rollout(pomcp, s, h, depth)
	end

    best_ind = indmax([action.V + pomcp.solver.c*sqrt(log(h.N)/action.N) for action in h.children])
    a = h.children[best_ind].label

    r = reward(pomcp.problem, s, a)

    obs_dist = create_observation(pomcp.problem)
    trans_dist = create_transition(pomcp.problem)
    sp = create_state(pomcp.problem)
    o = create_obs(pomcp.problem)

    transition!(trans_dist, pomcp.problem, s, a)
    rand!(pomcp.rng, sp, trans_dist)

    observation!(obs_dist, pomcp.problem, sp, a)
    rand!(pomcp.rng, o, obs_dist)

    hao = ObsNode(o, 0, ParticleCollection{typeof(s)}())
    push!(h.children[best_ind], hao)

    R = r + discount*simulate(pomcp, sp, hao, depth+1)

    push!(h.B, s)
    h.N += 1

    h.children[best_ind].N += 1
    h.children[best_ind].V += (R-h.children[best_ind].V)/h.children[best_ind].N

    return R
end

function rollout(pomcp::POMCPPolicy, start_state, h::ObsNode, depth)
    discount = discount(pomcp.problem)
    discount_at_depth = discount^depth
    r = 0
    s = deepcopy(start_state)
    b = belief_from_node(pomcp.problem, h)

    obs_dist = create_observation(pomcp.problem)
    trans_dist = create_transition(pomcp.problem)
    sp = create_state(pomcp.problem)
    o = create_obs(pomcp.problem)

    while discount_at_depth >= pomcp.solver.eps && !isterminal(s)
        a = get_action(pomcp.solver.rollout_policy, b)
        r += discount_at_depth*reward(pomcp.problem, s, a)

        transition!(trans_dist, pomcp.problem, s, a)
        rand!(pomcp.rng, sp, trans_dist)

        observation!(obs_dist, pomcp.problem, sp, a)
        rand!(pomcp.rng, o, obs_dist)

        # alternates using the memory allocated for s and sp so nothing has to be allocated
        tmp = s
        s = sp
        sp = tmp

        update_belief!(b, pomcp.problem, a, o)

        discount_at_depth*=discount
    end
    return r
end


# for use with a random rollout policy
type EmptyBelief <: POMDPs.Belief
end
function update_belief!(b::EmptyBelief, p::POMDPs.POMDP, a, o)
end

function belief_from_node(problem::POMDPs.POMDP, node::ObsNode)
    return EmptyBelief()
end


