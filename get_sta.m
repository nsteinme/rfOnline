function resp = get_sta(mua, allFrames, frameTimes, newFs, params)

% select time-points where a black or white square comes on
idx = abs(diff(allFrames, 1)) > 0 & abs(allFrames(1:end-1,:,:))<1e-10; 

muaframetimes = ceil(frameTimes * newFs);
%%
tpre  = round(params(1) * newFs);
tpost = round((params(2) + params(3)) * newFs);
dt = -tpre:1:tpost;
sta = zeros(numel(dt), size(mua,2),size(allFrames,2), size(allFrames,3));

for iy = 1:size(allFrames,2)
    for ix = 1:size(allFrames,3)
        ionset = muaframetimes(idx(:,iy, ix));
        indref = repmat(ionset, numel(dt), 1) + repmat(dt', 1, numel(ionset));
        sta(:,:, iy, ix) = mean(reshape(mua(indref, :), [size(indref) size(mua,2)]), 2);
    end
end

% subtract off pre-stimulus baseline (same for all stimuli)
sta = sta - repmat(mean(mean(mean(sta(1:tpre, :, :, :), 1),3),4), ...
    [size(sta,1) 1, size(sta,3), size(sta,4)]);
%%
del = round(params(2) * newFs);
resp = squeeze(mean(sta((tpre + del + 1):size(sta,1), :,:,:), 1));

resp = permute(resp, [2 3 1]);   
end
