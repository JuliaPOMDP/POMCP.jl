# XXX things to possibly speed this up
# replace recursion with while loop
# cache simulation results

import Debug

import Base.rand!
import POMDPs.update_belief!
import POMDPToolbox

type POMCPPolicy <: POMDPs.Policy
    problem::POMDPs.POMDP
    solver::POMCPSolver
    rng::AbstractRNG
end

# XXX Need to implement ==, hash
type ParticleCollection <: POMDPs.Belief
    particles::Array{Any,1}
end
ParticleCollection() = ParticleCollection({})
function rand!(rng::AbstractRNG, sample, b::ParticleCollection)
    return b.particles[ceil(rand(rng)*length(b.particles))]
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
    return search(policy, belief, policy.solver.timeout)
end

# just return a properly constructed POMCP policy object
# run the code once to ensure that it is properly compiled
function solve(solver::POMCPSolver, pomdp::POMDPs.POMDP)
    policy = POMCPPolicy(pomdp, solver, MersenneTwister(0))
    # XXX is this the right way to encourage precompilation?
    println("running search once to force precompilation...")
    search(policy, ParticleCollection({POMDPs.create_state(pomdp)}), 0.01)
    println("done")
    return policy
end

# Search for the best next move
function search(pomcp::POMCPPolicy, belief::POMDPs.Belief, timeout) 
	finish_time = time() + timeout
	# cache = SimulateCache{S}()
    s = POMDPs.create_state(pomcp.problem)

    #XXX is root_belief right!!?
    root_belief = ParticleCollection()
    root = ObsNode(:root, 0, root_belief, {})
	while time() < finish_time
		rand!(pomcp.rng, s, belief)
		simulate(pomcp, root, deepcopy(s), 0) # cache)
	end
    println("Search complete. Tree queried $(root.N) times")
    best_ind = indmax([action.V for action in root.children])
    return root.children[best_ind].label
end

function simulate(pomcp::POMCPPolicy, h::ObsNode, s, depth) # cache::SimulateCache)

    if POMDPs.discount(pomcp.problem)^depth < pomcp.solver.eps
        return 0
    end
	if length(h.children) == 0
        action_space = POMDPs.actions(pomcp.problem)
        # Debug.@bp
		h.children = Array(Any, length(action_space))
		for i in 1:length(h.children)
			h.children[i] = ActNode(action_space[i],
                                    init_N(pomcp.problem, h, action_space[i]),
                                    init_V(pomcp.problem, h, action_space[i]),
                                    {})
		end

		return rollout(pomcp, s, h, depth)
	end

    best_ind = indmax([action.V + pomcp.solver.c*sqrt(log(h.N)/action.N) for action in h.children])
    a = h.children[best_ind].label

    r = POMDPs.reward(pomcp.problem, s, a)

    obs_dist = POMDPs.create_observation_distribution(pomcp.problem)
    trans_dist = POMDPs.create_transition_distribution(pomcp.problem)
    sp = POMDPs.create_state(pomcp.problem)
    o = POMDPs.create_observation(pomcp.problem)

    POMDPs.transition!(trans_dist, pomcp.problem, s, a)
    rand!(pomcp.rng, sp, trans_dist)

    POMDPs.observation!(obs_dist, pomcp.problem, sp, a)
    rand!(pomcp.rng, o, obs_dist)

    hao = ObsNode(o, 0, ParticleCollection(), {})
    push!(h.children[best_ind].children, hao)

    R = r + POMDPs.discount(pomcp.problem)*simulate(pomcp, hao, sp, depth+1)

    push!(h.B.particles, s)
    h.N += 1

    h.children[best_ind].N += 1
    h.children[best_ind].V += (R-h.children[best_ind].V)/h.children[best_ind].N

    return R
end

function rollout(pomcp::POMCPPolicy, start_state, h::ObsNode, depth)
    b = belief_from_node(pomcp.problem, h)
    r = POMDPs.simulate(pomcp.problem,
                        pomcp.solver.rollout_policy,
                        b,
                        rng=pomcp.solver.rng,
                        eps=pomcp.solver.eps,
                        initial_state=start_state)
    h.N += 1
    return POMDPs.discount(pomcp.problem)^depth * r
end

function init_V(problem::POMDPs.POMDP, h::ObsNode, action)
    return 0.0
end

function init_N(problem::POMDPs.POMDP, h::ObsNode, action)
    return 0
end

function belief_from_node(problem::POMDPs.POMDP, node::ObsNode)
    return POMDPToolbox.EmptyBelief()
end


