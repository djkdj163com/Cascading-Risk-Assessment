function C = brew__ylorrd(n)
    % ColorBrewer YlOrRd (approx)
    base = [...
        1.0000 1.0000 0.8000
        0.9961 0.8784 0.5647
        0.9922 0.6824 0.3804
        0.9569 0.4275 0.2627
        0.8353 0.1882 0.1843];
    C = interp1(linspace(0,1,size(base,1)), base, linspace(0,1,n));
end