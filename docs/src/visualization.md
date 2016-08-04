# [Tree Visualization](@id Tree)

Interactive visualization of the MCTS tree is available in Jupyter notebooks. Run the Display Tree notebook in the notebooks folder for a demonstration, or view it here: [http://nbviewer.jupyter.org/github/JuliaPOMDP/POMCP.jl/blob/master/notebooks/Display_Tree.ipynb](http://nbviewer.jupyter.org/github/JuliaPOMDP/POMCP.jl/blob/master/notebooks/Display_Tree.ipynb)

In order to display a tree, create a POMCPTreeVisualizer with any BeliefNode. If the last line of a cell in a Jupyter notebook returns a POMCPTreeVisualizer, the output cell will be populated with html and javascript that display the tree. See the documentation for MCTS.jl for more detailed information about the tree and instructions describing how to customize its appearance. In particular, the `node_tag` and `tooltip_tag` functions can be overridden to customize how actions and observations are displayed.
