solver = POMCPSolver(rollout_solver=FeedWhenCrying(),
                    eps=0.01,
                    c=10.0,
                    tree_queries=50, 
                    rng=MersenneTwister(2))

problem = BabyPOMDP()
policy = solve(solver, problem)
up = updater(policy)
belief = initialize_belief(up, initial_state_distribution(problem))
action(policy, belief)

dummy = IOBuffer()
show(dummy, MIME("text/html"), POMCPTreeVisualizer(belief))
