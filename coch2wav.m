function wav = coch2wav(...
    coch_envs_compressed_dwnsmp_sr, R, audio_filts, audio_sr, dwnsmp_sr)

% wav = coch2wav(coch_envs_compressed_dwnsmp_sr, R, audio_filts, audio_sr, dwnsmp_sr)
% 
% Reconstructs a waveform from collection of cochlear envelopes.
% 
% -- Inputs --
% 
% coch_envs_compressed_dwnsmp_sr: [time x frequency] matrix of downsampled
% cochlear envelopes (see wav2coch)
% 
% R: structure containing the subband phases, compression factor, and envelope
% errors caused by downsampling/interpolation (see wav2coch)
% 
% audio_filts: cosine filter parameters (see make_erb_cos_filters)
% 
% audio_sr: sampling rate of the audio waveform
% 
% dwnsmp_sr: downsampled sampling rate of the envelopes
% 
% -- Example --
% 
% % texture toolbox
% addpath(genpath([pwd '/Sound_Texture_Synthesis_Toolbox']));
% 
% % read in waveform
% [wav,sr] = audioread([pwd '/speech.wav']);
% P.max_duration_sec = 1;
% wav = 0.1 * format_wav(wav, sr, P);
% 
% % filters
% P = default_synthesis_parameters;
% [audio_filts, audio_low_cutoff] = ...
%     make_erb_cos_filts_quadruple2(length(wav), P.audio_sr, ...
%     P.n_filts, P.lo_freq_hz, P.audio_sr/2);
% 
% % cochleogram
% [coch, P.f, P.t, R] = ...
%     wav2coch(wav, audio_filts, audio_low_cutoff, ...
%     P.audio_sr, P.env_sr, P.compression_factor, P.logf_spacing);
% 
% % reconstruction from cochleogram
% wav_reconstruct = coch2wav(coch, R, ...
%     audio_filts, audio_low_cutoff, P.audio_sr, P.env_sr);
% 
% % plot waveform
% subplot(2,1,1);
% plot(wav);
% subplot(2,1,2);
% plot(wav_reconstruct);
% 
% 2017-05-17: Created, Sam NH

% resample time and frequency axis
coch_envs_audio_sr_reconstructed = ...
    resample(coch_envs_compressed_dwnsmp_sr, audio_sr, dwnsmp_sr);

% remove extra time samples
coch_envs_audio_sr_reconstructed = ...
    coch_envs_audio_sr_reconstructed(1:size(R.coch_phases_audio_sr,1), :);

% truncate
coch_envs_audio_sr_reconstructed(coch_envs_audio_sr_reconstructed<0)=0;

% undo compression
coch_envs_audio_sr_reconstructed = ...
    coch_envs_audio_sr_reconstructed .^ (1/R.compression_factor);

% remove reconstruction error caused by the above steps (see wav2coch)
coch_envs_audio_sr_reconstructed = ...
    coch_envs_audio_sr_reconstructed - R.recon_error_audio_sr;

% combine envelopes with phases
coch_subbands_audio_sr_erbf = ...
    real(coch_envs_audio_sr_reconstructed .* R.coch_phases_audio_sr);

% collapse subbands
wav = collapse_subbands(coch_subbands_audio_sr_erbf, audio_filts);