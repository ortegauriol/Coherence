function [data] = Read_bin(filename, s)

% Function to read and store the information contained in the *.bin files
% giving it as an output from Draqonfly interface.
%
% Input: The filename of the *.bin file, containing the .bin - if second
% input ==1 the output will be inmediatly saved.
% The dragonfly_config.mat must be present in the CD folder.
%
% Output: Structured data if second argument is given the file can be
% stored under that name. 

%% Add this path in rangitoto (the module and utils are needed for this function to work)
%addpath('C:\Program Files\Dragonfly\src\utils\LogReader');
%addpath('C:\Users\amcmorl\Documents\BCI\modules\data_loader');

% disp('Store the dragonfly_config.mat to -- C:\Users\ortegauriol\Dropbox\PhD\Xperiments\Pilot');

data = [];

folder_path = 'D:\Data\Coherence\Message_Config';
cd(folder_path);
load('Dragonfly_config.mat')
    
%cd('E:\Synergies\Data\Des\Directions');
    if exist ('filename', 'var')==1
        Filename = filename;
    else
        [Filename,PathName,FilterIndex] = uigetfile('*.bin', 'Select file...');
    end
   
rawlog = LoadRawMessageLog(Filename,DF);
log = OrganizeLogByMsgType(rawlog,DF);
data = log;
    if exist('s','var')==1
        save(strcat(Filename,'.mat'),'log','-mat');
    end

end