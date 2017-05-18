% Illustrates how to perform the matching analysis

% directory containing the stimuli
directory_containing_this_file = fileparts(which('example_excitation_matching.m'));
input_directory = [directory_containing_this_file '/example-stimuli'];

% default parameters
P = default_parameters_excitation_matching;

% stimuli, organized into two sets
% the program will match the average excitation pattern between the sets
stimulus_sets = cell(1,2);
stimulus_sets{1} = {'cello1.wav', 'cello2.wav'};
stimulus_sets{2} = {'speech1.wav', 'speech2.wav', 'speech3.wav'};

% match both sets to the mean of the two sets
run_excitation_matching(stimulus_sets, input_directory, P)

% match music to speech
run_excitation_matching(stimulus_sets, input_directory, P, ...
    'target_stimulus_set', 2);

% match speech to music
run_excitation_matching(stimulus_sets, input_directory, P, ...
    'target_stimulus_set', 1);

% use more iterations (default=1), resulting in better but longer matching
run_excitation_matching(stimulus_sets, input_directory, P, 'n_iter', 10)



