import JSON

type TreeVisualizer
    node::BeliefNode
end

"""
Return text to display below the node corresponding to action or belief x
"""
node_tag(x) = string(x)

"""
Return text to display in the tooltip for the node corresponding to action or belief x
"""
tooltip_tag(x) = string(x)

function create_json(v::TreeVisualizer)

end

function to_dict(tree::ActNode)
    d = Dict()
    d["name"] = "$(string(tree.label))
                 N:$(tree.N)
                 V:$(@sprintf("%8.2e", tree.V))"
    d["children"] = [to_dict(child) for child in values(tree.children)]
    return d
end

function to_dict(tree::ObsNode)
    d = Dict()
    d["name"] = string(tree.label)
    d["children"] = [to_dict(child) for child in values(tree.children)]
    return d
end

function to_dict(tree::RootNode)
    d = Dict()
    d["name"] = "root" 
    d["children"] = [to_dict(child) for child in values(tree.children)]
    return d
end

function to_json_file(tree::BeliefNode, filename="tree.json")
    d = to_dict(tree)
    f = open(filename, "w")
    JSON.print(f,d)
    close(f)
end

function writemime(f::IO, ::MIME"text/html", visualizer::TreeVisualizer)
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
    # html_string = "visualization doesn't work yet :("

    # for debugging
    # outfile  = open("/tmp/pomcp_debug.html","w")
    # write(outfile,html_string)
    # close(outfile)

    println(f,html_string)
end
