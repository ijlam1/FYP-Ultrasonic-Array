% This code is written by Roger Zou (Student ID: 26029901)
% Last Modified 12.09.2018
%
% MIC_PLOT_FUNC - extracts, filters and plots the mic data in C_mat
%
% Usage [t_arr_lc, mic_filt_lc, mic_out, mic_up_env] = mic_plot_func(mic_num, t_samp, C_mat, plotbrowser_flag)
%
% This code extracts the mic data from C_mat found by the
% text_prcessing_func. It then removes the DC offset, applies a bandpass
% filter, scales the data according to the largest peak, extracts the
% envelopes of the signals and plots them.
%
% Input Arguments
%   mic_num          - Vector defining which mics are in use/recorded 
%                      by the signal tap in Quartus
%   t_samp           - Sample time
%   C_mat            - Mic output data after CIC filtering
%   capture count    - Number of capture windows used
%   capture_time_ms  - Capture window in milliseconds
%   plotbrowser_flag - Flag defining whether to turn the plot browser on
% 
% Output Arguments
%   t_arr_lc    - The array holding the time values, after compensating for
%                 the lag introduced by the filter
%   mic_filt_lc - The filtered mic signals, compensated for lag as above
%   mic_out     - Output mic data before any filtering
%   mic_up_env  - Array containing upper mic envelopes

