% This code is written by Roger Zou (Student ID: 26029901)
% Last Modified 12.09.2018
%
% DIST_CALC_FUNC - calculates distance to objects based on mic upper
%                  envelopes, processed data from mic_filt_func
%
% Usage [tof_est, dist_est, dist_est_ave, mic_half_amp_index] = dist_calc_func(mic_num, t_arr_lc, mic_filt_lc, mic_mapping, rx_pulse_thld, rx_pulse_max_width, tof_calib_vec, subplot_flag)
%
% This code takes the processed and filtered mic data and calculates the
% approximate time of flights of the received pulses, and thus the distance
% to objects from the array. 
%
%
% Methodology
% Step 1:   Use inbuilt matlab function findpeaks to determine where peaks
%           are and their index values, if no peaks above a threshold, then
%           no object detected
% Step 2:   Walk backwards from the peaks until half max value occurs in
%           received pulse (or max gradient)
% Step 3:   This time value is when the pulse is received (plus some
%           constant). This constant is defined via tof_calib_vector
% Step 4:   Calculate time of flight (TOF) from received pulse time
% Step 5:   Clean up TOF estimate array by grouping received pulses into 
%           the correct columns, then clearing erroneous peaks
% Step 6:   Calculate distance using speed of sound (~343m/s)
%
% Input Arguments
%   mic_num       - Vector defining which mics are in use/recorded by the
%                   signal tap in Quartus
%   t_arr_lc      - The array holding the time values, after compensating 
%                   for the lag introduced by the filter 
%   mic_up_env    - The filtered upper envelopes of the mic signals
%   mic_mapping   - Array that defines how the mics are physically
%                   arranged
%   rx_pulse_thld - Vector defining the thresholds for detection for each
%                   mic
%   peak_min_sep  - Minimum seperation between peaks detected, in
%                   milliseconds
%   tof_calib_vec - Vector defining calibration times for time of flight
%                   readings
%   tof_col_max_var - The max variation allowed in each column of the tof
%                   estimate array, used to group pulse points correctly
%   subplot_flag  - Flag used to determine if want to plot subplots of peak
%                   calculations, turn off to speed up code
%
% Output Arguments
%   tof_est_no_group   - Estimate of time of flight without grouping
%                        columns by detection time
%   tof_est_group      - Estimate of time of flight with grouping in
%                        columns by detection time
%   tof_est            - Estimate of time of flights to each object for
%                        each mic, rejecting erroneous peaks
%   dist_est           - Estimate of distance to each object for each mic
%   dist_est_ave       - Average distance, considering non-zero readings
%   mic_half_amp_index - The index values for the half amplitude points of
%                        each received pulse detected, used in angle calc

