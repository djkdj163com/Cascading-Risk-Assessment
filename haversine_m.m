function d = haversine_m(lat1, lon1, lat2, lon2)
R = 6371000; 
lat1 = deg2rad(lat1); lon1 = deg2rad(lon1);
lat2 = deg2rad(lat2); lon2 = deg2rad(lon2);
dlat = lat2 - lat1; dlon = lon2 - lon1;
a = sin(dlat/2).^2 + cos(lat1).*cos(lat2).*sin(dlon/2).^2;
d = 2*R*atan2(sqrt(a), sqrt(1-a));
end