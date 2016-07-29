# XXX things to possibly speed this up
# replace recursion with while loop
# cache simulation results

create_policy(s::Union{POMCPSolver,POMCPDPWSolver}, p::POMDPs.POMDP) = solve(s,p)

function action(policy::POMCPPlanner, belief, a=nothing)
    return search(policy, belief, policy.solver.tree_queries)
end

"""
    solve(solver::POMCPSolver, pomdp::POMDPs.POMDP)

Simply return a properly constructed POMCPPlanner object.
"""
function solve{S}(solver::Union{POMCPSolver,POMCPDPWSolver}, pomdp::POMDPs.POMDP{S})
    if isa(solver.rollout_solver, POMDPs.Policy)
        rollout_policy = solver.rollout_solver
    else
        rollout_policy = solve(solver.rollout_solver, pomdp)
    end
    if isa(solver.node_belief_updater, DefaultReinvigoratorStub)
        node_belief_updater = DeadReinvigorator{S}()
    else
        node_belief_updater = solver.node_belief_updater
    end
    rollout_updater = updater(rollout_policy)
    return POMCPPlanner(pomdp, solver, node_belief_updater, rollout_policy, rollout_updater, Nullable{Any}())
end

solve(solver::Union{POMCPSolver,POMCPDPWSolver}, pomdp::POMDPs.POMDP, dummy_policy) = solve(solver, pomdp)

"""
    function search(pomcp::POMCPPlanner, b::BeliefNode, tree_queries)
    function search(pomcp::POMCPPlanner, b::Any, tree_queries)

Search the tree for the next best move.

If b is not a belief node, the policy will attempt to convert it.
"""
function search{RootBelief}(pomcp::POMCPPlanner, belief::RootBelief, tree_queries)
    new_node = RootNode(belief)
    return search(pomcp, new_node, tree_queries)
end

function search(pomcp::POMCPPlanner, b::BeliefNode, tree_queries)
    #XXX hack
    pomcp._tree_ref = b
    # end hack

    for i in 1:tree_queries
        s = rand(pomcp.solver.rng, b)
        simulate(pomcp, b, s, 0)
        b.N += 1
    end

    best_V = -Inf
    local best_node # guessing that type stability is not important enough to make a difference at this point
    for node in values(b.children)
        if node.V >= best_V
            best_V = node.V
            best_node = node
        end
    end

    return best_node.label
end

"""
    simulate{S}(pomcp::POMCPPlanner, h::BeliefNode, s::S, depth)

Move the simulation forward a single step and update the BeliefNode h accordingly.
"""
function simulate{S,A,O,B}(pomcp::POMCPPlanner{S,A,O,B,POMCPSolver}, h::BeliefNode, s::S, depth)

    if POMDPs.discount(pomcp.problem)^depth < pomcp.solver.eps ||
            POMDPs.isterminal(pomcp.problem, s) ||
            depth >= pomcp.solver.max_depth
        return 0
    end
	if isempty(h.children)
        action_space_iter = sparse_actions(pomcp, pomcp.problem, h, pomcp.solver.num_sparse_actions)
		h.children = Dict{Any,ActNode}()
		for a in action_space_iter
			h.children[a] = ActNode(a,
                                    init_N(pomcp.problem, h, a),
                                    init_V(pomcp.problem, h, a),
                                    Dict{O,ObsNode{B,A,O}}())
		end

        if depth > 0 # no need for a rollout if this is the root node
            return POMDPs.discount(pomcp.problem)^depth * estimate_value(pomcp, pomcp.problem, s, h, depth)
        else
            return 0.
        end
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
        if isa(pomcp.node_belief_updater, ParticleReinvigorator)
            hao = ObsNode(o, 0, ParticleCollection{S}(), Dict{A,ActNode{A,O,ObsNode{B,A,O}}}())
        else
            new_belief = update(pomcp.node_belief_updater, h.B, a, o) # this relies on h.B not being modified
            hao = ObsNode(o, 0, new_belief, Dict{A,ActNode{A,O,ObsNode{B,A,O}}}())
        end
        best_node.children[o]=hao
    end

    R = r + POMDPs.discount(pomcp.problem)*simulate(pomcp, hao, sp, depth+1)

    if uses_states_from_planner(hao.B)
        push!(hao.B, sp) # insert this state into the particle collection
    end
    hao.N += 1

    best_node.N += 1
    best_node.V += (R-best_node.V)/best_node.N

    return R
