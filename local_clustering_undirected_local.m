% —— 无向图局部聚类系数
function c = local_clustering_undirected_local(G)
    A = adjacency(G) ~= 0; n = numnodes(G); k = full(sum(A,2)); c = zeros(n,1);
    for i=1:n
        ki = k(i); if ki<=1, c(i)=0; continue; end
        nbr = find(A(i,:)); sub = A(nbr,nbr); e = nnz(triu(sub,1));
        c(i) = (2*e)/(ki*(ki-1));
    end
end