close all; clear all; clc; rng(1)
addpath functions data

% ress = [1:1000];
% res_probs = normpdf(ress, 10, 10) + normpdf(ress, 100, 10);

ress = [5 10 50 100];
res_probs = [0 0 1 0];

xs_res=-1:0.01:3.41;

ys_res = interp1(log10(ress), res_probs, xs_res, 'linear', 0);

figure; tiledlayout('TileSpacing', 'compact')
nexttile
res_plot_improved(10.^xs_res, ys_res)
plot(10.^xs_res, ys_res, '-r', 'LineWidth', 1.5)

res_probs_norm = ys_res./sum(ys_res);
res_cumprobs = cumsum(res_probs_norm);

n = 100000;
res_vector = zeros(1,n);

for i = 1:n
    r = rand;
    k = find(res_cumprobs >= r, 1, 'first');
    res_value = 10.^((xs_res(k+1) - xs_res(k))*rand + xs_res(k));
    res_vector(i) = res_value;
end

nexttile
edges = logspace(-1,3.41,200);
histogram(res_vector, edges)
set(gca,'Xscale','log')

%%
% ress = [1:1000];
% res_probs = normpdf(ress, 10, 10) + normpdf(ress, 100, 10);
% 
% xs_res=-1:0.01:3.41;
% 
% ys_res = interp1(log10(ress), res_probs, xs_res, 'linear', 0);
% 
% res_probs_norm = ys_res./sum(ys_res);
% res_cumprobs = cumsum(res_probs_norm);

res_cumprobs = cumsum(res_probs);
res_cumprobs = res_cumprobs./res_cumprobs(end);
ress_log10 = log10(ress);

n = 100000;
res_vector = zeros(1,n);

for i = 1:n
    r = rand;
    k = find(res_cumprobs >= r, 1, 'first');
    res_value = interp1([0 1], ress_log10(k:k+1), r);
    res_vector(i) = 10.^res_value;
    % k = find(res_cumprobs >= r, 1, 'first');
    % res_value = 10.^((ress_log10(k+1) - ress_log10(k))*rand + ress_log10(k));
    % res_vector(i) = res_value;
end

nexttile
edges = logspace(-1,3.41,200);
histogram(res_vector, edges)
set(gca,'Xscale','log')