
% Test script, now for version 2.0
%
% Changes:
%
% - can apply CAR
%
% - generalized mechanism for determining frameTimes and allFrames: user
% supplies a function: 
%    [frameTimes, allFrames] = myFrameFunc(syncT, syncDat, mouseName, thisDate, expNum)
% The function should return frameTimes, a nFrames x 1 vector of the times of
% each frame onset in sec relative to the ephys, and allFrames, an nFrames x nX x nY matrix of the
% screen at each frame. The inputs are syncT and syncDat, the timestamps
% and data of a sync channel, as well as the info to specify which
% experiment data is loaded


addpath(genpath('C:\Users\Nick\Documents\GitHub\rfOnline'));

%%

'C:\DATA\Spikes\20150924_1.dat';

ops.geomFilename = 'forPRBimecToWhisper.mat';

ops.nChans          = 385;
ops.Fs              = 30000;
ops.syncChannelNum  = 385;
ops.mouseName       = 'Whipple';
ops.expNum          = 1;
ops.params          = [.2 .0 .2 ]; % time pre-stimulus,  cortical delay, time on-stimulus
ops.DateStr         = '2015-09-24';
ops.response        = 'mua'; %'lfp, 'mua' or 'thresh', 'lfp' might work best
ops.thresh_sds      = 3; % only used if response=='thresh'; in units of sd of ALL signal
% ops.DateStr = datestr(now, 'yyyy-mm-dd');
ops.sig             = 1; % gaussian smoothing width for RFs
ops.dynamicRFscale  = 1;
ops.tlag            = 0; % time lag in seconds (have not tracked this down yet)
ops.applyCAR        = true;

ops.frameFunc = @frameFuncKT;

% ops.datFilename = fullfile('J:\Whipple\2016-08-19\2', [ops.mouseName '_' ops.DateStr
ops.datFilename = 'J:\Whipple\2016-08-19\2\Whipple_2016-08-19_g2_t0.imec.ap_CAR.bin';

[bestCoords, stats] = rfOnline(ops);

%% try out different STA parameters without reloading all data (fast)
ops.sig             = 1; 
ops.dynamicRFscale  = 1;
ops.tlag            = -.1;
ops.params          = [.2 0 .2]; 

bestCoords  = rfOnline(ops, stats);