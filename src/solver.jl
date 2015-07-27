# XXX things to possibly speed this up
# replace recursion with while loop
# cache simulation results

type POMCPPolicy <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    rng::AbstractRNG
end

type ParticleCollection{S} <: POMDPs.AbstractDistribution
    particles::Set{S}
end
ParticleCollection{S}() = ParticleCollection{S}(S[])
function rand!{S}(rng::AbstractRNG, sample, b::ParticleCollection{S})
    return b[ceil(rand(rng)*length(b))]
end

type ActNode
    label::Any # for keeping track of which action this corresponds to
    N::Int64
    V::Float64
    children::Vector{ObsNode}
end

type ObsNode
    label::Any
    N::Int64
    B::POMDPs.AbstractDistribution
    children::Vector{ActNode}
end

# do all the computation necessary to pick the next action
function get_action(policy::POMCPPolicy, belief::POMDPs.AbstractDistribution)
end

# just return a properly constructed POMCP policy object
function solve(solver::POMCPSolver, pomdp::POMDPs.POMDP)
    return POMCPPolicy(pomdp, solver, MersenneTwister(0))
end

# Search for the best next move
function search(pomcp::POMCPPolicy, belief::POMDPs.AbstractDistribution, timeout) 
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

    obs_dist = create_observation(pomcp.problem)
    trans_dist = create_transition(pomcp.problem)
    sp = create_state(pomcp.problem)
    o = create_obs(pomcp.problem)

    observation!(obs_dist, pomcp.problem, s, a)
    transition!(trans_dist, pomcp.problem, s, a)

    rand!(pomcp.rng, o, obs_dist)
    rand!(pomcp.rng, sp, trans_dist)
    r = reward(pomcp.problem, s, a)

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
    b = belief_from_node(h)

    obs_dist = create_observation(pomcp.problem)
    trans_dist = create_transition(pomcp.problem)
    sp = create_state(pomcp.problem)
    o = create_obs(pomcp.problem)

    while discount_at_depth >= pomcp.solver.eps && !isterminal(s)
        a = get_action(pomcp.solver.rollout_policy, b)

        observation!(obs_dist, pomcp.problem, s, a)
        transition!(trans_dist, pomcp.problem, s, a)

        rand!(pomcp.rng, o, obs_dist)
        rand!(pomcp.rng, sp, trans_dist)
        r += discount_at_depth*reward(pomcp.problem, s, a)

        # alternates using the memory allocated for s and sp so nothing has to be allocated
        tmp = s
        s = sp
        sp = tmp

        update_belief!(b, pomcp.problem, a, o)

        discount_at_depth*=discount
    end
    return r
end

# below is stuff from skywalker's implementation

# using Iterators
# 
# type Tree
# 	N::Int64
# 	V::Float64
# 	# σ²::Float64 # don't implement this yet, and when we do, use chars one can type on a keyboard
# 	children::Vector{Tree}
# end
# Tree(N,V) = Tree(N,V,0.0,Array(Tree,0))
# 
# typealias ActionNode Tree
# typealias ObsNode Tree
# 
# type SimulateCache{S}
# 	action_nodes::Vector{ActionNode}
# 	obs_nodes::Vector{ObsNode}
# 	rewards::Vector{Float64}
# 	sor::SORTuple{S}
# 
# 	SimulateCache() = new(ActionNode[], ObsNode[], Float64[], SORTuple{S}())
# end
# 
# function empty!(cache::SimulateCache)
# 	Base.empty!(cache.action_nodes)
# 	Base.empty!(cache.obs_nodes)
# 	Base.empty!(cache.rewards)
# end

# Search for the best next move
# function search{S}(pomcp::POMCP, T::ActionNode, B::Vector{S}, timeout; 
# 				γ=.9, ϵ=1e-5, c=10.0)
# 	finish_time = time() + timeout
# 	num_sim = 0
# 	cache = SimulateCache{S}()
# 	while time() < finish_time
# 		s = B[rand(1:length(B))]
# 		simulate(pomcp, T, copy(s), γ, ϵ, c, cache)
# 		num_sim += 1
# 	end
# 	indmax([S.V for S in T.children]), num_sim
# end

