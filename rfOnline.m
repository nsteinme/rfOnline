

function [bestCoords, stats] = rfOnline(ops, varargin)
% Compute a receptive field map online for sparse noise stimuli.
% Uses an estimate of the MUA signal (raw data, high pass filtered) for a
% subset of channels.
% Produces a plot of the RF location for these channels and a suggested
% coordinate to use for the center.

flag_computed = 0;
if ~isempty(varargin)
    stats = varargin{1};
    Protocol = stats.Protocol;
    flag_computed = 1;
end

if ~flag_computed
    disp('loading geometry');
    load(ops.geomFilename);
    
    % determine length of file to use
    d = dir(ops.datFilename);
    b = d.bytes;
    sampsToRead = floor(b/ops.nChans/2);
    
    
    % load Timeline
    DateStr = ops.DateStr;
    zserverDir = '\\zserver';
    timelineDir = fullfile(zserverDir, 'Data', 'expInfo', ops.mouseName, DateStr, num2str(ops.expNum));
    d = dir(fullfile(timelineDir, '*Timeline.mat'));
    
    if ~isempty(d)
        disp(['loading timeline file: ' d.name])
        load(fullfile(timelineDir, d.name));
    else
        disp(['could not file timeline file in ' timelineDir]);
    end
    timelineSync = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, 'camSync'));
    
    d = dir(fullfile(timelineDir, '*hardwareInfo.mat'));
    if ~isempty(d)
        disp(['loading hardwareInfo file: ' d.name])
        load(fullfile(timelineDir, d.name)); % gives us "myScreenInfo"
    else
        disp(['could not file hardwareInfo file in ' timelineDir]);
    end
    
    
    % load Protocol
    
    DateStr(DateStr =='-') = [];
    
    protocolDir = fullfile(zserverDir, 'Data', 'trodes', ops.mouseName, DateStr, num2str(ops.expNum));
    d = dir(fullfile(protocolDir, 'Protocol.mat'));
    if ~isempty(d)
        load(fullfile(protocolDir, 'Protocol.mat'));
    else
        disp(['could not file protocol file in ' protocolDir]);
    end
    %
    % load data
    disp(['starting to load data file: ' ops.datFilename]);
    fid = fopen(ops.datFilename);
    
    fsubsamp = 100;
    Nsamps = ops.Fs * fsubsamp; % this number MUST be a multiple of fsubsamp
    newFs = ops.Fs/fsubsamp;
    
    ichn = chanMap(connected>0);
    ichn = sort(ichn);
    ichn = reshape(ichn , 10, []);
    syncDat = zeros(1, sampsToRead, 'single');
    
    ik = 0;
    iks = 0;
    while 1
        dat = fread(fid, [ops.nChans Nsamps], '*int16');
        dat = double(dat);
        
        if ~isempty(dat)
            syncDat(iks + (1:size(dat,2))) = dat(ops.syncChannelNum, :);
            iks = iks + size(dat,2);
            
            dat = double(permute(mean(reshape(dat(ichn, :), [size(ichn) size(dat,2)]),1), [3 2 1]));
            dat(fsubsamp * ceil(size(dat,1)/fsubsamp),:) = 0;
            
            switch ops.response
                case 'lfp'
                    mua0 = computeLFP(dat, ops.Fs, fsubsamp);
                case 'mua'
                    mua0 = datToMUA(dat, ops.Fs, fsubsamp);
                case 'thresh'
                    mua0 = threshCross(dat, ops.Fs, fsubsamp, ops.thresh_sds);
            end
            
            if ik==0
                mua = zeros(ceil(sampsToRead/fsubsamp), size(mua0,2));
            end
            mua(ik + (1:size(mua0,1)), :) = mua0;
            ik = ik+size(mua0,1);
        else
            break;
        end
        
        clear dat
    end
    fclose(fid);
    
    mua((1+ik):end, :) = [];
    syncDat((1+iks):end) = [];
    
    disp('finished loading data');
    
    %
    
    % synchronize TL and dat
    disp('attempting to synchronize dat and TL')
    datThresh = -2;
    timelineThresh = 2;
    datSyncSamps = find(syncDat(1:end-1)<datThresh & syncDat(2:end)>=datThresh);
    % datSyncSamps = datSyncSamps(end-1:end); % choose the last two
    %
    datSyncSamps = datSyncSamps((2*ops.expNum-1) + [0 1]);
    datSyncTimes = datSyncSamps/ops.Fs;
    timelineSyncSamps = find(timelineSync(1:end-1)<timelineThresh & timelineSync(2:end)>=timelineThresh);
    timelineSyncTimes = timelineSyncSamps/Timeline.hw.daqSampleRate;
    
    datDur = diff(datSyncTimes);
    tlDur = diff(timelineSyncTimes);
    if abs(datDur-tlDur)>0.03
        disp('dat and TL do not align');
        keyboard
    else
        disp(' sync successful');
    end
    datAlignment = regress(datSyncTimes', [timelineSyncTimes ones(size(timelineSyncTimes))]);
    
    % extract frame times from photodiode
    disp('computing frame times from photodiode');
    pd = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, 'photoDiode'));
    threshUp = 0.2;
    threshDown = 0.1;
    pd(end+1) = pd(end);
    flipTimes = detectPDiodeUpDown(pd, Timeline.hw.daqSampleRate, threshUp, threshDown);
    
    % recreate stimulus traces
    disp('computing stimulus that was shown');
    myScreenInfo.windowPtr = NaN;
    [allFrames, frameTimes] = computeSparseNoiseFrames(Protocol, flipTimes, myScreenInfo);
    frameTimesDat = [frameTimes' ones(size(frameTimes'))]*datAlignment;
    
    frameTimesDat = frameTimesDat';
    
    % all we need to compute RFs is in stats
    stats.frameTimesDat = frameTimesDat;
    stats.newFs         = newFs;
    stats.allFrames     = allFrames;
    stats.mua           = mua;
    stats.Protocol      = Protocol;
