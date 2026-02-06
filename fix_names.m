function T = fix_names(T)
    T.Properties.VariableNames = matlab.lang.makeUniqueStrings(strtrim(T.Properties.VariableNames));
end

function nm = normkey(s)
    nm = lower(regexprep(s, '[^a-zA-Z0-9]', ''));
end