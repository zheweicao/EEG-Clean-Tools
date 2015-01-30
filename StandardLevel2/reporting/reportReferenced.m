function summary = reportReferenced(fid, noiseDetection, numbersPerRow, indent)
%% Extracts and outputs parameters for referencing calculation
% Outputs a summary to file fid and returns a cell array of important messages
    summary = {};
    if ~isempty(noiseDetection.errors.reference)
        summary{end+1} =  noiseDetection.errors.reference;
        fprintf(fid, '%s\n', summary{end});
    end
    if ~isfield(noiseDetection, 'reference')
        summary{end+1} = 'Signal wasn''t referenced';
        fprintf(fid, '%s\n', summary{end});
        return;
    end
    reference = noiseDetection.reference;
    fprintf(fid, 'Rereferencing version %s\n',  ...
        noiseDetection.version.Reference);
    fprintf(fid, 'Sampling rate: %g Hz\n', reference.noisyOut.srate);

    fprintf(fid, 'Noisy channel detection parameters:\n');
    fprintf(fid, '%sRobust deviation threshold (z score): %g\n', ...
        indent, reference.noisyOut.robustDeviationThreshold);
    fprintf(fid, '%sHigh frequency noise threshold (ratio): %g\n', ...
        indent, reference.noisyOut.highFrequencyNoiseThreshold);
    fprintf(fid, '%sCorrelation window size (in seconds): %g\n', ...
        indent, reference.noisyOut.correlationWindowSeconds);
    fprintf(fid, '%sCorrelation threshold (with any channel): %g\n', ...
        indent, reference.noisyOut.correlationThreshold);
    fprintf(fid, '%sBad correlation threshold: %g\n', ...
        indent, reference.noisyOut.badTimeThreshold);
    fprintf(fid, '%s%s(fraction of time with low correlation or dropout)\n', ...
        indent, indent);
    fprintf(fid, '%sRansac sample size : %g\n', ...
        indent, reference.noisyOut.ransacSampleSize);
    fprintf(fid, '%s%s(number channels to use for interpolated estimate)\n', ...
        indent, indent);
    fprintf(fid, '%sRansac channel fraction (for ransac sample size): %g\n', ...
        indent, reference.noisyOut.ransacChannelFraction);
    fprintf(fid, '%sRansacCorrelationThreshold: %g\n', ...
        indent, reference.noisyOut.ransacCorrelationThreshold);
    fprintf(fid, '%sRansacUnbrokenTime (input parameter): %g\n', ...
        indent, reference.noisyOut.ransacUnbrokenTime);
    fprintf(fid, '%sRansacWindowSeconds (in seconds): %g\n', ...
        indent, reference.noisyOut.ransacWindowSeconds);
    fprintf(fid, '%sRansacPerformed: %g\n', indent, ...
        reference.noisyOut.ransacPerformed);
    fprintf(fid, '%sMaxInterpolationIterations: %g\n', indent, ...
        getFieldIfExists(reference, 'maxInterpolationIterations'));
    fprintf(fid, '%sActualInterpolationIterations: %g\n', indent, ...
          getFieldIfExists(reference, 'actualInterpolationIterations'));
    fprintf(fid, '\nReference channels (%d channels):\n', ...
        length(reference.referenceChannels));
    printList(fid, reference.referenceChannels, ...
        numbersPerRow, indent);
    fprintf(fid, '\nRereferencedChannels (%d channels):\n', ...
        length(reference.rereferencedChannels));
    printList(fid, reference.rereferencedChannels,  ...
        numbersPerRow, indent);
    fprintf(fid, '\nSpecific reference channels (%d channels):\n', ...
        length(reference.specificReferenceChannels));
    printList(fid, reference.specificReferenceChannels, ...
        numbersPerRow, indent);
    
    %% Listing of noisy channels
    outOriginal = reference.noisyOutOriginal;
    outFinal = reference.noisyOut;
    channelLabels = {reference.channelLocations.labels};
    
    badList = getLabeledList(outOriginal.noisyChannels,  ...
        channelLabels(outOriginal.noisyChannels), numbersPerRow, indent);
    fprintf(fid, '\n\nNoisy channels before referencing:\n %s', badList);
    badList = getLabeledList(reference.interpolatedChannels, ...
        channelLabels(reference.interpolatedChannels), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\nNoisy channels interpolated after robust referencing:\n %s', ...
        badList);
    summary{end+1} = ['Interpolated channels: ' badList];
    
   
    badList = getLabeledList(outFinal.noisyChannels, ...
        channelLabels(outFinal.noisyChannels), numbersPerRow, indent);
    fprintf(fid, '\nNoisy channels after robust referencing:\n%s', ...
         badList);
    summary{end+1} = ['Potential noisy channels remaining: ' badList];
          
    if ~isempty(reference.channelsStillBad)  
        badList = getLabeledList(reference.channelsStillBad, ...
           channelLabels(reference.channelsStillBad), ...
           numbersPerRow, indent);
       fprintf(fid, ...
           '\nRemaining bad channels that haven''t been interpolated:\n%s', ...
           badList);
        summary{end+1} = ...
            ['Remaining bad channels that haven''t been interpolated:', ...
            badList];
    end
    
    %% NaN criteria
    if isfield(outOriginal, 'badChannelsFromNaNs')   % temporary
        badList = getLabeledList(outOriginal.badChannelsFromNaNs, ...
            channelLabels(outOriginal.badChannelsFromNaNs), ...
            numbersPerRow, indent);
        fprintf(fid, '\n\nBad because of NaN (original):\n%s', badList);
        
        badList = getLabeledList(reference.interpolatedChannelsFromNaNs, ...
            channelLabels(reference.interpolatedChannelsFromNaNs), ...
            numbersPerRow, indent);
        fprintf(fid, '\n\nInterpolated because of NaN (referenced):\n%s', badList);
  
        badList = getLabeledList(outFinal.badChannelsFromNaNs, ...
            channelLabels(outFinal.badChannelsFromNaNs), ...
            numbersPerRow, indent);
        fprintf(fid, ...
            '\nStill bad because of NaN (after referencing):\n%s', badList');
        if ~isempty(outFinal.badChannelsFromNaNs)
            summary{end+1} = ...
                ['Still bad because of NaN (after referencing): ' badList];
        end
    end
    %% All constant criteria
    if isfield(outOriginal, 'badChannelsFromNaNs')   % temporary      
        badList = getLabeledList(outOriginal.badChannelsFromNoData, ...
            channelLabels(outOriginal.badChannelsFromNoData), ...
            numbersPerRow, indent);
        fprintf(fid, '\n\nBad because data is constant (original):\n%s',...
            badList);
        
        badList = getLabeledList(reference.interpolatedChannelsFromNoData, ...
            channelLabels(reference.interpolatedChannelsFromNoData), ...
            numbersPerRow, indent);
        fprintf(fid, '\n\nInterpolated because data is constant (referenced):\n%s',...
            badList);
        
        badList = getLabeledList(outFinal.badChannelsFromNoData, ...
            channelLabels(outFinal.badChannelsFromNoData), ...
            numbersPerRow, indent);
        fprintf(fid, ...
            '\nStill bad because because data is constant (after referencing):\n%s', ...
            badList);
        if ~isempty(outFinal.badChannelsFromNoData)
            summary{end+1} = ...
                ['Still bad because because data is constant (after referencing): ' badList];
        end
    end
    %% Dropout criteria
    if isfield(outOriginal, 'badChannelsFromDropOuts')   % temporary    
        badList = getLabeledList(outOriginal.badChannelsFromDropOuts, ...
            channelLabels(outOriginal.badChannelsFromDropOuts), ...
            numbersPerRow, indent);
        fprintf(fid, ...
            '\n\nBad because of drop outs (original):\n%s', badList);  
        
        badList = getLabeledList(reference.interpolatedChannelsFromDropOuts, ...
            channelLabels(reference.interpolatedChannelsFromDropOuts), ...
            numbersPerRow, indent);
        fprintf(fid, ...
            '\n\nInterpolated because of drop outs (referenced):\n%s', badList);       
        
        badList = getLabeledList(outFinal.badChannelsFromDropOuts, ...
            channelLabels(outFinal.badChannelsFromDropOuts), ...
            numbersPerRow, indent);
        fprintf(fid, ...
            '\nStill bad because of drop outs (after referencing):\n%s', badList);
        if ~isempty(outFinal.badChannelsFromDropOuts)
            summary{end+1} = ...
                ['Still bad because of drop outs (after referencing): ' badList];
        end
    end
    %% Maximum correlation criterion
    badList = getLabeledList(outOriginal.badChannelsFromCorrelation, ...
        channelLabels(outOriginal.badChannelsFromCorrelation), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\n\nBad because of poor max correlation(original):\n%s', badList);
    
    badList = getLabeledList(reference.interpolatedChannelsFromCorrelation, ...
        channelLabels(reference.interpolatedChannelsFromCorrelation), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\n\nInterpolated because of bad poor max correlation (referenced):\n%s', badList);
    
    badList = getLabeledList(outFinal.badChannelsFromCorrelation, ...
        channelLabels(outFinal.badChannelsFromCorrelation), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\nStill bad because of poor max correlation (after referencing):\n%s', badList);
    if ~isempty(outFinal.badChannelsFromCorrelation)
        summary{end+1} = ...
            ['Still bad because of poor max correlation (after referencing): ' badList];
    end
    %% Large deviation criterion
    badList = getLabeledList(outOriginal.badChannelsFromDeviation, ...
        channelLabels(outOriginal.badChannelsFromDeviation), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\n\nBad because of large deviation (original):\n%s', badList);
    
   badList = getLabeledList(reference.interpolatedChannelsFromDeviation, ...
        channelLabels(reference.interpolatedChannelsFromDeviation), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\n\nInterpolated because of large deviation (referenced):\n%s', badList);
    badList = getLabeledList(outFinal.badChannelsFromDeviation, ...
        channelLabels(outFinal.badChannelsFromDeviation), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\n\nStill bad because of large deviation criteria (referenced):\n%s', badList);
    if ~isempty(outFinal.badChannelsFromDeviation)
        summary{end+1} = ...
            ['Still bad because of large deviation criteria (referenced): ' badList];
    end
    %% HF SNR ratio criterion
    badList = getLabeledList(outOriginal.badChannelsFromHFNoise, ...
        channelLabels(outOriginal.badChannelsFromHFNoise), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\n\nBad because of HF noise (low SNR)(original):\n%s', badList);
    
    badList = getLabeledList(reference.interpolatedChannelsFromHFNoise, ...
        channelLabels(reference.interpolatedChannelsFromHFNoise), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\n\nBad because of HF noise (low SNR)(referenced):\n%s', badList);
    
    badList = getLabeledList(outFinal.badChannelsFromHFNoise, ...
        channelLabels(outFinal.badChannelsFromHFNoise), ...
        numbersPerRow, indent);
    fprintf(fid, ...
        '\nStill bad because of HF noise (low SNR) criteria (after referencing):\n%s', badList);
    if ~isempty(outFinal.badChannelsFromHFNoise)
        summary{end+1} = ...
            ['Still bad because of HF noise (low SNR) criteria (after referencing): ' badList];
    end
      
    %% Ransac criteria
    badList = getLabeledList(outOriginal.badChannelsFromRansac, ...
        channelLabels(outOriginal.badChannelsFromRansac), ...
        numbersPerRow, indent);
    fprintf(fid, '\n\nBad because of poor Ransac predictability (original):\n%s', badList);
    
    badList = getLabeledList(reference.interpolatedChannelsFromRansac, ...
        channelLabels(reference.interpolatedChannelsFromRansac), ...
        numbersPerRow, indent);
    fprintf(fid, '\n\nBad because of poor Ransac predictability (referenced):\n%s', badList);
  
    badList = getLabeledList(outFinal.badChannelsFromRansac, ...
        channelLabels(outFinal.badChannelsFromRansac), ...
        numbersPerRow, indent);
    fprintf(fid, '\nStill bad because of poor Ransac predictability (after referencing):\n%s', badList);

    if ~isempty(outFinal.badChannelsFromRansac)
        summary{end+1} = ...
            ['Still bad because of poor Ransac predictability (after referencing): ' badList];
    end

    %% Iteration report
    if isfield(reference, 'maxInterpolationIterations')
        report = sprintf('\n\nActual interpolation iterations: %d\n', ...
            reference.actualInterpolationIterations);
        if ~isempty(reference.interpolatedChannelsFromNaNs)
            report = [report sprintf('Bad NaNs: %s\n', ...
                getListString(reference.interpolatedChannelsFromNaNs))];
        end
        if ~isempty(reference.interpolatedChannelsFromNoData)
            report = [report sprintf('Bad NoData: %s\n', ...
                getListString(reference.interpolatedChannelsFromNoData))];
        end
        if ~isempty(reference.interpolatedChannelsFromHFNoise)
            report = [report sprintf('Bad HF: %s\n', ...
                getListString(reference.interpolatedChannelsFromHFNoise))];
        end
        if ~isempty(reference.interpolatedChannelsFromCorrelation)
            report = [report sprintf('Bad Correlation: %s\n', ...
                getListString(reference.interpolatedChannelsFromCorrelation)) ];
        end
        if ~isempty(reference.interpolatedChannelsFromDeviation)
            report = [report sprintf('Bad Deviation: %s\n', ...
                getListString(reference.interpolatedChannelsFromDeviation)) ];
        end
        if ~isempty(reference.interpolatedChannelsFromRansac)
            report = [report sprintf('Bad Ransac: %s\n', ...
                getListString(reference.interpolatedChannelsFromRansac))];
        end
        if ~isempty(reference.interpolatedChannelsFromDropOuts)
            report = [report sprintf('Bad DropOuts: %s\n', ...
                getListString(reference.interpolatedChannelsFromDropOuts))];
        end
        if ~isempty(reference.channelsStillBad)
            report = [report sprintf('Still bad: %s\n', ...
                getListString(reference.channelsStillBad))];
        end
        fprintf(fid, '%s', report);
        summary{end+1} = report;
    end
    
end