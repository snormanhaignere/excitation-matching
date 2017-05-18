function [coch, P, R] = wav2coch_wrapper(wav, P)

% same as wav2coch.m but simpler to use. Only takes as input the paramater
% structure P, which can be created with the script:
% 
% default_parameters_excitation_matching.m
% 
% -- Example --
% addpath(genpath([pwd '/Sound_Texture_Synthesis_Toolbox']));
% 
% P = default_parameters_excitation_matching;
% 
% % read and format waveform
% [wav,sr] = audioread([pwd '/example-stimuli/speech1.wav']);
% wav = mean(wav,2);
% wav = resample(wav, P.audio_sr, sr);
% 
% % cochleogram
% [coch, P, R] = wav2coch_wrapper(wav, P);
% 
% % plot the cochleogram
% plot_cochleogram(coch, P.f, P.t);
% 
% 2017-05-17: Created, Sam NH

% cochleogram filters
if P.overcomplete==0
    [audio_filts, audio_low_cutoff] = ...
        make_erb_cos_filters(length(wav), P.audio_sr, ...
        P.n_filts, P.lo_freq_hz, P.audio_sr/2);
    
elseif P.overcomplete==1
    [audio_filts, audio_low_cutoff] = ...
        make_erb_cos_filts_double2(length(wav), P.audio_sr, ...
        P.n_filts, P.lo_freq_hz, P.audio_sr/2);
    
elseif P.overcomplete==2
    [audio_filts, audio_low_cutoff] = ...
        make_erb_cos_filts_quadruple2(length(wav), P.audio_sr, ...
        P.n_filts, P.lo_freq_hz, P.audio_sr/2);
end

% remove filters below and above desired cutoffs
xi = audio_low_cutoff > P.lo_freq_hz - 1e-3 ...
    & audio_low_cutoff < P.audio_sr/2 + 1e-3;
audio_filts = audio_filts(:,xi);
audio_low_cutoff = audio_low_cutoff(xi);

% cochleogram 
[coch, P.t, R] = ...
    wav2coch(wav, audio_filts, P.audio_sr, P.env_sr, P.compression_factor);

% assign lower cutoffs to struct
P.f = audio_low_cutoff;