
function mua = threshCross(dat, Fs, fact, thresh_sds)
%%
filtDat = dat;

highPassCutoff = 300; % Hz
[b1, a1] = butter(5, highPassCutoff/Fs, 'high');
filtDat = filtfilt(b1,a1, filtDat);

filtDat = zscore(filtDat, [], 1);
filtDat = single(filtDat<-thresh_sds);

% lowPassCutoff = 100; % Hz
% [b1, a1] = butter(5, lowPassCutoff/Fs, 'low');
% filtDat = filtfilt(b1,a1, filtDat);



NT = size(filtDat,1);
mua = permute(mean(reshape(filtDat, fact, NT/fact, []), 1), [2 3 1]);
%%
% keyboard;