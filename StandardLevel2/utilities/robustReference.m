function [signal, referenceOut] = robustReference(signal, params)

if nargin < 1
    error('robustReference:NotEnoughArguments', 'requires at least 1 argument');
elseif isstruct(signal) && ~isfield(signal, 'data')
    error('robustReference:NoDataField', 'requires a structure data field');
elseif size(signal.data, 3) ~= 1
    error('robustReference:DataNotContinuous', 'signal data must be a 2D array');
elseif size(signal.data, 2) < 2
    error('robustReference:NoData', 'signal data must have multiple points');
elseif ~exist('params', 'var') || isempty(params)
    params = struct();
end
if ~isstruct(params)
    error('robustReference:NoData', 'second argument must be a structure')
end
referenceOut = getReferenceStructure();
referenceOut.referenceChannels = sort(getStructureParameters(params, ...
    'referenceChannels',  1:size(signal.data, 1)));
referenceOut.rereferencedChannels =  sort(getStructureParameters(params, ...
    'rereferencedChannels',  1:size(signal.data, 1)));
referenceOut.channelLocations = getStructureParameters(params, ...
    'channelLocations', signal.chanlocs);
referenceOut.channelInformation = getStructureParameters(params, ...
    'channelInformation', signal.chaninfo);
referenceOut.maxInterpolationIterations = ...
     getStructureParameters(params, 'maxInterpolationIterations', 4);
referenceOut.actualInterpolationIterations = 0;
referenceOut.referenceType = 'robust';

%% Check to make sure that reference channels have locations
chanlocs = referenceOut.channelLocations(referenceOut.referenceChannels);
if ~(length(cell2mat({chanlocs.X})) == length(chanlocs) && ...
     length(cell2mat({chanlocs.Y})) == length(chanlocs) && ...
     length(cell2mat({chanlocs.Z})) == length(chanlocs)) && ...
   ~(length(cell2mat({chanlocs.theta})) == length(chanlocs) && ...
     length(cell2mat({chanlocs.radius})) == length(chanlocs))
   error('robustReference:NoChannelLocations', ...
         'reference channels must have locations');
end

%% Find the noisy channels for the initial starting point
referenceOut.referenceSignalWithNoisyChannels = ...
                nanmean(signal.data(referenceOut.referenceChannels, :), 1);
referenceOut.noisyOutOriginal = findNoisyChannels(signal, params); 

%% Now remove the huber mean and find the channels that are still noisy
unusableChannels = union(...
    referenceOut.noisyOutOriginal.badChannelsFromNaNs, ...
    referenceOut.noisyOutOriginal.badChannelsFromNoData);
referenceChannels = setdiff(referenceOut.referenceChannels, unusableChannels);
signalTmp = removeHuberMean(signal, referenceChannels);
noisyOutHuber = findNoisyChannels(signalTmp, params); 

%% Construct new EEG with interpolated channels to find better average reference
noisyChannels = union(noisyOutHuber.noisyChannels, unusableChannels);
if referenceOut.referenceChannels - length(noisyChannels) < 2
    error('Could not perform a robust reference -- not enough good channels');
elseif ~isempty(noisyChannels) 
    sourceChannels = setdiff(referenceOut.referenceChannels, noisyChannels);
    signalTmp = interpolateChannels(signal, noisyChannels, sourceChannels);
else
    signalTmp = signal;
end
averageReference = mean(signalTmp.data(referenceOut.referenceChannels, :), 1);
signalTmp = removeReference(signal, averageReference, ...
                                 referenceOut.rereferencedChannels);
%% Now remove reference from the signal iteratively interpolate bad channels
noisyChannels = unusableChannels;
badChannelsFromNaNs = [];
badChannelsFromNoData = [];
badChannelsFromHFNoise = [];
badChannelsFromCorrelation = [];
badChannelsFromDeviation = [];
badChannelsFromRansac = [];
badChannelsFromDropOuts = [];
actualIterations = 0;
paramsNew = params;
paramsNew.referenceChannels = setdiff(params.referenceChannels, ...
                                      unusableChannels);
noisyChannelsOld = [];
while true  
    noisyOut = findNoisyChannels(signalTmp, paramsNew);
    if isempty(noisyOut.noisyChannels) || ...
            actualIterations > referenceOut.maxInterpolationIterations || ...
            (isempty(setdiff(noisyOut.noisyChannels, noisyChannelsOld)) ...
            && isempty(setdiff(noisyChannelsOld, noisyOut.noisyChannels)))
        break;
    end
    noisyChannelsOld = noisyOut.noisyChannels;
    noisyChannels = union(noisyOut.noisyChannels, noisyChannels);
    sourceChannels = setdiff(params.referenceChannels, noisyChannels);
    badChannelsFromNaNs = union(badChannelsFromNaNs, ...
          noisyOut.badChannelsFromNaNs);
    badChannelsFromNoData = union(badChannelsFromNoData, ...
          noisyOut.badChannelsFromNoData);
      badChannelsFromHFNoise = union(badChannelsFromHFNoise, ...
          noisyOut.badChannelsFromHFNoise);
      badChannelsFromCorrelation = union(badChannelsFromCorrelation, ...
          noisyOut.badChannelsFromCorrelation);
      badChannelsFromDeviation = union(badChannelsFromDeviation, ...
          noisyOut.badChannelsFromDeviation);
      badChannelsFromRansac = union(badChannelsFromRansac, ...
          noisyOut.badChannelsFromRansac);
      badChannelsFromDropOuts = union(badChannelsFromDropOuts, ...
          noisyOut.badChannelsFromDropOuts);
      if length(sourceChannels)  < 2
          error('robustReference:TooManyBad', ...
              'Could not perform a robust reference -- not enough good channels');
      end
      signalTmp = interpolateChannels(signal, noisyChannels, sourceChannels);
      averageReference = mean(signalTmp.data(referenceOut.referenceChannels, :), 1);
      signalTmp = removeReference(signalTmp, averageReference, ...
                                 referenceOut.rereferencedChannels);
      fprintf('Interpolated channels: %s\n', getListString(noisyChannels));
      actualIterations = actualIterations + 1;
end
signal = signalTmp;

referenceOut.interpolatedChannelsFromNaNs = ...
    union(noisyOut.badChannelsFromNaNs, badChannelsFromNaNs);
referenceOut.interpolatedChannelsFromNoData = ...
    union(noisyOut.badChannelsFromNoData, badChannelsFromNoData);
referenceOut.interpolatedChannelsFromHFNoise = ...
    union(noisyOut.badChannelsFromHFNoise, badChannelsFromHFNoise);
referenceOut.interpolatedChannelsFromCorrelation = ...
    union(noisyOut.badChannelsFromCorrelation, badChannelsFromCorrelation);
referenceOut.interpolatedChannelsFromDeviation = ...
    union(noisyOut.badChannelsFromDeviation, badChannelsFromDeviation);
referenceOut.interpolatedChannelsFromRansac = ...
    union(noisyOut.badChannelsFromRansac, badChannelsFromRansac);
referenceOut.interpolatedChannelsFromDropOuts = noisyOut.badChannelsFromDropOuts;
referenceOut.interpolatedChannels = noisyChannels;
noisyOut = findNoisyChannels(signal, params);
referenceOut.channelsStillBad = noisyOut.noisyChannels;

referenceOut.noisyOut = noisyOut;
referenceOut.referenceSignal = averageReference;
referenceOut.actualInterpolationIterations = actualIterations;

