function [stimulus_sets_matched, r] = synthesize_matched_stimuli(...
    stimulus_sets, excitation_pattern_average, input_directory, varargin)

% Synthesizes stimuli with matched excitation patterns. The excitation patterns
% and cochleograms must already have been computed from
% measure_excitation_patterns.m, see run_excitation_matching.m for the
% appropriate format.
% 
% 2017-05-17/18: Created, Sam NH

% add McDermott Texture toolbox to the path
name_of_this_file = mfilename;
directory_containing_this_file = fileparts(which(name_of_this_file));
addpath(genpath([directory_containing_this_file ...
    '/Sound_Texture_Synthesis_Toolbox']));

%% Optional Inputs

% whether or not to plot excitation figure
I.plot_figures = true;

% stimulus set to match all others to; default is to match the mean excitation
% pattern across all stimulus sets (target_stimulus_set = 0); to match a
% specific stimulus set, specify the index of that stimulus set
I.target_stimulus_set = 0;

% number of iterations to use in the synthesesis, goal of the iterations is to
% get the phases to relax to something consistent with the envelope, in practice
% a single iteration (i.e. no iterations) is often sufficient because the
% envelopes have not been changed dramatically, but more iterations is always
% better (just takes more time)
I.n_iter = 1;

% whether or not to sythesize new stimuli for the target stimulus set, there is
% no reason to do this since the target stimuli should be unchanged, but this
% can be a useful check that the code is working
I.synthesize_target_stimulus_set = true;

% whether or not over-write / recompute saved analyses
I.overwrite = false;

% overwrite with specified inputs
I = parse_optInputs_keyvalue(varargin, I);

%% Synthesis

% the excitation pattern to match each stimulus set to
if I.target_stimulus_set == 0
    target_excitation_pattern = mean(excitation_pattern_average, 2);
else
    target_excitation_pattern = excitation_pattern_average(:, I.target_stimulus_set);
end

% initialize
r = cell(size(stimulus_sets));
stimulus_sets_matched = cell(size(stimulus_sets));

for i = 1:length(stimulus_sets)
    
    % per frequency, multiplicative change in the excitation pattern
    excitation_delta = target_excitation_pattern ./ excitation_pattern_average(:,i);
    
    r{i} = nan(I.n_iter, length(stimulus_sets{i}));
    stimulus_sets_matched{i} = cell(size(stimulus_sets{i}));
    for j = 1:length(stimulus_sets{i})
        
        % remove extension
        [~, fname, ~] = fileparts(stimulus_sets{i}{j});
        
        % display current stimulus
        fprintf('%d, %d: %s\n', i, j, fname);
        
        % optionally skip if the stimulus set is the target, in which case no
        % change is needed
        if i == I.target_stimulus_set && ~I.synthesize_target_stimulus_set
            stimulus_sets_matched{i}{j} = stimulus_sets{i}{j};
            continue;
        else
            stimulus_sets_matched{i}{j} = [fname '_matched' ...
                '_targ' num2str(I.target_stimulus_set) ...
                '_niter' num2str(I.n_iter) '.wav'];
        end
        
        % skip if already completed
        matched_audio_file = [input_directory '/' stimulus_sets_matched{i}{j}];
        if exist(matched_audio_file, 'file') && ~I.overwrite
            continue;
        end
        
        % load the previously computed cochleogram
        % see measure_cochleograms
        MAT_file = [input_directory '/' fname '_cochleogram.mat'];
        load(MAT_file, 'coch', 'P', 'R');
        original_coch = coch;
        clear coch;
        
        % re-scale the excitation pattern
        target_coch = bsxfun(@times, original_coch, excitation_delta');
        
        % iteratively synthesize, so phases relax
        for k = 1:I.n_iter
            fprintf('Iter %d\n', k);
            recon_wav = coch2wav_wrapper(target_coch, P, R);
            [actual_coch, P, R] = wav2coch_wrapper(recon_wav, P);
            r{i}(k,j) = corr(actual_coch(:), target_coch(:));
        end
        
        % write waveform
        audiowrite(matched_audio_file, recon_wav, P.audio_sr); 
        
        % plot figures showing the various cochleograms computed
        if I.plot_figures
                  
            % prevent too many figures from being opened
            if length(findall(0,'type','figure')) > 20
                close all;
            end
            
            % plot
            figure;
            set(gcf, 'Position', [100 100 600 600]);
            subplot(3, 1, 1);
            plot_cochleogram(original_coch, P.f, P.t);
            title('Original');
            subplot(3, 1, 2);
            plot_cochleogram(target_coch, P.f, P.t);
            title('Rescaled Target');
            subplot(3, 1, 3);
            plot_cochleogram(actual_coch, P.f, P.t);
            title('Actual Cochleogram');
            
            % save 
            figure_name = ...
                [input_directory '/' fname '_cochleograms' ...
                '_targ' num2str(I.target_stimulus_set) ...
                '_niter' num2str(I.n_iter)];
            set(gcf, 'PaperSize', [10 10]);
            set(gcf, 'PaperPosition', [0.25 0.25 9.5 9.5]);
            print([figure_name '.pdf'],'-dpdf');
            print([figure_name '.png'],'-dpng', '-r100');
            
        end
    end
end

% plot correlation metric
r_all = cat(2, r{:});
if I.plot_figures && all(~isnan(r_all(:)))
    
    % plot
    figure;
    set(gcf, 'Position', [200 200 500 500]);
    hold on;
    plot(1:I.n_iter, r_all.^2, '-o', 'LineWidth', 0.5);
    plot(1:I.n_iter, mean(r_all.^2,2), 'k-o', 'LineWidth', 5);
    
    % axis formatting
    set(gca, 'FontSize', 16);
    xlabel('Iteration');
    ylabel(sprintf('corr target vs actual (r^2)'))
    
    % save
    figure_name = ...
        [input_directory '/corr' ...
        '_targ' num2str(I.target_stimulus_set) ...
        '_niter' num2str(I.n_iter)];
    set(gcf, 'PaperSize', [10 10]);
    set(gcf, 'PaperPosition', [0.25 0.25 9.5 9.5]);
    print([figure_name '.pdf'],'-dpdf');
    print([figure_name '.png'],'-dpng', '-r100');
    
end




