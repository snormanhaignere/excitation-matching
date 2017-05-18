function [excitation_pattern_set_average, excitation_patterns_all_stimuli] = ...
    measure_excitation_patterns(stimulus_sets, input_directory, P, varargin)

% Computes cochleograms for a collection of stimuli and averages them across
% time to arrive at a set of excitation patterns. The stimuli are organized into
% sets (e.g. a set of music stimuli, a set of speech stimuli, etc.). These sets
% are specified using the following format:
% 
% stimulus_sets = {...
%     {'FNAME_SET1_STIM1', 'FNAME_SET1_STIM2', etc.}, 
%     {'FNAME_SET1_STIM1', 'FNAME_SET1_STIM2', etc.}, 
%     etc.}
% 
% All stimuli should be contained within a single directory (input_directory),
% and all results are saved to this directory.
% 
% The code returns the excitation pattern averaged across all stimuli from a set
% (excitation_pattern_set_average), as well as the excitation pattern for all of
% the stimuli from each set (excitation_patterns_all_stimuli)
% 
% Optional input arguments are described in the section below and are specified
% as key-value pairs. For example: .
% 
% measure_excitation_patterns(stimulus_sets, P, 'plot_figures', false)
% 
% See example_excitation_matching.m and run_excitation_matching.m for examples
% of this function's use
% 
% 2017-05-17/18: Created, Sam NH

% add McDermott Texture toolbox to the path
name_of_this_file = mfilename;
directory_containing_this_file = fileparts(which(name_of_this_file));
addpath(genpath([directory_containing_this_file ...
    '/Sound_Texture_Synthesis_Toolbox']));

%% Optional Inputs

% whether or not over-write / recompute saved analyses
I.overwrite = false;

% whether or not to plot excitation figure
I.plot_figures = true;

% file name to save excitation figure to
I.figure_name = '';

% overwrite with specified inputs
I = parse_optInputs_keyvalue(varargin, I);

%% Compute cochleograms

excitation_patterns_all_stimuli = cell(size(stimulus_sets)); % initialize
for i = 1:length(stimulus_sets)
    for j = 1:length(stimulus_sets{i})
        
        % remove extension
        [~, fname, ~] = fileparts(stimulus_sets{i}{j});
        
        % display current stimulus
        fprintf('%d, %d: %s\n', i, j, fname);
        
        % read in waveform
        [wav, sr] = audioread([input_directory '/' stimulus_sets{i}{j}]);
        
        % convert to mono if necessary
        if size(wav,2)==2
            wav = mean(wav,2);
        else
            assert(size(wav,2)==1); % check mono if not stereo
        end
        
        % resample if needed
        if P.audio_sr ~= sr
            wav = resample(wav, P.audio_sr, sr);
        end
        
        % compute cochleogram, saving results
        MAT_file = [input_directory '/' fname '_cochleogram.mat'];
        if ~exist(MAT_file, 'file') || I.overwrite
            [coch, P, R] = wav2coch_wrapper(wav, P);
            save(MAT_file, 'coch', 'P', 'R');
        else
            load(MAT_file, 'coch', 'P', 'R');
        end
        
        % average across time (after initializing)
        if j == 1
            excitation_patterns_all_stimuli{i} = ...
                nan(size(coch,2), length(stimulus_sets{i}));
        end
        excitation_patterns_all_stimuli{i}(:,j) = mean(coch);
        
    end
    
    % averate across stimuli (after initializing)
    if i == 1
        excitation_pattern_set_average = nan(size(coch,2), length(stimulus_sets));
    end
    excitation_pattern_set_average(:,i) = mean(excitation_patterns_all_stimuli{i},2);
    
end

if I.plot_figures
    
    % plot
    load('colormap-default-line-colors.mat', 'cmap');
    figure;
    hold on;
    names = cell(1, length(stimulus_sets));
    h = nan(1, length(stimulus_sets));
    for i = 1:length(stimulus_sets)
        plot(excitation_patterns_all_stimuli{i}, ...
            'Color', cmap(i,:), 'LineWidth', 0.25); %#ok<NODEF>
        h(i) = plot(excitation_pattern_set_average(:,i), ...
            'Color', cmap(i,:), 'LineWidth', 5);
        names{i} = sprintf('set %d', i);
    end
    
    % increase font
    set(gca, 'FontSize', 16);
    
    % x-axis
    xlim([1, length(P.f)]);
    xticks = get(gca, 'XTick');
    set(gca, 'XTick', xticks, 'XTickLabel', round(P.f(xticks)));
    xlabel('Frequency (Hz)');
    
    % y-axis
    yL = ylim;
    ylim([0, yL(2)]);
    ylabel(sprintf('Power (After Compression to 0.3)'));
    
    % legend
    legend(h, names, 'Location', 'Best');
    
    % save results
    if ~isempty(I.figure_name)
        set(gcf, 'PaperSize', [8 6]);
        set(gcf, 'PaperPosition', [0.25 0.25 7.5 5.5]);
        print([input_directory '/' I.figure_name '.pdf'],'-dpdf');
        print([input_directory '/' I.figure_name '.png'],'-dpng', '-r100');
    end
    
end


