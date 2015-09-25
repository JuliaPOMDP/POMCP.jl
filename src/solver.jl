# XXX things to possibly speed this up
# replace recursion with while loop
# cache simulation results

# using Debug

create_policy(::POMCPSolver, ::POMDPs.POMDP) = POMCPPolicy()

# do all the computation necessary to pick the next action
function action(::POMDPs.POMDP, policy::POMCPPolicy, belief::POMDPs.Belief, a=nothing)
    #XXX hack
    if policy._tree_ref == nothing && isa(belief, POMCPBeliefWrapper) 
        policy._tree_ref = belief.tree
    end
    # end hack
    return search(policy, belief, policy.solver.tree_queries)
end

# just return a properly constructed POMCP policy object
function solve(solver::POMCPSolver, pomdp::POMDPs.POMDP)
    policy = POMCPPolicy(pomdp, solver)
    return policy
end

function search(pomcp::POMCPPolicy, belief::POMDPs.Belief, tree_queries)
    if pomcp.solver.use_particle_filter
        error("When using the pomcp particle filter, you must use a POMCPBeliefWrapper")
    end
    # XXX
    # println("Creating new tree") # TODO: Document this behavior
    return search(pomcp, POMCPBeliefWrapper(belief), tree_queries)
end

# Search for the best next move
function search(pomcp::POMCPPolicy, belief::POMCPBeliefWrapper, tree_queries) 
	# cache = SimulateCache{S}()
    s = POMDPs.create_state(pomcp.problem)

	# finish_time = time() + timeout
	# while time() < finish_time
    for i in 1:pomcp.solver.tree_queries
		rand!(pomcp.solver.rng, s, belief)
		# simulate(pomcp, belief.tree, deepcopy(s), 0) # cache)
		simulate(pomcp, belief.tree, s, 0) # why was the deepcopy above?
	end
    # println("Search complete. Tree queried $(belief.tree.N) times")

    best_V = -Inf
    best_node = ActNode() # for type stability
    for node in values(belief.tree.children)
        if node.V >= best_V
            best_V = node.V
            best_node = node
        end
    end
    return best_node.label
end

function simulate(pomcp::POMCPPolicy, h::BeliefNode, s, depth) # cache::SimulateCache)

    if POMDPs.discount(pomcp.problem)^depth < pomcp.solver.eps || POMDPs.isterminal(pomcp.problem, s)
        return 0
    end
	if isempty(h.children)
        action_space = sparse_actions(pomcp.problem, s, h, pomcp.solver.num_sparse_actions)
		h.children = Dict{Any,ActNode}()
		for a in action_space 
			h.children[a] = ActNode(a,
                                    init_N(pomcp.problem, h, a),
                                    init_V(pomcp.problem, h, a),
                                    h,
                                    Dict())
		end

		return rollout(pomcp, s, h, depth)
	end

    best_criterion_val = -Inf
    best_node = nothing
    for node in values(h.children)
        if node.N == 0 && h.N == 1
            criterion_value = node.V
        else 
            criterion_value = node.V + pomcp.solver.c*sqrt(log(h.N)/node.N)
        end
        if criterion_value >= best_criterion_val
            best_criterion_val = criterion_value
            best_node = node
        end
    end
    a = best_node.label

    r = POMDPs.reward(pomcp.problem, s, a)

    sp = POMDPs.create_state(pomcp.problem)
    o = POMDPs.create_observation(pomcp.problem)

    trans_dist = POMDPs.transition(pomcp.problem, s, a)
    rand!(pomcp.solver.rng, sp, trans_dist)

    obs_dist = POMDPs.observation(pomcp.problem, sp, a)
    rand!(pomcp.solver.rng, o, obs_dist)

    if haskey(best_node.children, o)
        hao = best_node.children[o]
    else
        if pomcp.solver.use_particle_filter
            hao = ObsNode(o, 0, ParticleCollection(), best_node, {})
        else
            new_belief = belief(pomcp.problem, h.B, a, o)
            hao = ObsNode(o, 0, new_belief, best_node, Dict{Any,ActNode}())
        end
        best_node.children[o]=hao
    end

    R = r + POMDPs.discount(pomcp.problem)*simulate(pomcp, hao, sp, depth+1)

    if pomcp.solver.use_particle_filter
        push!(h.B.particles, s)
    end
    h.N += 1

    best_node.N += 1
    best_node.V += (R-best_node.V)/best_node.N

    return R
end

function rollout(pomcp::POMCPPolicy, start_state, h::BeliefNode, depth)
    b = belief_from_node(pomcp.solver.node_converter, h)
    sim = POMDPToolbox.RolloutSimulator(rng=pomcp.solver.rng,
                                        eps=pomcp.solver.eps,
                                        initial_state=start_state,
                                        initial_belief=b)
    r = POMDPs.simulate(sim,
                        pomcp.problem,
                        pomcp.solver.rollout_policy)
    h.N += 1 # this does not seem to be in the paper. Is it right?
    return POMDPs.discount(pomcp.problem)^depth * r
end

function init_V(problem::POMDPs.POMDP, h::BeliefNode, action)
    return 0.0
end

function init_N(problem::POMDPs.POMDP, h::BeliefNode, action)
    return 0
end

function belief_from_node(converter::NodeBeliefConverter, node::BeliefNode)
    error("$(typeof(converter)) does not implement belief_from_node")
end
