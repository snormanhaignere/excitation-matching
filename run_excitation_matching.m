function run_excitation_matching(stimulus_sets, input_directory, P, varargin)

% Top-level script for performing excitation matching. Computes cochleograms
% for multiple sets of stimuli and alters the stimuli so that the excitation
% patterns are matched. Stimuli are specified using the following format:
% 
% stimulus_sets = {...
%     {'FNAME_SET1_STIM1', 'FNAME_SET1_STIM2', etc.}, 
%     {'FNAME_SET1_STIM1', 'FNAME_SET1_STIM2', etc.}, 
%     etc.}
% 
% All stimuli should be contained within a single directory (input_directory),
% and all results are saved to this directory.
% 
% A parameter structure, P, controls the parameters for of the cochleogram. See
% default_parameters_excitation_matching for details.
% 
% Optional input arguments are described in the section below and are specified
% as key-value pairs. For example: .
% 
% run_excitation_matching(stimulus_sets, P, 'target_stimulus_set', 1)
% 
% See example_excitation_matching.m for example use.
% 
% 2017-05-17/18: Created, Sam NH

%% Optional Inputs

% stimulus set to match all others to; default is not to use any particular
% stimulus set, but to instead match everything to the mean excitation pattern
% across stimuli (target_stimulus_set = 0); to match a specific stimulus set,
% specify the index of that stimulus set
I.target_stimulus_set = 0;

% whether or not to plot excitation figure
I.plot_figures = true;

% number of iterations to use in the synthesesis, goal of the iterations is to
% get the phases to relax to something consistent with the envelope, in practice
% a single iteration (i.e. no iterations) is often sufficient because the
% envelopes have not been changed dramatically, but more iterations is always
% better (just takes more time)
I.n_iter = 1;

% whether or not over-write / recompute cochleograms for the input stimuli
I.overwrite = false;

% overwrite with specified inputs
I = parse_optInputs_keyvalue(varargin, I);

%% Compute cochleograms / excitation patterns for the original stimuli

fprintf('\n\n-- Analyzing original cochleograms ---\n\n\n');

excitation_pattern_average = ...
    measure_excitation_patterns(stimulus_sets, input_directory, P, ...
    'figure_name', 'excitation-patterns-original', ...
    'plot_figures', I.plot_figures, 'overwrite', I.overwrite);

%% Synthesize new stimuli with matched excitation patterns

fprintf('\n\n-- Synthesizing excitation-matched cochleograms ---\n\n\n');

stimulus_sets_matched = synthesize_matched_stimuli(...
    stimulus_sets, excitation_pattern_average, input_directory, ...
    'n_iter', I.n_iter, ...
    'target_stimulus_set', I.target_stimulus_set, ...
    'plot_figures', I.plot_figures);

%% Re-compute cochleograms for the matched stimuli

fprintf('\n\n-- Analyzing excitation-matched cochleograms ---\n\n\n');

figure_name = ['excitation-patterns-matched' ...
    '_targ' num2str(I.target_stimulus_set) '_niter' num2str(I.n_iter)];
measure_excitation_patterns(stimulus_sets_matched, input_directory, P, ...
    'figure_name', figure_name, 'overwrite', true);