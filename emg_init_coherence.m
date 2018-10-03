function [Processed_EMG, avCat, enveCat,muscle_str,t] = emg_init_(data,notch,det,unitv,sfreq,files,fatigue)
%%  [Processed_EMG] = emg_init_(1,1,1,1,2000,fileList)
%Function to process EMG data from already structured matlab file
%containing EMG data from dragonfly acquisition system. 
%
% notch, if true 50 Hz filter is on. 
% detrend, if TRUE data is detrended before filter application 
%
%   INPUT:
%           - Data:     1xN cells structures containing the EMGs from all the trials.
%           - Notch:    1 = apply 50 HZ filter (49-51 notch) || 0 = ~apply
%           - Detrend:  1 = apply detrend 'constant' || 0 = ~apply
%           - unitv:    1 = apply unit variance || 0 = ~apply
%           - sfreq:    declare sampling frequency, if not 2000 is default
%           - files:    List of files from structure.
%           - fatigue:  declare something if processing fatigue trials. ]
% 
%   Output: 
%           - Processed_EMG: By row order is the Raw, filtered, envelope,
%           and Average EMG.
%EMG plot function for the EMG trigno data visualization. 
%The EMG channels need to be in a column order and each channel will be
%assign to the corresponding column number. If a notch filter (49-51 2nd butter)
%wants to be applied a second variable should be declared.
%The function gives 3 outputs Raw, filtered, and the envelope data...
% 
% 
% Created; September 29, 2016
% ortegauriol@gmail.com

disp('PROCESSING EMG...')
%%
%****************************************************
%               INITIALIZE & CHECK                  %
%****************************************************
EMG =[];cwd = [];Raw =[];filtered=[];envelope=[];lim=[];
str = 'Channel. '; 
muscle_str = {'Upper Trap', 'Middle Trap','Infraspinatus','Teres Minor','Serratus Ant.',...
    'Ant. Deltoid','Mid. Deltoid','Post. Deltoid','Pect. Major','L.H. Triceps',...
    'S.H. Triceps','L.H. Biceps','S.H. Biceps','Brachioradialis','Wrist Ext.','Wrist Flx.'};
if ~exist('sfreq', 'var')
sfreq = 2000;%constant in trigno
end

if ischar(data)==1
    disp ('Load Data')
    data = load (data);
else 
    disp('Data from workspace')
end
t=0:1/sfreq:size(data,1)/sfreq-1/sfreq; %nice way to create time variable.


%%
%****************************************************
%                SIGNAL PROCESSING                  %
%****************************************************
EMGs = data; 
for aa = 1:size(data,2)

     
      data = EMGs{aa};

%****************************************************
%            REMOVE CHANNELS W/ NO DATA             %
%****************************************************

    %Get indexes first 
    [row, column] = find(data(2,:));
    % Remove data withot channels
    i=1;
    for k=1:size(data,2)    
        if mean(data(:,k))~=0
            cwd(:,i)=data(:,k);
            i=i+1;
        end
    end
    Raw = cwd;
    raw=cwd;
%****************************************************
%                    DETREND                        %
%**************************************************** 

if exist('det','var')==1
    data = detrend (Raw,'constant');
    disp('Data mean substracted');
else
    disp('Not detrended') 
end

%****************************************************
%               INDEXES TO TRIM DATA               %
%**************************************************** 
% Trim coherence to 4.5 seconds before FT_data_complete meesagge
% EMG is of different sizes depending on the time that has been recording
% before the end trial marker (FT_COMPLETE), trim data at the marker spo
exist fatigue var;
if ans == 0
    sample = zeros(size(files));
    discarded = [];
    for p = 1:length(files)
        load(files{p});
% FT_COMPLETE determines the end of a trial, spot of EEG marker as well.
        if  any(strcmp('FT_COMPLETE',fieldnames(log.Headers)))==1
            n = size (log.Headers.FT_COMPLETE.send_time,2);
            A = log.Headers.FT_COMPLETE.send_time(2);
        else
            discarded{p} = p;
            continue
        end
% TRIGNO_DATA.send_time = when emg packages where sent
        B = log.Headers.TRIGNO_DATA.send_time;
        tmp = abs(B-A);
        [idx idx] = min(tmp);
        sample(p) = idx*27; % get the sample number to trimm the data
    end

     if  sample(aa)==0
         EMG =[];cwd = [];Raw =[];filtered=[];envelope=[];lim=[];
         disp(strcat('DONE WITH TRIAL' ,num2str(aa)))
         continue
     end
        % TRIMM IT
        %data = data(sample(aa)-7051:sample(aa)-950,:);
    %Coherence trim is 4.5 seconds before.
        data = data(sample(aa)-9001:sample(aa),:);
        t=0:1/sfreq:size(data,1)/sfreq-1/sfreq; %nice way to create time variable.
end
t=0:1/sfreq:size(data,1)/sfreq-1/sfreq; %nice way to create time variable.
%%
%****************************************************
%                  FILTERING                        %
%**************************************************** 

%HIGH PASS FILTER%%
    [b,a] = butter(2,3/(sfreq/2),'high');             
    DataDifFil = filtfilt (b,a,double(data));   
if exist('notch','var')==1
    %Filter to remove, first the 50 hz.
    [b,a] = butter(2,[49,51]/(sfreq/2),'stop');
    DataDifFil= filtfilt(b,a,double(DataDifFil));
    disp('50 Hz filter ON')
else
    disp('50 Hz filter OFF')
end

% LOW PASS FILTER
    [b,a] = butter(2, 400/(sfreq/2),'low'); 
    DataDifFil = filtfilt(b,a,double(DataDifFil)); 
    
