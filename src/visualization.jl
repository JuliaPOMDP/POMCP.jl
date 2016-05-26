import JSON
import Base: writemime
import MCTS: node_tag, tooltip_tag

type POMCPTreeVisualizer
    node::BeliefNode
end

typealias NodeDict Dict{Int, Dict{UTF8String, Any}}

function create_json(v::POMCPTreeVisualizer)
    complete = false
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
                  "tag"=>node_tag(n),
                  "tt_tag"=>tooltip_tag(n),
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
                  "tag"=>node_tag(n),
                  "tt_tag"=>tooltip_tag(n),
                  "N"=>n.N
                  )
    for (o,c) in n.children
        recursive_push!(nd, c, id)
    end
    return nd
end

# TODO: set to download javascript and css from MCTS repository

function writemime(f::IO, ::MIME"text/html", visualizer::POMCPTreeVisualizer)
    #=
    json, root_id = create_json(visualizer)
    # write("/tmp/tree_dump.json", json)
    css = readall(joinpath(dirname(@__FILE__()), "tree_vis.css"))
    js = readall(joinpath(dirname(@__FILE__()), "tree_vis.js"))
    div = "trevis$(randstring())"

    html_string = """
        <div id="$div">
        <style>
            $css
        </style>
        <script src="http://d3js.org/d3.v3.js"></script>
        <script>
            var treeData = $json;
            var rootID = $root_id;
            var div = "#$div";
            $js
        </script>
        </div>
    """
    =#
    html_string = "visualization doesn't work yet :("

    # for debugging
    # outfile  = open("/tmp/pomcp_debug.html","w")
    # write(outfile,html_string)
    # close(outfile)

    println(f,html_string)
end
