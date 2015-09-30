
function [allFrames, frameTimes] = computeSparseNoiseFrames(Protocol, photodiodeFlips, myScreenInfo)
ftInd = 1;
pdTimeInd = 1;

for stim = 1:numel(Protocol.seqnums)
    
    [stimNum, repetitionNum] = find(Protocol.seqnums==stim);
    
    %ss = stimSparseNoise(myScreenInfo, Protocol.pars(:,stimNum));
    ss = eval([Protocol.xfile(1:end-2) '(myScreenInfo, Protocol.pars(:,stimNum));']);
    
    if stim==1
        allFrames = zeros(length(photodiodeFlips)+numel(Protocol.seqnums), size(ss.ImageTextures{1},1), size(ss.ImageTextures{1},2));
        
        % every timeOn corresponds to a frame. However, a timeOff could
        % have a frame following or possibly not, if it is the last frame
        % of the stimulus.
        frameTimes = zeros(1, length(photodiodeFlips)+numel(Protocol.seqnums));
    end
    
%     disp([' stim ' num2str(stim)]);
%     disp(['   first frame starts ' num2str(photodiodeFlips(pdTimeInd))]);
    for img = 1:length(ss.ImageSequence)
        allFrames(ftInd, :, :) = ss.ImageTextures{ss.ImageSequence(img)};
        frameTimes(ftInd) = photodiodeFlips(pdTimeInd);
        ftInd = ftInd+1;
        pdTimeInd = pdTimeInd+1;
    end
%     disp(['   last frame starts ' num2str(photodiodeFlips(pdTimeInd))]);
    
    % now add the "turn off stimulus" event

    allFrames(ftInd,:,:) = zeros(size(ss.ImageTextures{1}));
    frameTimes(ftInd) = photodiodeFlips(pdTimeInd);
    ftInd = ftInd+1;
    pdTimeInd = pdTimeInd+1;

    missedfs = 0;
    while pdTimeInd<length(photodiodeFlips) && diff(photodiodeFlips(pdTimeInd-1:pdTimeInd)) < 1
        % whoops, there must have been a missed frame because this gap
        % should be something like 3 seconds
        missedfs = missedfs + 1;
        pdTimeInd = pdTimeInd-1;
    end
    fprintf('%d missed frame(s) around %2.2f \n', missedfs, photodiodeFlips(pdTimeInd));
end

allFrames = allFrames(frameTimes>0,:,:);
frameTimes = frameTimes(frameTimes>0);
