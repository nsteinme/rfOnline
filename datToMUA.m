
function mua = datToMUA(dat, Fs, newFs)

highPassCutoff = 300; % Hz
D = designfilt('highpassiir', 'FilterOrder', 2, 'PassbandFrequency', highPassCutoff, 'SampleRate', Fs);

filtDat = filtfilt(D, dat);

% smooth over a window twice as wide as the new sampling frequency's period
T = 1/newFs;
smWin = gausswin(round(T*Fs*2))./sum(gausswin(round(T*Fs*2)));

filtDatSm = conv(filtDat, smWin, 'same');

% resample at lower sampling frequency
mua = interp1((0:length(dat)-1)/Fs, filtDatSm, (0:1/newFs:length(dat)/Fs));

