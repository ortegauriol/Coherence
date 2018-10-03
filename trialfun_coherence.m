function [trl] = trialfun_coherence(cfg)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% the first part is common to all trial functions
% read the header (needed for the samping rate) and the events
hdr        = ft_read_header(cfg.headerfile);
event      = ft_read_event(cfg.headerfile);

%% from here on it becomes specific to the experiment and the data format
% for the events of interest, find the sample numbers (these are integers)
% for the events of interest, find the trigger values (these are strings in the case of BrainVision)
EVsample   = [event.sample]';
EVvalue    = {event.value}';

% select the target stimuli
Word = find(strcmp('S  1', EVvalue)==1);

PreTrig   = round(4.5 * hdr.Fs);
PostTrig  = round(0 * hdr.Fs);

begsample = EVsample(Word) - PreTrig;
endsample = EVsample(Word) + PostTrig;

offset = -PreTrig*ones(size(endsample));

%% the last part is again common to all trial functions
% return the trl matrix (required) and the event structure (optional)
%trl = [begsample endsample offset task];
trl = [begsample endsample offset];

end

