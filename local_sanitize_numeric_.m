function x = local_sanitize_numeric_(x)
% 转数值，非数值/Inf 置 NaN
if ~isnumeric(x)
    x = str2double(string(x));
end
x(~isfinite(x)) = NaN;
end