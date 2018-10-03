function data = Process_coherence()
%Function to process coherence data from experiment 2
%
%
%   Input: 
%
%   Output: 
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%                  EMG                     %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%              Load Data                   %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Transform bin files from dragon fly into into mat files
%Select folder where files are contained

folder_path = uigetdir('D:\Data\Coherence', 'Select Folder w EMG FILES');
cd (folder_path);
if exist('Path.mat', 'file') == 2
    load('Path.mat')
else
    [files, path] = batch_bin;
    cd(path)
    [EMG,files] = structure('a',path);
    save('Path','path')
end
% cd 'D:\Data\Coherence\Corey\Coherence';
% pathfile = 'D:\Data\Coherence\Corey\Coherence';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%       Process EMG and Force Data         %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if exist('Pro_EMG.mat', 'file') == 2
    load('Pro_EMG.mat')
else

    %Create Structure Function for the force analysis
    [EMG,~,~,labels,t] = emg_init_coherence(EMG,1,1,1,2000,files);
    Trials = EMG(2,:);
    %Rotate for fieldtrip data format 
    for i = 1:length(Trials)
        Trials{1,i} = Trials{1,i}';;
    end
    save('Pro_EMG','EMG','labels','t','Trials')
end

data.label          = labels';
data.fsample        = 2000;
data.trial          = Trials;
data.time           = repmat(t,length(Trials),1);
data.time           = num2cell(data.time,2)';
cfg.datafile     = 'PRO_EMG.mat';
cfg.headerfile   = 'PRO_EMG.mat';

emg = ft_preprocessing(cfg,data);

% Visualize EMG DATA 
cfg = [];
cfg.continous   = 'no';
cfg.viewmode    = 'vertical';
% cfg = ft_databrowser(cfg, data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%                  EEG                     %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%              Load/epoch Data             %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
folder_path = uigetdir('D:\Data\Coherence', 'Select Folder w EEG FILES');
cd (folder_path);
cfg = [];
cfg.dataset        = dir ('*.eeg');  cfg.dataset = cfg.dataset.name;
cfg.datafile       = dir ('*.eeg');  cfg.datafile = cfg.datafile.name;
cfg.headerfile     = dir ('*.vhdr'); cfg.headerfile = cfg.headerfile.name;

%TRIAL DEFINITION: defines sample init & end to epoch trials.
%User generated function to recognize the markers from brainvision. 
cfg.trialfun            = 'trialfun_coherence'; 
cfg.trialdef.eventvalue = 'S  1';
cfg.trialdef.prestim    = -4.5;
cfg.trialdef.poststim   = 0;
cfg.trialdef.eventtype  = 'string';
%define the trials
cfg = ft_definetrial(cfg);

EEG = ft_preprocessing(cfg);

cfg.continuous          = 'no';     
cfg.channel             = 'EEG';
cfg.viewmode            = 'vertical';
% cfg = ft_databrowser(cfg, EEG);
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%             Process EEG Data             %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%                  EOG                     %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% downsample the data to speed up the next step
if exist('Comp_EEG.mat', 'file') == 2
    load('Comp_EEG.mat')
else
    data = []; data = EEG;
    cfg = [];
    cfg.resamplefs = 2000;
    cfg.detrend    = 'no';
    data = ft_resampledata(cfg, data);
    % perform the independent component analysis (i.e., decompose the data)
    cfg        = [];
    cfg.method = 'runica'; % this is the default and uses the implementation from EEGLAB
    comp = ft_componentanalysis(cfg, data);
    % In principle you can continue analyzing the data on the component level by doing
    % cfg = [];
    % cfg = ...
    % freq = ft_freqanalysis(cfg, comp);
    % % OR
    % cfg = [];
    % cfg = ...
    % timelock = ft_timelockanalysis(cfg, comp);

    % plot the components for visual inspection
    figure
    cfg.component = 1:30;       % specify the component(s) that should be plotted
    cfg.layout    = 'easycapM22.lay'; % specify the layout file that should be used for plotting
    cfg.comment   = 'no';
    ft_topoplotIC(cfg, comp)
    %Browse through the components
    cfg = [];
    cfg.layout = 'easycapM22.lay'; % specify the layout file that should be used for plotting
    cfg.viewmode = 'component';
    ft_databrowser(cfg, comp)

    cfg = [];
    cfg.component = input('Input EOG components: e.g. [1,2,3]');
    data = ft_rejectcomponent(cfg, comp, data)
    save('Comp_EEG','data')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%          Artifacs ID & Removal           %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % % THIS HAS TO BE THREADED WITH THE DIRECTIONS 
% % 
% % % CFG AGAIN
% % %AUTOMATIC DETECTION%
% % % % Thresholding the accumulated z-score
% % % channel selection, cutoff and padding
% % cfg.continuous = 'no';
% % cfg.artfctdef.zvalue.channel    = 'EEG';
% % cfg.artfctdef.zvalue.cutoff     = 30;
% % cfg.artfctdef.zvalue.trlpadding = 0;
% % cfg.artfctdef.zvalue.artpadding = 0;
% % cfg.artfctdef.zvalue.fltpadding = 0;
% % % algorithmic parameters
% % cfg.artfctdef.zvalue.cumulative    = 'yes';
% % cfg.artfctdef.zvalue.medianfilter  = 'yes';
% % cfg.artfctdef.zvalue.medianfiltord = 9;
% % cfg.artfctdef.zvalue.absdiff       = 'yes';
% % % make the process interactive
% % % cfg.artfctdef.zvalue.interactive = 'yes';
% % [cfg, artifact_jump] = ft_artifact_zvalue(cfg,data);
% % cfg.artfctdef.reject          = 'complete';
% % cfg.dataset        = dir ('*.eeg');  cfg.dataset = cfg.dataset.name;
% % cfg.datafile       = dir ('*.eeg');  cfg.datafile = cfg.datafile.name;
% % cfg.headerfile     = dir ('*.vhdr'); cfg.headerfile = cfg.headerfile.name;
% % cfg = ft_rejectartifact(cfg);
% % A = EEG.cfg.trl; %Original trial definition 
% % B = cfg.trl; %New Trial definition after automatic cleaning. 
% % 
% % % Reject the same trials from EMG. 
% % if isequal(A,B) == 0
% %     missing = setdiff(A(:,1),B(:,1));
% %     for i = 1:size(missing,1)
% %         rmv_trl(i) = find(A == missing(i));
% %     end
% % end
% % emg.trial(rmv_trl) = [];
% % emg.time(rmv_trl) = [];
% % emg.sampleinfo(rmv_trl,:) = [];

%%
%FILTERS%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%               Filtering                  %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fitering options
% preprocess the MEG data
cfg.lpfilter                  = 'yes';
cfg.lpfreq                    = 100;
cfg.demean                    = 'yes';
cfg.dftfilter                 = 'yes';
cfg.channel                   = {'EEG'};
cfg.continuous                = 'no';
eeg = ft_preprocessing(cfg);






%% Calculate Coherence





end