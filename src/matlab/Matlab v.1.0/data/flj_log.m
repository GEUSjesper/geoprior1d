function J = flj_log
%FLJ    Variant of jet
%   FLJ(M), a variant of jet(M), is a colormap, design by Flemming Jørgensen
%   to be correct, caxis([log10(0.1) log10(2600)])
%
% ILM: 13.02.2013

x_c=[0.1 0.881 1.93 3.61 6.79 10 14.7 19.7  25 29.7 35 39.7 49.4 60 74.1 90 120 150 200 247 300 400 600 1600 2600]';
lg_x_c=log10(x_c);
d_lg_x_c=diff(lg_x_c)/2;
m_lg_x_c=lg_x_c(1:length(x_c)-1)+d_lg_x_c;
m_x_c=10.^(m_lg_x_c);

c_m=[0 0 145
         0 0 180
         0 50 220 
         0 90 245
         0 140 255
         0 190 255
         0 220 255
         1 255 255
         0 255 150
         0 255 1
         150 255 0 
         210 255 0 
         255 255 1
         255 181 0
         255 115 0
         255 0 1
         255 28 141
         255 106 255
         242 0 242
         202 0 202
         166 0 166
         128 0 128
         117 0 117
         100 0 117];
c_m_norm=(c_m+1)./256;

m_x_c_t=[x_c(1);m_x_c;x_c(length(x_c))];
c_m_norm_t=[c_m_norm(1,:);c_m_norm;c_m_norm(length(m_x_c),:)];

m_c_x_i=[10.^(-1:0.01:log10(2600))';2600];
m_c_x_i_n=[0.1:0.1:2600];

J=interp1(m_x_c_t,c_m_norm_t,m_c_x_i);
c_m_norm_i_n=interp1(m_x_c_t,c_m_norm_t,m_c_x_i_n);