function [t_arr_lc, mic_filt_lc, mic_out, mic_up_env] = mic_filt_func(mic_num, t_samp, C_mat, capture_count, capture_time_ms, plotbrowser_flag)
    
    %---------------------------------------------------------------------%
    %                    Extracting Mic Output Data                       %
    %---------------------------------------------------------------------%
    % Initialising array to store microphone output data
    mic_out = zeros(length(mic_num),length(C_mat(1,:)));
    t_arr = 0:t_samp:t_samp*(length(C_mat(1,:))-1);     % time array
    
    % Using a for loop to read data into mic_out array, then plotting mic
    % output data on the same figure
    mat_offset = 3;         % defining number of lines required offset to read in data correctly from C_mat
    figure; hold on;        % figure for mic output data
    
    for counter = 1:length(mic_num)
        mic_out(mic_num(counter),:) = C_mat(mat_offset+counter,:);      % extracting data from C_mat
        plot(t_arr,mic_out(mic_num(counter),:));        % plotting mic outputs
    end
    
    % Plot of mic outputs labels
    % Creating legend label using for loop
    my_legend_str = sprintf('''Mic %i''',mic_num(1));           % initialising my legend str
    for counter = mic_num(2:end)
        my_legend_str = sprintf('%s,''Mic %i''',my_legend_str,counter);
    end
    
    eval(sprintf('legend(%s);',my_legend_str));
    %legend('Mic 1','Mic 2','Mic 3','Mic 5','Mic 6','Mic 7','Mic 8','Mic 9','Mic 10','Mic 11','Mic 13','Mic 14','Mic 15','Mic 16');
    legend('hide');
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('Mic Data (Post CIC Filtering)');
    hold off;
    if (plotbrowser_flag)
        plotbrowser('on');
    else
        plotbrowser('off');
    end
    
    
    
    %---------------------------------------------------------------------%
    %                    Filtering Mic Output Data                        %
    %---------------------------------------------------------------------%
    
    % Initialising arrays
    DC_offsets = zeros(1,length(mic_num));       % Array to store DC offsets
    mic_filtered = zeros(length(mic_num), length(C_mat(1,:)));
    
    % Loading predesigned filters, exported from sptool
    load('\\ad.monash.edu\home\User037\rzou3\Documents\2018 S2\ECE4094 - FYP\Code Documents\Matlab\Optimised Code\Filters\bandpass_40khz.mat','filt1');
    
    % Calculating group delay due to FIR filter
    [gd,f] = grpdelay(filt1.tf.num,filt1.tf.den,1000,50e6/12/14);
    % gd contains lags needed to compensate for 
    lag_comp = mean(gd);
    t_arr_lc = t_arr(1,1:end-(lag_comp-1));
    mic_filt_lc = zeros(length(mic_num), length(t_arr_lc));

    % New figure for filtered signals
    figure; hold on;
    
    % For loop removing the dc component and filter each mic signal
    for counter = 1:length(mic_num)

        % Calculating DC offsets
        DC_offsets(counter) = mean(mic_out(mic_num(counter),:));     

        % Removing dc offsets
        mic_filtered(mic_num(counter),:) = mic_out(mic_num(counter),:) - DC_offsets(counter);

        % Applying bandpass filter
        mic_filtered(mic_num(counter),:) = filter(filt1.tf.num,filt1.tf.den,mic_filtered(mic_num(counter),:));
        %mic_filtered(mic_num(counter),:) = filtfilt(SOS,G, mic_filtered(mic_num(counter),:));
        mic_filt_lc(mic_num(counter),:) = mic_filtered(mic_num(counter),lag_comp:end);

    end
    
    
    
    %---------------------------------------------------------------------%
    %                     Scaling Mic Output Data                         %
    %---------------------------------------------------------------------%
    % Scaling mic output data to ensure all maximums have equal value
    % Calculating max peak across all signals and the max max peak
    max_peak_vector = max(mic_filt_lc,[],2);
    max_peak = max(max_peak_vector);
    scale_vector = max_peak./max_peak_vector;
    scale_vector(isinf(scale_vector)) = 0;          % making inf values zero

    for counter = 1:length(mic_num)
        mic_filt_lc(mic_num(counter),:) = mic_filt_lc(mic_num(counter),:)* scale_vector(mic_num(counter));
        plot(t_arr_lc,mic_filt_lc(mic_num(counter),:));       % plotting filtered and scaled mic signals
    end
    
    % Plotting Transmitter On Pulse Time
    % Scaled by max mic_output amplitude
    plot(t_arr,C_mat(3,:)*max(max(mic_filtered)));
    
    % If statement determining if shold plot patches
    if capture_count ~= 1
        
        % Plotting patches to visualize mic capture windows
        % Using a for loop to create correct number of patch vertices
        % Initialising matrices as empty
        patch_x_vertices = zeros(4,capture_count);
        patch_y_vertices = zeros(4,capture_count);
        patch_color_vec = zeros(capture_count,1);
        for counter = 1:capture_count

            % Patch function has vertices defined in columns
            patch_y_vertices(:,counter) = [-max_peak; -max_peak; max_peak; max_peak];
            patch_x_vertices(:,counter) = [(counter-1)*capture_time_ms/1000; (counter)*capture_time_ms/1000; (counter)*capture_time_ms/1000; (counter-1)*capture_time_ms/1000];

            % Patch colors defined in columns
            % Using if statement to alternate colors
            if mod(counter,2)
                patch_color_vec(counter,1) = 0;
            else
                patch_color_vec(counter,1) = 1;
            end
        end
        
        % Plotting patch
        patch(patch_x_vertices, patch_y_vertices, patch_color_vec, 'FaceAlpha','0.1','EdgeAlpha','0');
        
        % Setting Legend
        eval(sprintf('legend(%s,''Transmitter On'',''Capture Windows'');',my_legend_str));
    else
        eval(sprintf('legend(%s,''Transmitter On'');',my_legend_str));
    end
        
    % Plot labels
    %legend('Mic 1','Mic 2','Mic 3','Mic 5','Mic 6','Mic 7','Mic 8','Mic 9','Mic 10','Mic 11','Mic 13','Mic 14','Mic 15','Mic 16','Transmitter On Time');
    legend('hide')
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('Mic Data (Post Bandpass/Highpass Filtering)');
    hold off;
    if (plotbrowser_flag)
        plotbrowser('on');
    else
        plotbrowser('off');
    end

    %---------------------------------------------------------------------%
    %                    Extracting Upper Envelopes                       %             
    %---------------------------------------------------------------------%
    % For loop calculating the upper envelope of each signal

    % Matrix initialisations
    mic_up_env = zeros(length(mic_num),length(mic_filt_lc(1,:)));
    mic_lo_env = zeros(length(mic_num),length(mic_filt_lc(1,:)));

    for counter = 1:length(mic_num)

        % Calculating envelopes for all mics (including zero output mics)
        [mic_up_env(mic_num(counter),:),mic_lo_env(mic_num(counter),:)] = envelope(mic_filt_lc(mic_num(counter),:));  

    end

    % Plotting Mic envelopes
    figure;
    plot(t_arr_lc,mic_up_env);
    legend('Mic 1','Mic 2','Mic 3','Mic 4','Mic 5','Mic 6','Mic 7','Mic 8','Mic 9','Mic 10','Mic 11','Mic 12','Mic 13','Mic 14','Mic 15','Mic 16');
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('Upper Mic Envelopes (Post Filtering)');
    if (plotbrowser_flag)
        plotbrowser('on');
    else
        plotbrowser('off');
    end
    
end




