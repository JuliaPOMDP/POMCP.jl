import JSON
import MCTS: AbstractTreeVisualizer, node_tag, tooltip_tag, create_json, blink

type POMCPTreeVisualizer <: AbstractTreeVisualizer
    node::BeliefNode
end

blink(n::BeliefNode) = blink(POMCPTreeVisualizer(n))

typealias NodeDict Dict{Int, Dict{String, Any}}

function create_json(v::POMCPTreeVisualizer)
    node_dict = NodeDict()
    dict = recursive_push!(node_dict, v.node)
    json = JSON.json(node_dict)
    return (json, 1)
end

function recursive_push!(nd::NodeDict, n::BeliefNode, parent_id=-1)
    id = length(nd) + 1
    if parent_id > 0
        push!(nd[parent_id]["children_ids"], id)
    end
    nd[id] = Dict("id"=>id,
                  "type"=>:belief, # maybe this should be :state - it doesn't matter for now
                  "children_ids"=>Array(Int,0),
                  "tag"=>node_tag(n.label),
                  "tt_tag"=>tooltip_tag(n.label),
                  "N"=>n.N
                  )
    for (a,c) in n.children
        recursive_push!(nd, c, id)
    end
    return nd
end

function recursive_push!(nd::NodeDict, n::RootNode, parent_id=-1)
    id = length(nd) + 1
    if parent_id > 0
        push!(nd[parent_id]["children_ids"], id)
    end
    nd[id] = Dict("id"=>id,
                  "type"=>:belief, # maybe this should be :state - it doesn't matter for now
                  "children_ids"=>Array(Int,0),
                  "tag"=>node_tag(n.B),
                  "tt_tag"=>tooltip_tag(n.B),
                  "N"=>n.N
                  )
    for (a,c) in n.children
        recursive_push!(nd, c, id)
    end
    return nd
end

function recursive_push!(nd::NodeDict, n::ActNode, parent_id=-1)
    id = length(nd) + 1
    if parent_id > 0
        push!(nd[parent_id]["children_ids"], id)
    end
    nd[id] = Dict("id"=>id,
                  "type"=>:action,
                  "children_ids"=>Array(Int,0),
                  "tag"=>node_tag(n.label),
                  "tt_tag"=>tooltip_tag(n.label),
                  "N"=>n.N,
                  "Q"=>n.V
                  )
    for (o,c) in n.children
        recursive_push!(nd, c, id)
    end
    return nd
end
