

function [bestCoords, stats] = rfOnline(ops, varargin)
% Compute a receptive field map online for sparse noise stimuli.
% Uses an estimate of the MUA signal (raw data, high pass filtered) for a
% subset of channels.
% Produces a plot of the RF location for these channels and a suggested
% coordinate to use for the center.

flag_computed = 0;
if ~isempty(varargin)
    stats = varargin{1};
    flag_computed = 1;
end

if isempty(ops.syncChannelNum) && isfield(ops, 'syncDat') && isfield(ops, 'syncT')
    fprintf(1, 'using provided sync data\n');
    syncDat = ops.syncDat;
    syncT = ops.syncT;
    loadSync = false;
else
    loadSync = true;
end


if ~flag_computed
    disp('loading geometry');
    load(ops.geomFilename);
    
    % determine length of file to use
    d = dir(ops.datFilename);
    b = d.bytes;
    sampsToRead = floor(b/ops.nChans/2);
    
  
    %
    % load data
    disp(['starting to load data file: ' ops.datFilename]);
    fid = fopen(ops.datFilename);
    
    fsubsamp = 100;
    Nsamps = ops.Fs * fsubsamp; % this number MUST be a multiple of fsubsamp
    newFs = ops.Fs/fsubsamp;
    
    ichn = chanMap(connected>0);
    ichn = sort(ichn);
    ichn = reshape(ichn , 11, []);
    if loadSync
        syncDat = zeros(1, sampsToRead, 'single');
    end
    
    ik = 0;
    iks = 0;
    while 1
        dat = fread(fid, [ops.nChans Nsamps], '*int16');
        dat = double(dat);
        
        if ~isempty(dat)
            if loadSync
                syncDat(iks + (1:size(dat,2))) = dat(ops.syncChannelNum, :);
            end
            iks = iks + size(dat,2);
            
            if ops.applyCAR
                % Common avg ref
                dat = bsxfun(@minus, dat, median(dat,2)); % subtract median of each channel                
                dat = bsxfun(@minus, dat, median(dat,1)); % subtract median of each time point
            end
            
            % take mean across adjacent N channels
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
    if loadSync
        syncDat((1+iks):end) = [];
        syncT = (0:length(syncDat)-1)/ops.Fs;
    end
    
    disp('finished loading data');
    
    % compute visual stimulus and timing    
    [frameTimesDat, allFrames, xcenters, ycenters] = ops.frameFunc(syncT, syncDat, ops.mouseName, ops.DateStr, ops.expNum);
    
    % all we need to compute RFs is in stats
    stats.frameTimesDat = frameTimesDat;
    stats.newFs         = newFs;
    stats.allFrames     = allFrames;
    stats.mua           = mua;
    stats.xcenters      = xcenters;
    stats.ycenters      = ycenters;
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
xcenters = stats.xcenters(:)'; ycenters = stats.ycenters(:)';
bestCoords = [ycenters(pk(:,1))' xcenters(pk(:,2))'];

   
% end
   
