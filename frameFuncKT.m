

function [frameTimes, allFrames, xcenters, ycenters] = frameFuncKT(syncT, syncDat, mouseName, thisDate, expNum)

syncFlips = schmittTimes(syncT, syncDat, [-1.75 -1.25]);

[~, stimPositions, allFrames] = computeSparseNoiseForExp(...
    mouseName, thisDate, expNum, false);

allFrames = permute(allFrames, [3 1 2]);

if numel(syncFlips)>size(allFrames,1)
    % first try dropping the last one from each stimulus
    syncFlips = syncFlips(diff([syncFlips; syncFlips(end)+1])<0.1);
end

if numel(syncFlips)==size(allFrames,1)
    fprintf(1, 'correct number of frames found\n');
else
    fprintf(1, 'sync has %d, stim has %d\n', numel(syncFlips), size(allFrames, 1));
    fprintf(1, 'try to fix the alignment?\n');
    keyboard
end

frameTimes = syncFlips(:);
xcenters = unique(stimPositions{1}(:,2));
ycenters = unique(stimPositions{1}(:,1));
assert(numel(xcenters)==size(allFrames, 3), 'did not find correct xcenters');
assert(numel(ycenters)==size(allFrames, 2), 'did not find correct ycenters');