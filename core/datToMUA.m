
function mua = datToMUA(dat, Fs, fact)

highPassCutoff = 300; % Hz

[b1, a1] = butter(7, highPassCutoff/Fs, 'high');

filtDat = abs(filtfilt(b1,a1, dat));

NT = size(filtDat,1);
mua = permute(mean(reshape(filtDat, fact, NT/fact, []), 1), [2 3 1]);
