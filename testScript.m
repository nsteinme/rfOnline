cd \\zserver.ioo.ucl.ac.uk\Code\
SetPathCortexLab;

%%
% datFilename = '\\zserver\Data\multichanspikes\Ehrlich\20150707\20150707_1.dat';
% datFilename = '\\zserver\Data\multichanspikes\Ehrlich\20150626\20150626_1.dat';
% datFilename = 'J:\data\Ehrlich\20150626\20150626_1.dat';
ops.datFilename = 'C:\DATA\Spikes\20150924_1.dat';

% datFilename = 'C:\DATA\Spikes\20150707_1.dat';
ops.geomFilename = 'forPRBimecToWhisper.mat';

ops.nChans          = 129;
ops.Fs              = 25000;
ops.syncChannelNum  = 129;
ops.mouseName       = 'M150820_NS1WAR';
ops.expNum          = 1;
ops.params          = [.2 .0 .2 ]; % time pre-stimulus,  cortical delay, time on-stimulus
ops.DateStr         = '2015-09-24';
ops.response        = 'lfp'; %'lfp, 'mua' or 'thresh', 'lfp' might work best
ops.thresh_sds      = 3; % only used if response=='thresh'; in units of sd of ALL signal
% ops.DateStr = datestr(now, 'yyyy-mm-dd');
ops.sig             = 1; % gaussian smoothing width for RFs
ops.dynamicRFscale  = 1;
ops.tlag            = -.1; % time lag in seconds (have not tracked this down yet)

[bestCoords, stats] = rfOnline(datFilename, ops);

%% try out different STA parameters without reloading all data (fast)
ops.sig             = 1; 
ops.dynamicRFscale  = 1;
ops.tlag            = -.1;
ops.params          = [.2 0 .2]; 

bestCoords  = rfOnline(ops, stats);