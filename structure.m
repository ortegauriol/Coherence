function [array_EMG, fileList] = structure(data, pathfile) 

%Function to arrange emg data in column time series.
%
%Input:
%       - If fatigue trials are being process, the string 'fatigue' should
%       be given as an input. This will load the files in natsort order (you need this function)
%       and vertcat all the files present in the folder. And store it in a
%       cell structure again.
% 
%Output: 
%       - An structure containing all the trials EMG, and the file list
%       
%Dependencies: 
%       - natsort: https://au.mathworks.com/matlabcentral/fileexchange/47434-natural-order-filename-sort
%       
% Create a fileList containing the *.mat files of a selected folder. 

if ~exist('pathfile', 'var')
    folder_path = uigetdir;
    
    cd(folder_path)
else
    cd(pathfile)
end

files = dir('*.mat'); file = {files.name};
file = file';
file = natsort(file);
fileList = file;

exist data var;
if ans ==1;
    sys = data;
end
%****************************************************
%                Load and declare                   %
%****************************************************
    
channels = 16; % available chanels in trigno base.
    
for k = 1: length(file)
    load (file{k});
    data = log.Data.TRIGNO_DATA.T;
    final = 1;
%****************************************************
%                Channels to Column                 %
%****************************************************
    for j = 1:channels
        channel{j} = [];
    end
%Columns are a 27 samples per channel
    for j = 1:channels
       start = final+1; final = 27*j; 
            if j==1
                start=1;
            end
        for i = 1:size(data,2)
            channel{j} = [channel{j};data(start:final,i)];
        end
    end
%Output just an array
    EMG{k} = cell2mat(channel);
    array_EMG{k}= EMG{k};
 
%****************************************************
%              PLOT RAW EMG per TRIAL               %
%****************************************************
    figure(); signal=[EMG{k}];
    for i=1:channels
        subplot(ceil(channels/2),2,i)
            plot(signal(:,i))
        hold all
    end
    drawnow;
    pause(1);
    close all;
end
S = sprintf('Data is an EMG array ordered in columns %n');
disp(S)

exist sys var;
if ans == 1
    C = vertcat(EMG{1,1:size(EMG,2)});
    clear EMG
    EMG{1,1} = C;
end

end 