function fill_band(t, ylo, yhi, rgb, alpha_)
% 画半透明分位带
t = t(:)'; ylo = ylo(:)'; yhi = yhi(:)';
X = [t, fliplr(t)];
Y = [ylo, fliplr(yhi)];
p = patch('XData',X,'YData',Y,'FaceColor',rgb,'EdgeColor','none');
p.FaceAlpha = alpha_;
end