function [data,folder_path] = batch_bin()

%This function process ALL the bin files from dragonfly transform them into
%*.mat file and returns a sorted list of the file paths. 
%
% -output  = The files are automatically saved in the folder ||
%            + fileList of the *.mat files of the selected folders
%Used functions:
% This function uses Natural-Order Filename Sort, it can be found at 
% http://au.mathworks.com/matlabcentral/fileexchange/47434-natural-order-filename-sort
% 
% 
% Created; Dec 05, 2016
% ortegauriol@gmail.com


% Load Config MAT
%When working at uni computer
% folder_path = 'C:\Users\port970\Dropbox\PhD\First Experiment\Config File';
% AT LAPTOP
folder_path = 'D:\Data\Coherence\Message_Config';
cd(folder_path);
load('Dragonfly_config.mat')

% Convert Files
folder_path = uigetdir('D:\Data\Coherence', 'Select Folder w Files 2 Transform');
cd(folder_path); 
% load('Dragonfly_config.mat')
[status, list] = system( 'dir /B /S *.bin' );
result = textscan( list, '%s', 'delimiter', '\n' );
fileList = result{1};
fileList = natsort(fileList);

%From bin to mat
for i = 1:length(fileList)
    Read_bin(fileList{i},1);
end

% Filepath of the *.mat files
cd(folder_path)
files = dir('*.mat'); data = {files.name};
data= data';

end