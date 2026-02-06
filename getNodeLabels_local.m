function labels = getNodeLabels_local(G)
    n = numnodes(G);
    if istable(G.Nodes) && any(strcmpi('Name', G.Nodes.Properties.VariableNames))
        labels = string(G.Nodes.Name);
    else
        labels = string((1:n)');
    end
end
