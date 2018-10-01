% This code is written by Roger Zou (Student ID: 26029901)
% Last Modified 12.09.2018
% This file runs all the functions and scripts required to analyse the data
% output from the phased array of microphones designed as part of the
% 'Ultrasonic Phased Array Final Year Project' partaken by Roger Zou and
% Isabelle Lam in 2018.
%
% Data Analysis Methodology:
% (1)   Incoming data is exported from the signal tap tool in Quartus, in a
%       .tbl format, which contains the 16 bit data from each mic sampled 
%       at a specified sample rate.
% (2)   This data then is read in using a text processing function which
%       saves the 16 bit mic data streams into a matrix.
% (3)   Due to the restriction on memory, each reading sample is only 7ms,
%       to extend range, multiple readings are taken with different initial
%       recording delays, allowing for data capture up to 21ms. These 3
%       seperate readings need to be stitched together using another
%       function, which outputs a single matrix containing the total
%       reading for all 16 mics. The number of samples readings that make
%       up each capture can be defined at the beginning of this code.
% (4)   After this capture has been created and stored into a matrix a
%       function is run to post process the data (in software vs hardware).
%       The post processing consists of removing the dc components,
%       bandpass filtering the signals for the transmitted pulse frequency,
%       scaling the received waveforms to have the same max amplitude
%       response and extracting the upper envelopes of the signals. In this
%       step the waveforms are plotted.
% (5)   From the processed signals the local peaks are calculated for each
%       mic signal to determine where received pulses could be. The half
%       amplitude points on each received pulse is calculated which gives
%       an estimate of the time of flight, from which an estimate of the
%       distance to the objects can be calculated. (DISTANCE CALCULATION)
% (6)   At the half amplitude points the phases of the received waveforms
%       is calculated, from which a plane can be fitted to approximate the
%       bearing of an object. (ANGLE CALCULATION)
% (7)   After the distances and angles are calculated the resultant objects
%       are plotted in a 3D space to give a representation of the
%       surroundings of the array.


%-------------------------------------------------------------------------%
%                          CLEARING WORKSPACE                             %
%-------------------------------------------------------------------------%
close all; clearvars; clc;



%-------------------------------------------------------------------------%
%                           GLOBAL VARIABLES                              %
%-------------------------------------------------------------------------%
% Defining variables that are used across functions and that are specific 
% to the physical array

% Text Processing variables
%my_filename = 'test_pulse_6ms_window_';       % file name of capture (no %i.tbl)
%my_filename = 'test_pulse_01ms_transmit_';
my_filename = 'test_pulse_our_array33_';
capture_count = 1;                      % number of captured segments
capture_time_ms = 6;                    % capture window time in ms
mic_count = 14;                         % number of mics in data capture
f_samp = 50*10^6/12/14;                 % sample frequency defined by clock divider used and CIC filter in hardware
t_samp = 1/f_samp;

% Mic Filter Variables
mic_num = [1 2 3 4 5 6 7 8 9 11 12 13 15 16];      % Defining microphones in use, edit this array to change which microphones are being analysed
plotbrowser_flag = 1;                   % Enables the plotbrowser for the mic_filt_func, substantially slows down code

% Distance Calculation Variables
mic_mapping = [1 2 3 4; 5 6 7 8; 9 10 11 12; 13 14 15 16];      % array defining how mics are physically place
rx_pulse_thld = 100*ones(16,1);         % received pulse detection thresholds -> considering calibrating for each mic seperately
peak_min_sep = 1;                       % minimum peak seperation distance in milliseconds, calibrate so no erroneous readings from large transmit pulse amplitude
tof_calib_vec = 2.08e-04*ones(16,1);  % calibration times for half amplitude points to beginning of received pulse -> considering calibrating for each mic seperately
tof_calib_vec = tof_calib_vec + 0.00097776;
tof_col_max_var = 0.001;                % max range of columns in tof_est array
subplot_flag = 1;

% Angle Calculation Variables
sig_samp_length = 0.2;            % sample length used for phase comparison, in milliseconds, set to half rise time
threshold_plane = 0.001;          % Defining threshold for inliers, used in RANSACFITPLANE function
plot_flag = 1;


%-------------------------------------------------------------------------%
%                TEXT PROCESSING OF INCOMING TABLE DATA                   %
%-------------------------------------------------------------------------%
% Defining file path on computer
my_filepath = '\\ad.monash.edu\home\User037\rzou3\Documents\2018 S2\ECE4094 - FYP\Code Documents\Matlab\Optimised Code Our Array\Test Pulses';
col_count_table = mic_count+1;         % setting number of columns in input table, +1 due to transmit pulse

% Determining if need to iterate text_processing_func
if capture_count > 1
    
    % Using for loop to call function n number of times depending on how many
    % capture windows were taken
    for counter = 1:capture_count

        % Calling function to read in table text data into matrices
        % Using eval function to call output variable different names
        eval(sprintf('C_mat_%i = text_processing_func(my_filename,my_filepath, col_count_table, %i);', counter, counter));
        
    end
    
    % If more than one capture need to join capture waveforms at the
    % correct point. To deal with overlap, calculate how many samples
    % overlap reduce the length of the first vector before connecting
    
    % Determining sample index that corresponds to overlap point
    capture_window_end_index = round((capture_time_ms/1000)/t_samp + 1);      % +1 to adjust for index 0 is time 0
    
    C_mat = [];          % Initialising C_mat
    % Connecting C_mat_n together to form C_mat
    for counter = 1:capture_count

        % Iterating as many times as required
        eval(sprintf('C_mat = [C_mat, C_mat_%i(:,1:capture_window_end_index)];', counter));
        
    end
    
else
    % Calling function only once if only one capture taken
    C_mat = text_processing_func(my_filename,my_filepath, col_count_table);
end



%-------------------------------------------------------------------------%
%                    FILTERING AND PLOTTING MIC DATA                      %
%-------------------------------------------------------------------------%
% Extracting mic data from C_mat and plotting mic data using a function
% with inputs defined by which mics were used

% Time array
t_arr = 0:t_samp:t_samp*(length(C_mat(1,:))-1);

% Calling mic_filter function
[t_arr_lc, mic_filt_lc, mic_out, mic_up_env] = mic_filt_func(mic_num, t_samp, C_mat, capture_count, capture_time_ms, plotbrowser_flag);



%-------------------------------------------------------------------------%
%                      DISTANCE CALCULATIONS                              %
%-------------------------------------------------------------------------%
clc;        % clearing handle.listener warnings from load function in mic_filt_func

% Calling dist_calc_func to determine distance calculations
% Distance calculations detailed in dist_calc_func
[tof_est_no_group, tof_est_group, tof_est, dist_est, dist_est_ave, mic_half_amp_index] = dist_calc_func(mic_num, t_arr_lc, mic_up_env, mic_mapping, rx_pulse_thld, peak_min_sep, tof_calib_vec, tof_col_max_var, subplot_flag);



%-------------------------------------------------------------------------%
%                        ANGLE CALCULATIONS                               %
%-------------------------------------------------------------------------%
% Calling ang_calc_func to determine angles to each object
[ori_mic_vec, phase_array, phase_array_wrap_adj, plane_pts, az_el_ang] = ang_calc_func(mic_num, t_arr_lc, mic_filt_lc, mic_mapping, tof_est, mic_half_amp_index, sig_samp_length, threshold_plane, plot_flag);