%PLOT FREQUEMCY ANALYSIS
%Case that data points is less than a second
if size(DataDifFil,1)<sfreq
   window =  size(DataDifFil,1);
else
   window = sfreq;
end
    

for n = 1:size(DataDifFil,2);
    fig=figure(2);set(fig,'units','normalized','outerposition',[0 0 0.5 1])
    [p,f] = pwelch (DataDifFil(:,n),window,round(0.25*window),sfreq,sfreq);
    handle(column(n)) = subplot(ceil(size(DataDifFil,2)/2),2,n); plot(f,p,'color','r'); 
%     title(strcat(str ,num2str(column(n))))
    title(muscle_str(n))
    ax = gca; ax.XColor = 'white'; ax.YColor = 'white'; box off;
    if n ==size(DataDifFil,2)
        ax.XColor = 'black';ax.YColor = 'black';
    end
    limit(n,:) = ylim;
    xlim([0 600]);
    xlabel('Frequency');ylabel('Power');
    axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    text(0.5, 1,'\bf Welch Spectral Frequency Analysis of Raw Signal','HorizontalAlignment' ,'center','VerticalAlignment', 'top');
end
%     Same limit for all plots y axis
%     for p = column
%         ylim(handle(p),[0 max(limit(:))])
%     end
     hold off;
    set(gcf,'color','w');
    
%****************************************************
%                    RECTIFY                        %
%**************************************************** 
data=DataDifFil;
data = abs(data);
% filtered = data;

%%
%****************************************************
%                 NORMALIZE DATA                    %
%**************************************************** 
%Intro MVC normalization of the data
%Normalize to max activation of one muscle.

% normal = max(data(:));
% data = (data./normal)*100;

%Norm to max activation of each muscle 


% normal_chan = max(data,[],1);
% temp = [];
% for z = 1:size(data,2)
% temp(:,z) = (data(:,z)./normal_chan(z))*100;
% end
% data = temp;
filtered = data;

%%

%****************************************************
%               PLOT FILTERED DATA                  %
%**************************************************** 
figure(3);set(fig,'units','normalized','outerposition',[0 0 0.5 1]);
% ha= tight_subplot(ceil(size(DataDifFil,2)/2),2,0.05,[.1 .1],[.1 .03]);
ax = gca; ax.XColor = 'white';
for i=1:size(DataDifFil,2)
    subplot(ceil(size(DataDifFil,2)/2),2,i)
%     axes(ha(i))
    plot(t,data(:,i),'Color',rgb('Teal'));
        title(muscle_str(i))
%         title(strcat(str ,num2str(column(i))))
    hold all
end

%****************************************************
%                   ENVELOPE                        %
%**************************************************** 
[b,a] = butter(2, 6/(sfreq/2),'low'); 
data = filtfilt(b,a,double(data)); 
for i=1:size(DataDifFil,2)
    subplot(ceil(size(DataDifFil,2)/2),2,i);
    plot(t,data(:,i),'r','LineWidth',2);
    hold off;
    ax = gca; ax.XColor = 'white'; ax.YColor = 'white'; box off;
    ylim([0 inf]);
    lim(i,:) = ylim;
    if i ==size(DataDifFil,2)
        ax.XColor = 'black';ax.YColor = 'Black';
    end 
hl=legend('Filt.& Rect.','Linear envelope','Location','north','Orientation','horizontal');
hl.Position = [0.4 0.84 0.2 0.2];
    xlabel('Time');ylabel('Amplitude (mV-Unit STD)');
    axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    text(0.5, 1,'\bf Filtered Signal & Envelope','HorizontalAlignment' ,'center','VerticalAlignment', 'top')
    
end

set(gcf,'color','w'); 
envelope=data; 

drawnow; 
    
%%    
%****************************************************
%        AVERAGE THE DATA OR SELECT A WINDOW        %
%****************************************************
 
% Trim surplus of data to prevent 0s at the beggining
%filtered = filtered(52:end-51,:);
%envelope = envelope(52:end-51,:);

average = mean(envelope);



Processed_EMG{1,aa} = Raw;
Processed_EMG{2,aa} = filtered;
Processed_EMG{3,aa} = envelope;
Processed_EMG{4,aa} = average;
EMG =[];cwd = [];Raw =[];filtered=[];envelope=[];lim=[];
disp(strcat('DONE WITH TRIAL_ ' ,num2str(aa)));
disp(' ');
end %Finished to process all data in EMG


    
%****************************************************
%        CONCATENATE THE DATA FOR INPUT             %
%****************************************************

enveCat = vertcat(Processed_EMG{3,1:end});
idx = find(enveCat<0);
enveCat(idx)=0; find(enveCat<0);
avCat =  vertcat(Processed_EMG{4,1:end});

%%
disp('To synergies!! >>>>')
% 
% 
% %****************************************************
% %        Include the direction under EMG            %
% %****************************************************
% K = importfile('order.csv');
% Dict= loadjson('dictionary.json');
% 
% %****************************************************
% %              Remove Rest Fields                   %
% %****************************************************
% % *if any
% % This because this file is not recorded, thus the order is good again.
% field = 'pos_13';
% Dict = rmfield(Dict,field);
% K(:, cellfun(@(x)x==13, K(1,:))) = [];
%  
% %****************************************************
% %              Create Structured Data               %
% %****************************************************
% TA = zeros(length(K), 3); 
% for n = 1:length(K)
%    string = sprintf('Dict.pos_%d', cell2mat(K(n)));
%    direction(n).order = cell2mat(K(n));
%    direction(n).vector= eval(string);
%    TA(n,:) = eval(string);
% end
% 
% % get the order underneath EMG{}
% 
% for i = 1:26
%    Processed_EMG{5,i} = direction(i).vector;
% end

end



