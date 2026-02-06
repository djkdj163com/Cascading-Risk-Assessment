function share = safeShare_local(topVals, allVals)
    S = sum(allVals(:));
    if S <= 0, share = 0; else, share = sum(topVals(:))/S; end
end