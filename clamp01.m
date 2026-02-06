function y = clamp01(x)
x = double(x);
x(~isfinite(x)) = NaN;
y = min(max(x,0),1);
y(isnan(y)) = 0;
end