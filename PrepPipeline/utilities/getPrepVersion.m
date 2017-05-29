function [currentVersion, changeLog, markdown] = getPrepVersion()

    changeLog = getChangeLog();
    currentVersion = ['PrepPipeline' changeLog(end).version]; 
    markdown = getMarkdown(changeLog);
end

function changeLog = getChangeLog()
   changeLog(1) = ...
     struct('version', '0', 'status', 'Unreleased', 'date', '', 'changes', '');

    changeLog(1).version = '0.55.0';
    changeLog(1).status = 'Released';
    changeLog(1).date = '05/29/2017';
    changeLog(1).changes = { ...
       ['Changed the EEG.etc.noiseDetection structure to contain ' ...
        'removed channels and interpolated channels for easier access ']; ...
       'Fixed reporting to work when bad channels have been removed'; ...
       ['Added original channel labels to EEG.etc.noiseDetection for ' ...
        'ease in reporting']; ... 
       'Added Blasst as an unsupported line noise removal option'; ...
       'Moved legend of spectrum to right, put in checks for removed channels'; ...
       'Corrected bug in smoothing in cleanline'; ...
       'Corrected several reporting issues';
       'Default behavior now outputs errors to command line in addition to logging'; ...
       'Renamed several functions to make naming scheme consistent'; ...
       'Started supporting changelog in versions'; ...
       'Fixed bug in struct2str and improved com return on pop_prepPipeline'};
end

function markdown = getMarkdown(changeLog)
   markdown = '';
   for k = length(changeLog):-1:1
       tString = sprintf('Version %s %s %s\n', changeLog(k).version, ...
           changeLog(k).status, changeLog(k).date);
       changes = changeLog(k).changes;
       for j = 1:length(changes)
           cString = sprintf('* %s\n', changes{j});
           tString = [tString cString]; %#ok<*AGROW>
       end
       markdown = [markdown tString];
   end
end