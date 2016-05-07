import JSON

type POMCPTreeVisualizer
    node::BeliefNode
end


function create_json(v::POMCPTreeVisualizer)

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
