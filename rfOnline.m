

function bestCoords = rfOnline(datFilename, nChans, Fs, syncChannelNum, mouseName, expNum)
% Compute a receptive field map online for sparse noise stimuli. 
% Uses an estimate of the MUA signal (raw data, high pass filtered) for a
% subset of channels. 
% Produces a plot of the RF location for these channels and a suggested
% coordinate to use for the center. 

analyzeChans = [2 3 4];


% determine length of file to use
d = dir(datFilename);
b = d.bytes;
sampsToRead = floor(b/nChans/2);


% load Timeline
todaysDateStr = datestr(now, 'yyyy-mm-dd');
todaysDateStr = '2015-07-07';
zserverDir = '\\zserver';
timelineDir = fullfile(zserverDir, 'Data', 'expInfo', mouseName, todaysDateStr, num2str(expNum));
d = dir(fullfile(timelineDir, '*Timeline.mat'));
if ~isempty(d)
    load(fullfile(timelineDir, d.name));
end
timelineSync = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, 'camSync'));

d = dir(fullfile(timelineDir, '*hardwareInfo.mat'));
if ~isempty(d)
    load(fullfile(timelineDir, d.name)); % gives us "myScreenInfo"
end


% load Protocol
todaysDateStr = datestr(now, 'yyyymmdd');
todaysDateStr = '20150707';
protocolDir = fullfile(zserverDir, 'Data', 'trodes', mouseName, todaysDateStr, num2str(expNum));
d = dir(fullfile(protocolDir, 'Protocol.mat'));
if ~isempty(d)
    load(fullfile(protocolDir, 'Protocol.mat'));
end


% load synch channel from dat file and detect pulses (assume that should
% use the most recent two)
fid = fopen(datFilename);
try
    q = fread(fid, (syncChannelNum-1), 'int16'); % skip over the first samples of the other channels
    syncDat = fread(fid, [1, sampsToRead], 'int16', (nChans-1)*2); % skipping other channels
    fclose(fid);
catch me
    fclose(fid)
    rethrow(me);
end

% synchronize TL and dat
datThresh = -2;
timelineThresh = 2;
datSyncSamps = find(syncDat(1:end-1)<datThresh & syncDat(2:end)>=datThresh);
% datSyncSamps = datSyncSamps(end-1:end); % choose the last two
datSyncSamps = datSyncSamps([5 6]);
datSyncTimes = datSyncSamps/Fs;
timelineSyncSamps = find(timelineSync(1:end-1)<timelineThresh & timelineSync(2:end)>=timelineThresh);
timelineSyncTimes = timelineSyncSamps/Timeline.hw.daqSampleRate;

datDur = diff(datSyncTimes);
tlDur = diff(timelineSyncTimes);
if abs(datDur-tlDur)>0.01
    disp('dat and TL do not align');
end
datAlignment = regress(datSyncTimes', [timelineSyncTimes ones(size(timelineSyncTimes))]);

% extract frame times from photodiode
pd = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, 'photoDiode'));
threshUp = 0.2;
threshDown = 0.1;
flipTimes = detectPDiodeUpDown(pd, Timeline.hw.daqSampleRate, threshUp, threshDown);

% recreate stimulus traces
myScreenInfo.windowPtr = NaN;
[allFrames, frameTimes] = computeSparseNoiseFrames(Protocol, flipTimes, myScreenInfo);
frameTimesDat = [frameTimes ones(size(frameTimes))]*datAlignment;

% load each dat channel to analyze
numChansToAnalyze = length(analyzeChans);
for ch = 1:numChansToAnalyze
    
    % load data
    fid = fopen(datFilename);
    try
        q = fread(fid, (analyzeChans(ch)-1), 'int16'); % skip over the first samples of the other channels
        dat = fread(fid, [1, sampsToRead], 'int16', (nChans-1)*2); % skipping other channels
        fclose(fid);
    catch me
        fclose(fid)
        rethrow(me);
    end
    
    % filter for MUA, smooth, then downsample
    mua = datToMUA(dat, Fs, newFs);
    
    
    % compute spike-trig averages
    
    
    % extract magnitude of responses
    
    
    % find peak
    
    
    % plot
    
end

% plot summary

% compute best coordinates
   bestCoords = [];