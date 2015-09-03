import JSON

function to_dict(tree::ActNode)
    d = Dict()
    d["name"] = "$(string(tree.label))
                 N:$(tree.N)
                 V:$(tree.V)"
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
    d["name"] = string(tree.B)
    d["children"] = [to_dict(child) for child in values(tree.children)]
    return d
end

function to_json_file(tree::BeliefNode, filename="tree.json")
    d = to_dict(tree)
    f = open(filename, "w")
    JSON.print(f,d)
    close(f)
end

function Base.writemime(f::IO, ::MIME"text/html", tree::BeliefNode)
    json = JSON.json(to_dict(tree))
    css = readall("../src/tree_vis.css")
    js = readall("../src/tree_vis.js")

    html_string = """
        <div id="pomcp">
        <style>
            $css
        </style>
        <script src="http://d3js.org/d3.v3.min.js"></script>
        <script>
            var treeData = [$json];
            $js
        </script>
        </div>
    """

    # for debugging
    # outfile  = open("/tmp/pomcp_debug.html","w")
    # write(outfile,html_string)
    # close(outfile)

    println(f,html_string)
end
