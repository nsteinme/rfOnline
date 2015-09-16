

function bestCoords = rfOnline(datFilename, geomFilename, nChans, Fs, syncChannelNum, mouseName, expNum, params)
% Compute a receptive field map online for sparse noise stimuli. 
% Uses an estimate of the MUA signal (raw data, high pass filtered) for a
% subset of channels. 
% Produces a plot of the RF location for these channels and a suggested
% coordinate to use for the center. 

disp('loading geometry');
load(geomFilename);

% determine length of file to use
d = dir(datFilename);
b = d.bytes;
sampsToRead = floor(b/nChans/2);


% load Timeline
todaysDateStr = datestr(now, 'yyyy-mm-dd');
todaysDateStr = '2015-06-26';
zserverDir = '\\zserver';
timelineDir = fullfile(zserverDir, 'Data', 'expInfo', mouseName, todaysDateStr, num2str(expNum));
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
todaysDateStr = datestr(now, 'yyyymmdd');
todaysDateStr = '20150626';
protocolDir = fullfile(zserverDir, 'Data', 'trodes', mouseName, todaysDateStr, num2str(expNum));
d = dir(fullfile(protocolDir, 'Protocol.mat'));
if ~isempty(d)
    load(fullfile(protocolDir, 'Protocol.mat'));
end
%

% load data
disp(['starting to load data file: ' datFilename]);
fid = fopen(datFilename);

Nsamps = Fs * 100; % this number MUST be a multiple of fsubsamp
fsubsamp = 100;
newFs = Fs/fsubsamp;

ichn = chanMap(connected>0);
ichn = sort(ichn);
ichn = reshape(ichn , 10, []);
syncDat = zeros(1, sampsToRead, 'single');

ik = 0;
iks = 0;
while 1
    dat = fread(fid, [nChans Nsamps], '*int16');
    dat = double(dat);    
   
    if ~isempty(dat)
        syncDat(iks + (1:size(dat,2))) = dat(syncChannelNum, :);
         iks = iks + size(dat,2);
         
        dat = double(permute(mean(reshape(dat(ichn, :), [size(ichn) size(dat,2)]),1), [3 2 1]));
        dat(fsubsamp * ceil(size(dat,1)/fsubsamp),:) = 0;
        mua0 = datToMUA(dat, Fs, fsubsamp);
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

datSyncSamps = datSyncSamps([5 6]);
datSyncTimes = datSyncSamps/Fs;
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
flipTimes = detectPDiodeUpDown(pd, Timeline.hw.daqSampleRate, threshUp, threshDown);

% recreate stimulus traces
disp('computing stimulus that was shown');
myScreenInfo.windowPtr = NaN;
[allFrames, frameTimes] = computeSparseNoiseFrames(Protocol, flipTimes, myScreenInfo);
frameTimesDat = [frameTimes' ones(size(frameTimes'))]*datAlignment;

frameTimesDat = frameTimesDat';

% compute spike-trig averages + extract magnitude of responses
disp('computing stimulus-triggered MUA signal')
resp = get_sta(mua, allFrames, frameTimesDat, newFs, params);

% add the mean of all channels as last entry
resp(:,:,end+1) = mean(resp,3);
%
% find peak
disp('finding peaks and plotting');
pk = zeros(size(resp,3), 2);

nrow = ceil(sqrt(size(resp,3)/1.35));
ncol = ceil(size(resp,3)/nrow);

% plot
for i = 1:size(resp,3)
    resp0 = my_conv(my_conv(resp(:,:,i), 1)', 1)';
    [Mmax, xmax]  = max(resp0, [], 2);
    [~, ymax]     = max(Mmax, [], 1);
    xmax = xmax(ymax);
    
    pk(i,1) = ymax;
    pk(i,2) = xmax;
    
    subplot(nrow, ncol, i)
    imagesc(resp0)
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


   
end
   
