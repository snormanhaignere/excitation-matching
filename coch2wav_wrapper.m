function [wav, P, R] = coch2wav_wrapper(coch, P, R)

% Similar as coch2wav.m but simpler to use
% 
% -- Example --
% 
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
% % reconstruction from cochleogram
% wav_reconstruct = coch2wav_wrapper(coch, P, R);
% 
% % plot waveform
% subplot(2,1,1);
% plot(wav);
% subplot(2,1,2);
% plot(wav_reconstruct);
% 
% 2017-05-21: Created by Sam NH

% cochleogram filters
if P.overcomplete==0
    [audio_filts, audio_low_cutoff] = ...
        make_erb_cos_filters(size(R.coch_phases_audio_sr,1), P.audio_sr, ...
        P.n_filts, P.lo_freq_hz, P.audio_sr/2);
    
elseif P.overcomplete==1
    [audio_filts, audio_low_cutoff] = ...
        make_erb_cos_filts_double2(size(R.coch_phases_audio_sr,1), P.audio_sr, ...
        P.n_filts, P.lo_freq_hz, P.audio_sr/2);
    
elseif P.overcomplete==2
    [audio_filts, audio_low_cutoff] = ...
        make_erb_cos_filts_quadruple2(size(R.coch_phases_audio_sr,1), P.audio_sr, ...
        P.n_filts, P.lo_freq_hz, P.audio_sr/2);
end

% remove filters below and above desired cutoffs
xi = audio_low_cutoff > P.lo_freq_hz - 1e-3 ...
    & audio_low_cutoff < P.audio_sr/2 + 1e-3;
audio_filts = audio_filts(:,xi);

% convert to cochleogram
wav = coch2wav(coch, R,  audio_filts, P.audio_sr, P.env_sr);
