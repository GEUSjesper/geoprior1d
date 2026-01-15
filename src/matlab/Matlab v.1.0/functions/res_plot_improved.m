function res_plot_improved(x,y)
% This function makes colored resistivity plots
%
% x is the resistivity values
% y is counts, probability or similar
%
% JN, 11/10-2024

xs = logspace(log10(0.1),log10(2600),444);
xs_center = zeros(1,443);
for i = 1:443
    xs_center(i) = sqrt(xs(i)*xs(i+1));
end
ys = interp1(x,y,xs_center,'linear',0);


X = zeros(4,443);
Y = zeros(4,443);


for i = 1:443
    X(:,i) = [xs(i); xs(i); xs(i+1); xs(i+1)];
    Y(:,i) = [0; ys(i); ys(i); 0];
end

   
patch(X,Y,xs_center,'EdgeColor','none')
hold on
plot(x,y,'-k')
set(gca,'Colormap',flj_log)
set(gca,'Clim',[0.1 2600])
set(gca,'ColorScale','log')
set(gca,'Xscale','log')
set(gca,'Layer', 'top')

