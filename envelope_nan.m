function [mn, mx] = envelope_nan(M)
% 行=样本；列=时间点；忽略 NaN
mn = nanmin(M, [], 1);
mx = nanmax(M, [], 1);
end