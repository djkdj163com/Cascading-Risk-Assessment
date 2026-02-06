%% ================= helper functions =================
function T = fix_names_case_insensitive(T)
    % 去除列名首尾空格并强制唯一
    vn = T.Properties.VariableNames;
    vn = regexprep(vn,'^\s+|\s+$','');             % trim
    T.Properties.VariableNames = matlab.lang.makeUniqueStrings(vn);
end