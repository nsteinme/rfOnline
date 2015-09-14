

function bestCoords = rfOnline(datFilename, nChans, Fs, mouseName, expNum)
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

% load Protocol
protocolDir = fullfile(zserverDir, 'Data', 'trodes', mouseName, todaysDateStr, num2str(expNum));
d = dir(fullfile(protocolDir, 'Protocol.mat'));



% load synch channel from dat file and detect pulses (assume that should
% use the most recent two)

% synchronize TL and dat


% extract trial times from photodiode


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
   