# Perform the next playout
# function simulate(pomcp::POMCP, T::ActionNode, s::State, γ, ϵ, c, cache::SimulateCache)
# 
# 	empty!(cache)
# 	action_nodes = cache.action_nodes
# 	obs_nodes = cache.obs_nodes
# 	rewards = cache.rewards
# 	sor = cache.sor
# 	sor.s = s
# 
# 	discount = γ
# 	while discount > ϵ && !s.terminal
# 
# 		if length(T.children) == 0
# 			T.children = Array(ObsNode, num_actions(pomcp))
# 			for i in 1:num_actions(pomcp)
# 				@inbounds T.children[i] = ObsNode(0,0)
# 			end
# 
# 			push!(rewards, rollout!(pomcp,s,γ,ϵ*discount))
# 			break
# 		end
# 
# 		a = next_sample!(pomcp,T,sor.s,sor,c)
# 
# 		S = T.children[a]
# 		if length(S.children) == 0
# 			S.children = Array(ActionNode, num_obs(pomcp))
# 			for i in 1:num_obs(pomcp)
# 				@inbounds S.children[i] = ActionNode(0,0)
# 			end
# 		end
# 
# 		push!(action_nodes, T)
# 		push!(obs_nodes, S)
# 		push!(rewards, sor.r)
# 
# 		T = S.children[sor.o]
# 		discount *= γ
# 	end
# 
# 	reward = 0.0
# 	if length(rewards) > length(action_nodes)
# 		reward = rewards[length(rewards)]
# 	end
# 
# 	for i in reverse(1:length(action_nodes))
# 		reward = rewards[i] + γ * reward
# 		action_nodes[i].N += 1
# 		obs_nodes[i].N += 1
# 
# 		N = obs_nodes[i].N
# 		if N == 2
# 			obs_nodes[i].σ² = (reward - obs_nodes[i].V)^2/N
# 		elseif N > 2
# 			obs_nodes[i].σ² = (N-2)*obs_nodes[i].σ²/(N-1) + (reward - obs_nodes[i].V)^2/N
# 		end
# 		# println(obs_nodes[i].σ²)
# 		obs_nodes[i].V += (reward - obs_nodes[i].V)/N
# 	end
# end

# Select the action in this playout
# function next_sample!(pomcp::POMCP, T::ActionNode, s::State, sor::SORTuple, c::Float64)
# 	k = num_actions(pomcp)
# 	α = log(T.N)
# 	valid = false
# 	@inbounds while true
# 		a = -1
# 		v = -Inf
# 		offset = rand(1:k)
# 		for j in 1:k
# 			i = j + offset
# 			if i > k
# 				i -= k
# 			end
# 
# 			if T.children[i].V == -Inf
# 				continue
# 			end
# 
# 			ni = T.children[i].N
# 			if ni < 2
# 				a = i
# 				break
# 			end
# 
# 
# 			# A variation of UCB* that takes into account variance info
# 			vi = T.children[i].V + 13 * sqrt(T.children[i].σ² * α / ni)
# 
# 			if vi > v
# 				a = i
# 				v = vi
# 			end
# 		end
# 
# 		if a == -1
# 			println("No valid actions.")
# 			continue
# 		end
# 
# 		valid = sample!(pomcp,s,get_action(pomcp,a),sor)
# 		if valid
# 			return a
# 		else
# 			T.children[a].V = -Inf
# 		end
# 	end
# end

# Play through a game until the end
# function play{S <: State}(pomcp::POMCP, B::Vector{S}, s::S)
# 	reward = 0.0
# 	dreward = 0.0
# 	discount = 1.0
# 	T = ActionNode(0,0)
# 	while true 
# 		gc() # Garbage collect so that playout times are consistent
# 		a, num_sim = search(pomcp, T, B, 1, γ=.95, ϵ=0)	
# 		action = get_action(pomcp,a)
# 		s,o,r = sample(pomcp,s,action)
# 		T = T.children[a].children[o]
# 		reward += r
# 		dreward += discount * r
# 		discount *= .95
# 		B = update_belief(pomcp,B,action,o,r)
# 		println("Action: $action, Reward: $r, State: $s, Obs: $o")
# 		println("     Simulations: $num_sim")	
# 
# 		if is_terminal(s)
# 			break
# 		end
# 	end
# 	println("Total reward: $reward")
# 	println("Total discounted reward: $dreward")
# end

# function update_belief{S <: State}(pomcp::POMCP, 
# 								   B::Vector{S}, 
# 	 							   a::Action, 
# 	 							   o::Observation, 
# 	 							   r::Float64)
# 	B′ = Array(S, length(B))
# 	i = 1
# 	sor = SORTuple{S}()
# 	while i <= length(B)
# 		s = B[rand(1:length(B))]
# 		sample!(pomcp, copy(s), a, sor)	
# 		if sor.o == o && sor.r == r
# 			B′[i] = sor.s
# 			i += 1
# 		end
# 	end
# 	B′
# end
