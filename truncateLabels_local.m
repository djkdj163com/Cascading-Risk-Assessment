function out = truncateLabels_local(s, maxLen)
    s = string(s); out = s;
    for i=1:numel(s)
        if strlength(s(i)) > maxLen
            out(i) = extractBetween(s(i), 1, maxLen-1) + "…";
        end
    end
end