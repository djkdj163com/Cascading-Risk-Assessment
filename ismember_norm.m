function [tf, loc] = ismember_norm(a, b)
    % 不区分大小写 + 去两端空格的字符串匹配
    a1 = lower(strtrim(string(a)));
    b1 = lower(strtrim(string(b)));
    [tf, loc] = ismember(a1, b1);
end