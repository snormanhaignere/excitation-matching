function P = default_parameters_excitation_matching

% number of iterations to run algorithm for
P.n_iter = 100;

% audio sampling rate
P.audio_sr = 20000;

% sampling rate of the envelope in seconds
P.env_sr = 400;

% lowest filter in the audio filter bank
% highest is the nyquist - P.audio_sr/2
P.lo_freq_hz = 20;

% number of cosine filters to use
% increasing the number of filters
% decreases the bandwidth of the filters
P.n_filts = 30;

% whether or not the number of filters is
% complete (=0), 1x overcomplete (=1), or 2x overcomplete (=2)
% overcomplete representations typically result in slightly more compelling 
% synthetics, but require more time and memory 
P.overcomplete = 2;

% factor to which cochleogram envelopes are raised
P.compression_factor = 0.3;