# XXX things to possibly speed this up
# replace recursion with while loop
# cache simulation results

function create_policy{S}(solver::Union{POMCPSolver,POMCPDPWSolver}, pomdp::POMDPs.POMDP{S})
    if isa(solver.node_belief_updater, DefaultReinvigoratorStub)
        node_belief_updater = DeadReinvigorator{S}()
    else
        node_belief_updater = solver.node_belief_updater
    end
    return POMCPPlanner(pomdp, solver, node_belief_updater,
                        convert_estimator(solver.estimate_value, solver, pomdp),
                        Nullable{Any}())
end

function action(policy::POMCPPlanner, belief, a=nothing)
    try
        a = search(policy, belief, policy.solver.tree_queries)
    catch ex
        a = default_action(policy.solver.default_action, belief, ex)
    end
    return a
end

"""
    solve(solver::POMCPSolver, pomdp::POMDPs.POMDP)

Simply return a properly constructed POMCPPlanner object.
"""
function solve{S}(solver::Union{POMCPSolver,POMCPDPWSolver}, pomdp::POMDPs.POMDP{S})
    create_policy(solver, pomdp)
end

solve(solver::Union{POMCPSolver,POMCPDPWSolver}, pomdp::POMDPs.POMDP, dummy_policy::Any) = solve(solver, pomdp)

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
    # XXX hack
    pomcp._tree_ref = b
    # end hack

    all_terminal = true
    for i in 1:tree_queries
        s = rand(pomcp.solver.rng, b)
        if !POMDPs.isterminal(pomcp.problem, s)
            simulate(pomcp, b, s, 0)
            b.N += 1
            all_terminal = false
        end
    end

    if all_terminal
        throw(AllSamplesTerminal(b.B))
    end

    best_node = first(values(b.children))
    best_V = best_node.V
    @assert !isnan(best_V)
    for node in collect(values(b.children))[2:end]
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

    sol = pomcp.solver

    if POMDPs.discount(pomcp.problem)^depth < sol.eps ||
            POMDPs.isterminal(pomcp.problem, s) ||
            depth >= sol.max_depth
        return 0
    end
	if isempty(h.children)
        action_space_iter = sparse_actions(pomcp, pomcp.problem, h, sol.num_sparse_actions)
		h.children = Dict{Any,ActNode}()
		for a in action_space_iter
			h.children[a] = ActNode(a,
                                    init_N(sol.init_N, pomcp.problem, h, a),
                                    init_V(sol.init_V, pomcp.problem, h, a),
                                    Dict{O,ObsNode{B,A,O}}())
		end

        if depth > 0 # no need for a rollout if this is the root node
            steps_to_eps = ceil(Int, log(sol.eps)/log(POMDPs.discount(pomcp.problem))-depth)
            steps = min(sol.max_depth-depth, steps_to_eps)
            return POMDPs.discount(pomcp.problem)^depth * estimate_value(pomcp.solved_estimate, pomcp.problem, s, h, steps)
        else
            return 0.
        end
	end

    best_criterion_val = -Inf
    local best_node
    for node in values(h.children)
        if node.N == 0 && h.N == 1
            criterion_value = node.V
        elseif node.N == 0 && node.V == -Inf
            criterion_value = Inf
        else
            criterion_value = node.V + sol.c*sqrt(log(h.N)/node.N)
        end
        if criterion_value >= best_criterion_val
            best_criterion_val = criterion_value
            best_node = node
        end
    end
    a = best_node.label

    (sp, o, r) = GenerativeModels.generate_sor(pomcp.problem, s, a, sol.rng)

    if r == Inf
        warn("POMCP: +Inf reward. This is not recommended and may cause future errors.")
    end

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
    if best_node.V != -Inf
        best_node.V += (R-best_node.V)/best_node.N
    end

    return R
end



function simulate{S,A,O,B}(pomcp::POMCPPlanner{S,A,O,B,POMCPDPWSolver}, h::BeliefNode, s::S, depth)

    sol = pomcp.solver

    if POMDPs.discount(pomcp.problem)^depth < sol.eps ||
            POMDPs.isterminal(pomcp.problem, s) ||
            depth >= sol.max_depth
        return 0
    end

    total_N = reduce(add_N, 0, values(h.children))
    if sol.enable_action_pw
        if length(h.children) <= sol.k_action*total_N^sol.alpha_action
            a = next_action(sol.next_action, pomcp.problem, s, h)
            if !(a in keys(h.children))
                h.children[a] = ActNode(a,
                                        init_N(sol.init_N, pomcp.problem, h, a),
                                        init_V(sol.init_V, pomcp.problem, h, a),
                                        Dict{O,ObsNode{B,A,O}}())
            end
            if length(h.children) <= 1
                if depth > 0
                    return POMDPs.discount(pomcp.problem)^depth * estimate_value(pomcp.solved_estimate, pomcp.problem, s, h, depth)
                else
                    return 0.
                end
            end
        end
    else # run through all the actions
        if isempty(h.children)
            action_space_iter = POMDPs.iterator(POMDPs.actions(pomcp.problem))
            h.children = Dict{Any,ActNode}()
            for a in action_space_iter
                h.children[a] = ActNode(a,
                                        init_N(sol.init_N, pomcp.problem, h, a),
                                        init_V(sol.init_V, pomcp.problem, h, a),
                                        Dict{O,ObsNode{B,A,O}}())
            end

            if depth > 0 # no need for a rollout if this is the root node
                return POMDPs.discount(pomcp.problem)^depth * estimate_value(pomcp.solved_estimate, pomcp.problem, s, h, depth)
            else
                return 0.
            end
        end
        total_N = h.N
    end

    # Calculate UCT
    best_criterion_val = -Inf
    local best_node
    for (a,node) in h.children
        if node.N == 0 && total_N <= 1
            criterion_value = node.V
        elseif node.N == 0 && node.V == -Inf
            criterion_value = Inf
        else
            criterion_value = node.V + sol.c*sqrt(log(total_N)/node.N)
        end
        if criterion_value >= best_criterion_val
            best_criterion_val = criterion_value
            best_node = node
        end
    end
    a = best_node.label

    if length(best_node.children) <= sol.k_observation*(best_node.N^sol.alpha_observation)
        state_was_generated = true

        # observation progressive widening
        (sp, o, r) = GenerativeModels.generate_sor(pomcp.problem, s, a, sol.rng)

        if r == Inf
            warn("POMCP: +Inf reward. This is not recommended and may cause future errors.")
        end


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
        os = values(best_node.children)
        wv = WeightVec(Int[node.N for node in os]) # allocation
        hao = sample(sol.rng, os, wv)
        sp = rand(sol.rng, hao.B)
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
    if best_node.V != -Inf
        best_node.V += (R-best_node.V)/best_node.N
    end

    return R
end

"""
Add the N's of two nodes - for use in reduce
"""
add_N(a::ActNode, b::ActNode) = a.N + b.N
add_N(a::Int, b::ActNode) = a + b.N
