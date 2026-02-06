function y = sanitize_numeric(x)
    if isnumeric(x)
        y = double(x);
    elseif isstring(x)
        y = str2double(x);
    elseif iscell(x)
        try, y = cellfun(@str2double, x);
        catch, y = str2double(string(x)); end
    elseif iscategorical(x)
        y = str2double(string(x));
    elseif ischar(x)
        y = str2double(string(x));
    else
        try, y = double(x);
        catch, y = str2double(string(x)); end
    end
    y(~isfinite(y)) = NaN;
    y = y(:);
end