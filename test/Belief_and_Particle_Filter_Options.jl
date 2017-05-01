
using POMCP
using POMDPs
using POMDPModels
using POMDPToolbox

problem = BabyPOMDP();
rng = MersenneTwister(1);

solver = POMCPSolver(rng=rng, tree_queries=5)
policy = solve(solver, problem)
up = updater(policy)

# setup
init_dist = initial_state_distribution(problem)
s = rand(rng, init_dist)
first_root_node = initialize_belief(up, init_dist)
typeof(first_root_node)

# plan and execute first action
a = action(policy, first_root_node)
(sp, o, r) = generate_sor(problem, s, a, rng)

# the updater simply chooses the next root node
second_root_node = update(up, first_root_node, a, o)
typeof(second_root_node)

# this new node contains particles representing the belief
second_root_node.B

# at the next step, POMCP uses the new root
action(policy, second_root_node);

# artificially simulate particle depletion
delete!(first_root_node.children[a].children, o)
@test_throws ErrorException update(up, first_root_node, a, o)

type UniformBabyReinvigorator <: ParticleReinvigorator end

function POMCP.reinvigorate!(pc::ParticleCollection,
        r::UniformBabyReinvigorator,
        old_node::BeliefNode, a::Bool, o::Bool)
    push!(pc, true)
    push!(pc, false)
    return pc
end

function POMCP.handle_unseen_observation(r::UniformBabyReinvigorator,
        old_node::BeliefNode, a::Bool, o::Bool)
    return ParticleCollection{Bool}([true, false])
end   

up_with_reinvig = RootUpdater(UniformBabyReinvigorator())
# artificially simulate particle depletion
delete!(first_root_node.children[a].children, o)
update(up_with_reinvig, first_root_node, a, o)

init_dist = initial_state_distribution(problem)
action(policy, init_dist)

get(policy._tree_ref).children[true].children[false].B

solver = POMCPSolver(rng=rng, tree_queries=5,
                     node_belief_updater = VoidUpdater())
policy = solve(solver, problem)
a = action(policy, init_dist)

exact_updater = BabyBeliefUpdater(problem)
(sp, o, r) = generate_sor(problem, s, a, rng)
belief2 = update(exact_updater, init_dist, a, o)
a2 = action(policy, belief2)

solver = POMCPSolver(rng=rng, tree_queries=5,
                     node_belief_updater = exact_updater)
policy = solve(solver, problem)
a = action(policy, init_dist)
get(policy._tree_ref).children[true].children[false].B

POMCP.uses_states_from_planner(::BoolDistribution) = true
Base.push!(::BoolDistribution, s) = println("Received state $s from planner.")

solver = POMCPSolver(rng=rng, tree_queries=5,
                     node_belief_updater = exact_updater)
policy = solve(solver, problem)
a = action(policy, init_dist)
