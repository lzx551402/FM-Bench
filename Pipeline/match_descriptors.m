function [X1, X2] = match_descriptors(f1, f2, d1, d2, method, ratio_val)
%method can be 'r' or 'm' or 'rm'
assert(strcmp(method,'r')|strcmp(method,'m')|strcmp(method,'rm'));

gpu_d1 = gpuArray(d1);
gpu_d2 = gpuArray(d2);
dists = pdist2(gpu_d1, gpu_d2, 'squaredeuclidean');
% Find the first best matches.
idxs1 = gpuArray(single(1:size(d1, 1)));
[first_dists12, idxs12] = min(dists, [], 2);
[~, idxs21] = min(dists, [], 1);
idxs121 = idxs21(idxs12);

% Find the second best matches.
dists(sub2ind(size(dists), idxs1, idxs12')) = single(realmax('single'));
second_dists12 = min(dists, [], 2);

% Compute the distance ratios between the first and second best matches.
dist_ratios12 = sqrt(first_dists12) ./ sqrt(second_dists12);
ratio_mask = dist_ratios12(:) <= ratio_val;
mutual_mask = idxs1(:) == idxs121(:);
if strcmp(method,'r')
    mask = ratio_mask;
elseif strcmp(method,'m')
    maks = mutual_mask;
elseif strcmp(method,'rm')
    mask = ratio_mask & mutual_mask;
end
idxs1 = idxs1(mask);
idxs2 = idxs12(mask);
% Compose the match matrix.
matches = uint32(gather([idxs1', idxs2]));
X1 = f1(matches(:,1),1:2);
X2 = f2(matches(:,2),1:2);
end