function [tof_est_no_group, tof_est_group, tof_est, dist_est, dist_est_ave, mic_half_amp_index] = dist_calc_func(mic_num, t_arr_lc, mic_up_env, mic_mapping, rx_pulse_thld, peak_min_sep, tof_calib_vec, tof_col_max_var, subplot_flag)
    
    % Converting minpeak_seperation from milliseconds to number of samples
    % t_samp can be found from first value in t_arr_lc
    peak_min_sep_samples = (peak_min_sep/1000)/t_arr_lc(2);
    
    %---------------------------------------------------------------------%
    %         Determining Where Peaks of Received Pulses Occur            %
    %---------------------------------------------------------------------%
    % Using inbuilt Matlab function 'findpeaks' to find peaks in signals
    % Then finding the half amplitude points before each peak, to use as
    % time of flight estimate
    
    % Initialising variables to store peak values and locations
    peaks_dummy = [];               % dummy variable to hold peak values
    locs_dummy = [];                % dummy variable to hold peak locations
    peaks_array = zeros(16,1);      % peak values for each mic, initially large enough size for one peak, resize per loop if more than one peak detected
    locs_array = zeros(16,1);       % peak locations for each mic, resize as above
    half_amp_index_array = zeros(16,1);     % variable holding the half amplitude index values
    
    % Initialising variables for tof estimates and distance estimates
    tof_array = zeros(16,1);
    
    % Creating figure for subplots if subplot flag is on
    if (subplot_flag)
        figure;
        set(gcf, 'Position', [500, 400, 900, 550])
    end
    
    % For loop iterating through each mic signal
    for counter = 1:length(mic_num)
        
        %-----------------------------------------------------------------%
        %                  FINDING PEAKS AND LOCATIONS                    %
        %-----------------------------------------------------------------%        
        % Finding the peaks for each mic signal given calibration variables
        % of minpeakheight and minpeakdistance
        [peaks_dummy, locs_dummy] = findpeaks(mic_up_env(mic_num(counter),:),'MinPeakHeight',rx_pulse_thld(mic_num(counter)),'MinPeakDistance',peak_min_sep_samples);
        
        % Increasing size of peaks array if more than current number of peaks detected
        if (length(peaks_dummy) > size(peaks_array,2))
            
            % Increasing number of columns in peak and peak time array accordingly
            peaks_array = [peaks_array, zeros(16,(length(peaks_dummy)-size(peaks_array,2)))];
            locs_array = [locs_array, zeros(16,(length(locs_dummy)-size(locs_array,2)))];
            
        end
        
        % If number of peaks detected is less than col width of peak and
        % location arrays, pad with number of zeros so can place in arrays
        if (length(peaks_dummy) < size(peaks_array,2))
            
            % Padding with correct number of zeros so can place in array
            peaks_dummy = [peaks_dummy, zeros(1,(size(peaks_array,2)-length(peaks_dummy)))];
            locs_dummy = [locs_dummy, zeros(1,(size(locs_array,2)-length(locs_dummy)))];
            
        end
        
        % Placing dummy variables into correct sized arrays
        peaks_array(mic_num(counter),:) = peaks_dummy;
        locs_array(mic_num(counter),:) = locs_dummy;
        
        
        %-----------------------------------------------------------------%
        %                 FINDING HALF AMPLITUDE INDEXES                  %
        %-----------------------------------------------------------------% 
        % Resizing half amplitude array if necessary
        if (size(half_amp_index_array,2) < size(peaks_array,2))
            
            % Padding with correct number of zero columns depending on
            % max number of peaks detected
            half_amp_index_array = [half_amp_index_array, zeros(16, size(peaks_array,2)-size(half_amp_index_array,2))];
            
        end
        
        % For loop iterating through equal to the number of times a peak
        % was detected
        for counter_2 = 1:(length(peaks_array(mic_num(counter),:)))
            
            % Setting half amp value and t_index to start
            half_amp_val = peaks_array(mic_num(counter),counter_2)/2;
            t_half_amp_start = locs_array(mic_num(counter),counter_2);
            
            % If statement checking if no peak reading for current mic in
            % loop, setting index to zero and not looping to half amplitude
            % point
            
            if (half_amp_val == 0)
                
                % setting t_half_amp_index = 0 before placing in half_amp_index array
                t_half_amp_index = 0;
                
            else
                
                % When a peak is detected, walk backwards from the peak to
                % the point which is below the half amplitude point, this
                % will give the index of the half amplitude location
                t_half_amp_index = t_half_amp_start;        % setting starting index for iteration point
                while (mic_up_env(mic_num(counter),t_half_amp_index) > half_amp_val)
                    
                    % Iterate until mic value below half amplitude
                    t_half_amp_index = t_half_amp_index - 1;
                    
                end 
            end
            
            % Placing half amplitude index into array
            half_amp_index_array(mic_num(counter),counter_2) = t_half_amp_index;
            
        end
        
        %-----------------------------------------------------------------%
        %                   PLOTTING AMPLITUDE GRAPHS                     %
        %-----------------------------------------------------------------% 
        % Plotting data if subplot flag is on
        if (subplot_flag)
            
            % Determining which subplot to plot on
            subplot(4,4,mic_num(counter));
            hold on;
            
            % Plotting upper envelope of mic signal
            plot(t_arr_lc,mic_up_env(mic_num(counter),:));
            
            % Extracting non-zero peak indexes and readings
            t_sub_dummy = locs_array(mic_num(counter),:);       % dummy variable holding t indexes for peaks
            t_sub_dummy = t_sub_dummy(t_sub_dummy~=0);          % removing zero values
            t_sub_dummy = t_arr_lc(t_sub_dummy);                % grabbing time value from time array
            amp_sub_dummy = peaks_array(mic_num(counter),:);    % dummy variable holding amplitude values
            amp_sub_dummy = amp_sub_dummy(amp_sub_dummy~=0);    % removing zero amplitude values
            plot(t_sub_dummy,amp_sub_dummy,'r*');
            
            % Extracting non-zero half amp indexes and readings
            t_sub_dummy = half_amp_index_array(mic_num(counter),:);       % dummy variable holding t indexes for peaks
            t_sub_dummy = t_sub_dummy(t_sub_dummy~=0);          % removing zero values
            amp_sub_dummy = mic_up_env(mic_num(counter),t_sub_dummy);            % dummy variable holding half amplitude values
            t_sub_dummy = t_arr_lc(t_sub_dummy);                % grabbing time value from time array
            plot(t_sub_dummy,amp_sub_dummy,'g*');
            
            % Setting plot parameters
            title_str = sprintf('Peak Detection (Mic %g)',mic_num(counter));
            title(title_str);
            xlabel('Time (s)');
            ylabel('Amplitude');
            hold off;
        end
        
        % Adding legend to last subplot if needed
        if (subplot_flag && (counter==length(mic_num)))
            legend('Mic Signal','Detected Peak','Half Amplitude Location');
        end
        
        %-----------------------------------------------------------------%
        %                    EXTRACTING TOF ESTIMATES                     %
        %-----------------------------------------------------------------%
        % Resizing tof array if necessary
        if (size(tof_array,2) < size(peaks_array,2))
            
            % Padding with correct number of zero columns depending on
            % max number of peaks detected
            tof_array = [tof_array, zeros(16, size(peaks_array,2)-size(tof_array,2))];
            
        end
        
        % Extracting t_arr_lc indices to use
        tof_index_dummy = half_amp_index_array(mic_num(counter),:);         % extracting indexes to use
        tof_index_dummy = tof_index_dummy(tof_index_dummy~=0);              % extacting non-zero readings
        
        % Extracting tof values and placing in tof_array
        tof_est_dummy = t_arr_lc(tof_index_dummy);
        tof_est_dummy = tof_est_dummy - tof_calib_vec(mic_num(counter));    % adjusting tof readings for calibration time associated with rise time to half amplitude of received pulse
        tof_array(mic_num(counter), 1:(length(tof_est_dummy))) = tof_est_dummy;
        
    end
    
    %---------------------------------------------------------------------%
    %                 GROUPING PEAK SETS IN TOF ARRAY                     %
    %---------------------------------------------------------------------%
    % This section of the function analyses the tof data and groups the
    % detected peaks into the correct columns, to account for random noise
    % readings. This is accomplished by finding the minimum of each column,
    % seeing which other mics detected the same peak, then shifting the
    % rows for the mics which did not detect the peak to the right
    peak_tof_error_max = tof_col_max_var;         % max variation from the minimum of each column allowed to exist within column group
    
    % Extending width of tof_est array to ensure no indexing issues in loop
    % Extended with zeros on the RHS, to be removed at the end of the loop
    % Abitrary addition of 16 columns added, can increase if necessary
    % Performing exact same shifts on half_amp_index array
    tof_array_grouped = [tof_array, zeros(16,16)];
    half_amp_index_array = [half_amp_index_array, zeros(16,16)];
    
    % Iterating for number of columns of tof_array
    % Starting at column 2 as column 1 is transmit pulse
    for counter = 2:size(tof_array_grouped,2)
        
        % Finding the non-zero minimum of the column
        col_min = min(tof_array_grouped(tof_array_grouped(:,counter)~=0,counter));
        
        % Setting col_min to zero if sum of column is zero
        if (sum(tof_array_grouped(:,counter)) == 0)
            col_min = 0;
        end
        
        % Determining which values in current column are not within
        % specified range of the minimum
        in_range_vec = zeros(16,1);         % vector holding logical values if current row value in suitable range of column min
        for counter_2 = 1:16
            
            % If statement determining if current row value in suitable
            % range of column minimum
            if (((col_min - peak_tof_error_max) < tof_array_grouped(counter_2,counter)) && (tof_array_grouped(counter_2,counter) < (col_min + peak_tof_error_max)))
                in_range_vec(counter_2,1) = 1;
            else
                in_range_vec(counter_2,1) = 0;
            end
            
            % Shifting rows across where not within specified range
            % ie. when mic did not detect the peak
            % Only shift row across if not within specified range
            if (in_range_vec(counter_2,1) == 0)
                
                % Extracting correct portions of row to shift across,
                % beginning at current column
                row_vector_dummy = tof_array_grouped(counter_2, counter:(size(tof_array_grouped,2)-1));
                row_vector_dummy_2 = half_amp_index_array(counter_2, counter:(size(half_amp_index_array,2)-1));
                
                % Setting correct portion of row to zero before shifting
                tof_array_grouped(counter_2, counter:size(tof_array_grouped,2)) = zeros(1, (size(tof_array_grouped,2)-counter+1));
                half_amp_index_array(counter_2, counter:size(half_amp_index_array,2)) = zeros(1, (size(half_amp_index_array,2)-counter+1));
                
                % Placing row vector_dummy back in to tof_array_grouped but
                % shifted across one column
                tof_array_grouped(counter_2, (counter+1):(size(tof_array_grouped,2))) = row_vector_dummy;
                half_amp_index_array(counter_2, (counter+1):(size(half_amp_index_array,2))) = row_vector_dummy_2;
            end
        end 
    end
    
    % Removing zero columns from tof_array_grouped
    tof_array_grouped = tof_array_grouped(:,any(tof_array_grouped));
    half_amp_index_array = half_amp_index_array(:,any(half_amp_index_array));
    
    
    %---------------------------------------------------------------------%
    %                     REMOVING ERRONEOUS PEAKS                        %
    %---------------------------------------------------------------------%
    % Removing erroneous peaks from tof_est array by determining if enough
    % mics detected the peak
    min_peak_detect = 12;           % setting the minimum number of mics required that detected the peak
    tof_array_str_peaks = tof_array_grouped(:,1);           % Setting strong peaks array to first column as it is the transmit pulse and will always be present
    half_amp_index_array_dummy = half_amp_index_array(:,1);     % creating dummy for mic_half_amp_index array
    
    % Counter running through remaining columns of tof_array_grouped
    % Starting at second column to account for transmit pulse
    for counter = 2:size(tof_array_grouped,2)
        
        % Counting number of zeros in column
        col_zero_count = sum(tof_array_grouped(:,counter)==0);
        
        % If zero count less than 16-min_peak_detect then enough
        % mics have detected the signal, add column to strong peaks array
        if (col_zero_count < (16-min_peak_detect))
            
            % Adding column onto arrays
            tof_array_str_peaks = [tof_array_str_peaks, tof_array_grouped(:,counter)];
            half_amp_index_array_dummy = [half_amp_index_array_dummy, half_amp_index_array(:,counter)];
            
        end
    end
    
    % Setting half_amp_index array to adjust array
    half_amp_index_array = half_amp_index_array_dummy;
    
    
    %---------------------------------------------------------------------%
    %                  CALCULATING DISTANCE ESTIMATES                     %
    %---------------------------------------------------------------------%
    c = 343;            % speed of sound (m/s)
    dist_est_array = tof_array_str_peaks*c/2;
    dist_est_ave_vec = zeros(1,(size(dist_est_array,2)-1));         % vector holding distance measured averages
    
    % Printing distance estimates for each object detected, with the
    % mapping of the mic array
    fprintf('\n\t---------------------------------------------------------------------------------\n');
    fprintf('\t\t\t\t\t\t\t\t\tDISTANCE READINGS');
    fprintf('\n\t---------------------------------------------------------------------------------\n');
    fprintf('\n\tThe microphone array detected %g objects based on the sound reflections received.\n',size(dist_est_array,2)-1);
    for counter = 2:size(dist_est_array,2)
        
        % Starting loop at column 2 as column one peak reading is from
        % intial pulse of ultrasonic transmitter
        
        % extracting column of dist_est array corresponding to each object
        dist_est_dummy_vec = dist_est_array(:,counter);         
        dist_est_ave_dummy = dist_est_dummy_vec(dist_est_dummy_vec~=0);       % extracting non_zero dist values
        dist_est_ave_dummy = mean(dist_est_ave_dummy);      % calculating the average non_zero distance
        dist_est_ave_vec(counter-1) = dist_est_ave_dummy;
        
        fprintf('\n\tThe average distance measured (in metres) to OBJECT %g is %.4g.\n',counter-1,dist_est_ave_dummy);
        fprintf('\tThe distance to OBJECT %g measured by each mic (in metres) is:\n\n',counter-1);
        disp(dist_est_dummy_vec(mic_mapping));
        
    end
    
    
    % Assigning output variables
    tof_est_no_group = tof_array;
    tof_est_group = tof_array_grouped;
    tof_est = tof_array_str_peaks;
    dist_est = dist_est_array;
    dist_est_ave = dist_est_ave_vec;
    mic_half_amp_index = half_amp_index_array;
    
    
    
end


