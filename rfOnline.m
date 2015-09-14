

function bestCoords = rfOnline(datFilename, nChans, Fs, syncChannelNum, mouseName, expNum)
% Compute a receptive field map online for sparse noise stimuli. 
% Uses an estimate of the MUA signal (raw data, high pass filtered) for a
% subset of channels. 
% Produces a plot of the RF location for these channels and a suggested
% coordinate to use for the center. 


% determine length of file to use
d = dir(datFilename);
b = dir.Bytes;
sampsToRead = floor(b/nChans/2);


% load Timeline
todaysDateStr = datestr(now, 'yyyy-mm-dd');
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
protocolDir = fullfile(zserverDir, 'Data', 'trodes', mouseName, todaysDateStr, num2str(expNum));
d = dir(fullfile(protocolDir, 'Protocol.mat'));
if ~isempty(d)
    load(fullfile(protocolDir, 'Protocol.mat'));
end


% load synch channel from dat file and detect pulses (assume that should
% use the most recent two)
fid = fopen(filename);
try
    q = fread(fid, (requestedChan-1), 'int16'); % skip over the first samples of the other channels
    syncDat = fread(fid, [1, Inf], 'int16', (numChans-1)*2); % skipping other channels
catch me
    fclose(fid)
    rethrow(me);
end

% synchronize TL and dat
datThresh = 2;
timelineThresh = 2;
datSyncSamps = find(syncDat(1:end-1)<datThresh & syncDat(2:end)>=datThresh);
datSyncSamps = datSyncSamps(end-1:end); % choose the last two
timelineSyncSamps = find(timelineSync(1:end-1)<timelineThresh & timelineSync(2:end)>=timelineThresh);

datDur = diff(datSyncSamps)/Fs;
tlDur = diff(timelineSyncSamps)/Timeline.hw.daqSampleRate;
if abs(datDur-tlDur)>0.01
    disp('dat and TL do not align');
end

% extract frame times from photodiode
pd = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, 'photoDiode'));

% recreate stimulus traces


% load each dat channel to analyze
for ch = 1:numChansToAnalyze
    
    % load data
    dat = readDatLimited(filename, nChans, analyzeChans(ch));
    
    % filter for MUA, smooth, then downsample
    mua = datToMUA(dat, Fs, newFs);
    
    
    % compute spike-trig averages
    
    
    % extract magnitude of responses
    
    
    % find peak
    
    
    % plot
    
end

% plot summary

% compute best coordinates
   