end
% compute spike-trig averages + extract magnitude of responses
disp('computing stimulus-triggered MUA signal')
resp = get_sta(stats.mua, stats.allFrames, stats.frameTimesDat, stats.newFs, ops);

% add the mean of all channels as last entry
resp(:,:,end+1) = mean(resp,3);
%
% find peak
disp('finding peaks and plotting');
pk = zeros(size(resp,3), 2);

nrow = ceil(sqrt(size(resp,3)/1.35));
ncol = ceil(size(resp,3)/nrow);

% plot
Mlim = 0;
for i = 1:size(resp,3)
    resp0 = my_conv(my_conv(resp(:,:,i), ops.sig)', ops.sig)';
    [Mmax, xmax]  = max(abs(resp0), [], 2);
    [maxALL, ymax]     = max(abs(Mmax), [], 1);
    Mlim = max(Mlim, maxALL);
end

for i = 1:size(resp,3)
    resp0 = my_conv(my_conv(resp(:,:,i), ops.sig)', ops.sig)';
    [Mmax, xmax]  = max(resp0, [], 2);
    [~, ymax]     = max(Mmax, [], 1);
    xmax = xmax(ymax);
    
    pk(i,1) = ymax;
    pk(i,2) = xmax;
    
    subplot(nrow, ncol, i)
    if ops.dynamicRFscale
        imagesc(resp0)
    else
       imagesc(resp0, [-Mlim Mlim])
    end
    colorbar
    
    xlabel(xmax)
    ylabel(ymax)
    if i==size(resp,3)
       title('mean of all channels') 
    end
end

% compute best coordinates
xcenters = linspace(Protocol.pars(2), Protocol.pars(3), size(resp,2)+1);
xcenters = (xcenters(1:end-1) + xcenters(2:end))/2;
ycenters = linspace(Protocol.pars(5), Protocol.pars(4), size(resp,1)+1);
ycenters = (ycenters(1:end-1) + ycenters(2:end))/2;
bestCoords = [ycenters(pk(:,1))' xcenters(pk(:,2))'];

   
% end
   
