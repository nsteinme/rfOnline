

function [stimTimes, stimPositions, stimArray] = computeSparseNoiseForExp(mouseName, thisDate, expNum, varargin)
% currently only works for case in which you use just one stimulus, should
% be expanded to do multiple in the correct order...
%
% stimTimes are INDICES of which frame showed the stimulus in
% stimPositions. So you should index your photodiode times with it. 

if ~isempty(varargin)
    excludeLastFrame = varargin{1};
else
    excludeLastFrame = true;
end

load(dat.expFilePath(mouseName, thisDate, expNum, 'parameters', 'master'));
Protocol = parameters.Protocol;
sqsz = Protocol.pars(strcmp(Protocol.parnames, 'sqsz'),1);
x1 =  Protocol.pars(strcmp(Protocol.parnames, 'x1'),1);
y1 =  Protocol.pars(strcmp(Protocol.parnames, 'y1'),1);

load(dat.expFilePath(mouseName, thisDate, expNum, 'hw-info', 'master'));
myScreenInfo.windowPtr = NaN;

stimNum = 1;
ss = eval([Protocol.xfile(1:end-2) '(myScreenInfo, Protocol.pars(:,stimNum));']);

% convert stimulus info to array

if excludeLastFrame
    % excluding the last ImageSequence here as a hack to make the right number of photodiode events (?)
    imTextSeq = ss.ImageTextures(ss.ImageSequence(1:end-1)); 
else
    imTextSeq = ss.ImageTextures(ss.ImageSequence); 
end
q = reshape([imTextSeq{:}], size(ss.ImageTextures{1},1), size(ss.ImageTextures{1},2), []);
stimArray = repmat(q, [1 1 Protocol.nrepeats]); clear q; 

nX = size(stimArray,1);
nY = size(stimArray,2);

xPos = (0:nX-1)*sqsz+y1+sqsz/2;
yPos = (0:nY-1)*sqsz+x1+sqsz/2;

stimArrayZeroPad = cat(3,zeros(size(stimArray,1), size(stimArray,2),1), stimArray);
stimTimes = {[], []};
stimPositions = {[], []};
for x = 1:nX
    for y = 1:nY
        stimEventTimes{x,y,1} = find(stimArrayZeroPad(x,y,1:end-1)==0 & ...
            stimArrayZeroPad(x,y,2:end)==1); % going from grey to white
        stimEventTimes{x,y,2} = find(stimArrayZeroPad(x,y,1:end-1)==0 & ...
            stimArrayZeroPad(x,y,2:end)==-1); % going from grey to black
        stimTimes{1} = [stimTimes{1}; stimEventTimes{x,y,1}];
        stimTimes{2} = [stimTimes{2}; stimEventTimes{x,y,2}];
        
        nEv = length(stimEventTimes{x,y,1});
        stimPositions{1} = [stimPositions{1}; xPos(x)*ones(nEv,1) yPos(y)*ones(nEv,1)];
        nEv = length(stimEventTimes{x,y,2});
        stimPositions{2} = [stimPositions{2}; xPos(x)*ones(nEv,1) yPos(y)*ones(nEv,1)];
    end
end