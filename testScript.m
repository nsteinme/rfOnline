
% Test script, now for version 2.0
%
% Changes:
%
% - can apply CAR
%
% - generalized mechanism for determining frameTimes and allFrames: user
% supplies a function: 
%    [frameTimes, allFrames, xcenters, ycenters] = myFrameFunc(syncT, syncDat, mouseName, thisDate, expNum)
% The function should return frameTimes, a nFrames x 1 vector of the times of
% each frame onset in sec relative to the ephys, and allFrames, an nFrames x nX x nY matrix of the
% screen at each frame. The inputs are syncT and syncDat, the timestamps
% and data of a sync channel, as well as the info to specify which
% experiment data is loaded

% todo:
% - update plotting to include time course, optimize for vertical display
% - determine channel averaging better somehow

addpath(genpath('C:\Users\Nick\Documents\GitHub\rfOnline'));

%%

rootDir = 'J:\Whipple\2016-08-19\2\';
cd(rootDir)

% load syncDat first
fn = 'Whipple_2016-08-19_g2_t0.imec.lf.bin';
syncFs = 2500;
d = dir(fn);
nSamp = d.bytes/2/385;
mmf = memmapfile(fn, 'Format', {'int16', [385 nSamp], 'x'});
syncDat = mmf.Data.x(385,:);
syncT = (0:length(syncDat)-1)/syncFs;

%%
ops.geomFilename = fullfile(rootDir, 'forPRBimecP3opt3.mat');

ops.nChans          = 385;
ops.Fs              = 30000;
ops.syncChannelNum  = [];
ops.syncDat         = syncDat;
ops.syncT           = syncT;
ops.mouseName       = 'Whipple';
ops.expNum          = 1;
ops.params          = [.2 .0 .2 ]; % time pre-stimulus,  cortical delay, time on-stimulus
ops.DateStr         = '2016-08-19';
ops.response        = 'thresh'; %'lfp, 'mua' or 'thresh', 'lfp' might work best
ops.thresh_sds      = 3; % only used if response=='thresh'; in units of sd of ALL signal
% ops.DateStr = datestr(now, 'yyyy-mm-dd');
ops.sig             = 1; % gaussian smoothing width for RFs
ops.dynamicRFscale  = 1;
ops.tlag            = 0; % time lag in seconds (have not tracked this down yet)
ops.applyCAR        = false;

ops.frameFunc = @frameFuncKT;

% ops.datFilename = fullfile('J:\Whipple\2016-08-19\2', [ops.mouseName '_' ops.DateStr
ops.datFilename = fullfile(rootDir, 'Whipple_2016-08-19_g2_t0.imec.ap_CAR.bin');

%%
[bestCoords, stats] = rfOnline(ops);

%% try out different STA parameters without reloading all data (fast)
ops.sig             = 1; 
ops.dynamicRFscale  = 0;
ops.tlag            = 0;
ops.params          = [.2 0 .2]; 

bestCoords  = rfOnline(ops, stats);