cd \\zserver.ioo.ucl.ac.uk\Code\
SetPathCortexLab;

%%
% datFilename = '\\zserver\Data\multichanspikes\Ehrlich\20150707\20150707_1.dat';
% datFilename = '\\zserver\Data\multichanspikes\Ehrlich\20150626\20150626_1.dat';
datFilename = 'J:\data\Ehrlich\20150626\20150626_1.dat';
% datFilename = 'C:\DATA\Spikes\20150707_1.dat';
geomFilename = 'forPRBimecToWhisper.mat';

nChans = 129;
Fs = 25000;
syncChannelNum = 129;
mouseName = 'M150218_NS2EHR';
expNum = 3;
params = [.2 .05 .2 ]; % time pre-stimulus,  cortical delay, time on-stimulus

bestCoords = rfOnline(datFilename, geomFilename, nChans, Fs, syncChannelNum, mouseName, expNum, params);


%%