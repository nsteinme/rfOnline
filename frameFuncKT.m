

function [frameTimes, allFrames] = frameFuncKT(syncT, syncDat, mouseName, thisDate, expNum)

syncFlips = schmittTimes(syncT, syncDat, [-1.75 -1.25]);

[stimTimeInds, stimPositions, allFrames] = computeSparseNoiseForExp(...
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
    fprintf(1, 'try to fix the alignment?')
    keyboard
end

frameTimes = syncFlips(stimTimeInds);
frameTimes = frameTimes(:);