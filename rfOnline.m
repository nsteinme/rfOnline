

function bestCoords = rfOnline(filename)
% Compute a receptive field map online for sparse noise stimuli. 
% Uses an estimate of the MUA signal (raw data, high pass filtered) for a
% subset of channels. 
% Produces a plot of the RF location for these channels and a suggested
% coordinate to use for the center. 


% read file metadata


% load Timeline

% load Protocol


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
   