# XXX things to possibly speed this up
# replace recursion with while loop
# cache simulation results

create_policy(::POMCPSolver, ::POMDPs.POMDP) = POMCPPolicy()

function action(policy::POMCPPolicy, belief::POMDPs.Belief, a=nothing)
    #XXX hack
    if isnull(policy._tree_ref) && isa(belief, POMCPPolicyState) 
        policy._tree_ref = belief.tree
    end
    # end hack
    return search(policy, belief, policy.solver.tree_queries)
end

"""
    solve(solver::POMCPSolver, pomdp::POMDPs.POMDP)

Simply return a properly constructed POMCPPolicy object.
"""
function solve(solver::POMCPSolver, pomdp::POMDPs.POMDP)
    if isa(solver.rollout_solver, POMDPs.Policy)
        rollout_policy = solver.rollout_solver
    else
        rollout_policy = solve(solver.rollout_solver, pomdp)
    end
    rollout_updater = updater(rollout_policy)
    return POMCPPolicy(pomdp, solver, rollout_policy, rollout_updater)
end

"""
    function search(pomcp::POMCPPolicy, b::POMCPPolicyState, tree_queries) 
    function search(pomcp::POMCPPolicy, b::POMDPs.Belief, tree_queries)

Search the tree for the next best move.
"""
function search(pomcp::POMCPPolicy, belief::POMDPs.Belief, tree_queries)
    if isa(pomcp.solver.updater, ParticleCollectionUpdater)
        error("execution should never get here... something's wrong")
    end
    # println("Creating new tree") # TODO: Document this behavior
    return search(pomcp, POMCPPolicyState(belief), tree_queries)
end

function search(pomcp::POMCPPolicy, b::POMCPPolicyState, tree_queries) 

    for i in 1:pomcp.solver.tree_queries
		s = rand(pomcp.solver.rng, b)
		simulate(pomcp, b.tree, s, 0) # why was the deepcopy above?
	end

    best_V = -Inf
    best_node = ActNode() # for type stability
    for node in values(b.tree.children)
        if node.V >= best_V
            best_V = node.V
            best_node = node
        end
    end
    return best_node.label
end

"""
    simulate{S}(pomcp::POMCPPolicy, h::BeliefNode, s::S, depth)

Move the simulation forward a single step and update the BeliefNode h accordingly.
"""
function simulate{S}(pomcp::POMCPPolicy, h::BeliefNode, s::S, depth)

    if POMDPs.discount(pomcp.problem)^depth < pomcp.solver.eps || POMDPs.isterminal(pomcp.problem, s)
        return 0
    end
	if isempty(h.children)
        action_space_iter = sparse_actions(pomcp, pomcp.problem, h, pomcp.solver.num_sparse_actions)
		h.children = Dict{Any,ActNode}()
		for a in action_space_iter
			h.children[a] = ActNode(a,
                                    init_N(pomcp.problem, h, a),
                                    init_V(pomcp.problem, h, a),
                                    h,
                                    Dict())
		end

		return POMDPs.discount(pomcp.problem)^depth * estimate_value(pomcp, pomcp.problem, s, h)
	end

    best_criterion_val = -Inf
    local best_node
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

    (sp, o, r) = GenerativeModels.generate_sor(pomcp.problem, s, a, pomcp.solver.rng)

    if haskey(best_node.children, o)
        hao = best_node.children[o]
    else
        if isa(pomcp.solver.updater, ParticleCollectionUpdater)
            hao = ObsNode(o, 0, ParticleCollection{S}(), best_node, Dict{Any,ActNode}())
        else
            new_belief = update(pomcp.solver.updater, h.B, a, o) # this relies on h.B not being modified
            hao = ObsNode(o, 0, new_belief, best_node, Dict{Any,ActNode}())
        end
        best_node.children[o]=hao
    end

    R = r + POMDPs.discount(pomcp.problem)*simulate(pomcp, hao, sp, depth+1)

    # if isa(pomcp.solver.updater, ParticleCollectionUpdater) && !isa(h, RootNode)
    if isa(h.B, ParticleCollection)
        push!(h.B.particles, s)
    end
    h.N += 1

    best_node.N += 1
    best_node.V += (R-best_node.V)/best_node.N

    return R
end

"""
    rollout(pomcp::POMCPPolicy, start_state, h::BeliefNode)

Perform a rollout simulation to estimate the value.
"""
function rollout(pomcp::POMCPPolicy, start_state, h::BeliefNode)
    b = convert_belief(pomcp.rollout_updater, h)
    sim = POMDPToolbox.RolloutSimulator(rng=pomcp.solver.rng,
                                        eps=pomcp.solver.eps,
                                        initial_state=start_state)
    r = POMDPs.simulate(sim,
                        pomcp.problem,
                        pomcp.rollout_policy,
                        pomcp.rollout_updater,
                        b)
    h.N += 1 # this does not seem to be in the paper. Is it right?
    return r
end