end



function simulate{S,A,O,B}(pomcp::POMCPPlanner{S,A,O,B,POMCPDPWSolver}, h::BeliefNode, s::S, depth)

    if POMDPs.discount(pomcp.problem)^depth < pomcp.solver.eps ||
            POMDPs.isterminal(pomcp.problem, s) ||
            depth >= pomcp.solver.max_depth
        return 0
    end

    total_N = reduce(add_N, 0, values(h.children))
    if length(h.children) <= pomcp.solver.k_action*total_N^pomcp.solver.alpha_action
        a = next_action(pomcp.solver.gen, pomcp.problem, s, h)
        if !(a in keys(h.children))
            h.children[a] = ActNode(a,
                                    init_N(pomcp.problem, h, a),
                                    init_V(pomcp.problem, h, a),
                                    Dict{O,ObsNode{B,A,O}}())
        end
        if length(h.children) <= 1
            if depth > 0
                return POMDPs.discount(pomcp.problem)^depth * estimate_value(pomcp, pomcp.problem, s, h, depth)
            else
                return 0.
            end
        end
    end

    # Calculate UCT
    best_criterion_val = -Inf
    local best_node
    for (a,node) in h.children
        if node.N == 0 && total_N <= 1
            criterion_value = node.V
        else
            criterion_value = node.V + pomcp.solver.c*sqrt(log(total_N)/node.N)
        end
        if criterion_value >= best_criterion_val
            best_criterion_val = criterion_value
            best_node = node
        end
    end
    a = best_node.label

    if length(best_node.children) <= pomcp.solver.k_observation*(best_node.N^pomcp.solver.alpha_observation)
        state_was_generated = true

        # observation progressive widening
        (sp, o, r) = GenerativeModels.generate_sor(pomcp.problem, s, a, pomcp.solver.rng)

        if haskey(best_node.children, o)
            hao = best_node.children[o]
        else
            if isa(pomcp.node_belief_updater, ParticleReinvigorator)
                hao = ObsNode(o, 0, ParticleCollection{S}(), Dict{A,ActNode{A,O,ObsNode{B,A,O}}}())
            else
                new_belief = update(pomcp.node_belief_updater, h.B, a, o) # this relies on h.B not being modified
                hao = ObsNode(o, 0, new_belief, Dict{A,ActNode{A,O,ObsNode{B,A,O}}}())
            end
            best_node.children[o] = hao
        end
        
    else
        state_was_generated = false
        # otherwise sample nodes
        os = collect(values(best_node.children)) # XXX allocation
        wv = WeightVec(Int[node.N for node in os]) # XXX allocation
        hao = sample(pomcp.solver.rng, os, wv)
        sp = rand(pomcp.solver.rng, hao.B)
        r = POMDPs.reward(pomcp.problem, s, a, sp)
    end

    R = r + POMDPs.discount(pomcp.problem)*simulate(pomcp, hao, sp, depth+1)

    if state_was_generated
        if uses_states_from_planner(hao.B)
            push!(hao.B, sp)
        end
        hao.N += 1
    end

    best_node.N += 1
    best_node.V += (R-best_node.V)/best_node.N

    return R
end

"""
Add the N's of two nodes - for use in reduce
"""
add_N(a::ActNode, b::ActNode) = a.N + b.N
add_N(a::Int, b::ActNode) = a + b.N

