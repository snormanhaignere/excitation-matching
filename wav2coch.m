function [coch_envs_compressed_dwnsmp_sr, t, R] = ...
    wav2coch(wav, audio_filts, audio_sr, dwnsmp_sr, compression_factor)

% [coch_envs_compressed_dwnsmp_sr, t, R] = ...
%     wav2coch(wav, audio_filts, audio_sr, dwnsmp_sr, compression_factor)
%
% Calculates cochleogram envelopes from an audio waveform. The envelopes are
% downsampled (to dwnsmp_sr). A structure R is returned that along with the
% downsampled envelopes can be used to reconstruct the waveform using the
% function coch2wav.
%
% -- Inputs --
%
% wav: waveform from which to compute cochleogram
%
% audio_filts: cosine filter parameters (see make_erb_cos_filters)
%
% audio_sr: sampling rate of the audio waveform
%
% dwnsmp_sr: downsampled sampling rate of the envelopes
%
% compression_factor: power to which subbands are raised (e.g. 0.3)
%
% -- Outputs --
%
% coch_envs_compressed_dwnsmp_sr: cochleogram envelopes, downsampled in time
%
% t: vector of time indices for the subbands
%
% R: structure containing the subband phases, logarithmic frequencies,
% compression factor, and envelope errors caused by downsampling;
% used to reconstruct the waveform (see coch2wav)
%
% % -- Example --
%
% % texture toolbox
% addpath(genpath([pwd '/Sound_Texture_Synthesis_Toolbox']));
%
% % read in waveform
% [wav,sr] = audioread([pwd '/speech1_1sec.wav']);
%
% % filters
% P = default_parameters_excitation_matching;
% [audio_filts, audio_low_cutoff] = ...
%     make_erb_cos_filts_quadruple2(length(wav), P.audio_sr, ...
%     P.n_filts, P.lo_freq_hz, P.audio_sr/2);
%
% % cochleogram
% [coch, P.t, R] = ...
%     wav2coch(wav, audio_filts, P.audio_sr, P.env_sr, P.compression_factor);
%
% % plot the cochleogram
% plot_cochleogram(coch, audio_low_cutoff, P.t);
% 
% 2017-05-17: Created, Sam NH

% -- Analysis --

% subbands from waveform
coch_subbands_audio_sr = generate_subbands(wav, audio_filts);

% subband envelopes
analytic_subbands_audio_sr = hilbert(coch_subbands_audio_sr);
coch_envs_audio_sr = abs(analytic_subbands_audio_sr);

% subband phases
R.coch_phases_audio_sr = analytic_subbands_audio_sr./coch_envs_audio_sr;
clear coch_subbands_audio_sr analytic_subbands_audio_sr;

% compress envelopes
R.compression_factor = compression_factor;
coch_envs_compressed_audio_sr = coch_envs_audio_sr .^ R.compression_factor;

% resample time axis
coch_envs_compressed_dwnsmp_sr = ...
    resample(coch_envs_compressed_audio_sr, dwnsmp_sr, audio_sr);

% time vector
n_t = size(coch_envs_compressed_dwnsmp_sr,1);
t = (0:n_t-1)/dwnsmp_sr;

% truncate negatives
coch_envs_compressed_dwnsmp_sr(coch_envs_compressed_dwnsmp_sr<0)=0;

% -- Reverse analysis to compute errors for reconstruction --

% resample time and frequency axis
coch_envs_audio_sr_reconstructed = ...
    resample(coch_envs_compressed_dwnsmp_sr, audio_sr, dwnsmp_sr);

% remove extra time samples
coch_envs_audio_sr_reconstructed = ...
    coch_envs_audio_sr_reconstructed(1:length(wav), :);

% truncate
coch_envs_audio_sr_reconstructed(coch_envs_audio_sr_reconstructed<0)=0;

% undo compression
coch_envs_audio_sr_reconstructed = ...
    coch_envs_audio_sr_reconstructed .^ (1/R.compression_factor);

% compute error
R.recon_error_audio_sr = ...
    coch_envs_audio_sr_reconstructed - coch_envs_audio_sr;