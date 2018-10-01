% This code is written by Roger Zou (Student ID: 26029901)
% Last Modified 18.09.2018
%
% ANG_CALC_FUNC - calculates the bearing to objects detected using the
%                 dist_calc_func
%
% Usage [ori_mic phase_array phase_array_wrap_adj plane_pts az_el_ang] = dist_calc_func(mic_num, t_arr_lc, mic_filt_lc, mic_mapping, tof_est, mic_half_amp_index, plot_flag)
%
% This code takes the half amplitude index readings given by the distance
% calculation function and uses phase comparisons to determine the bearing
% of the object.
%
%
% Methodology
% Step 1:   Determine how many objects were detected based on the distance
%           half amplitude index readings (number of columns), loop based
%           on this count
% Step 2:   Extract the column of half index readings and process data from
%           this
% Step 3:   Based on time of flight estimates determine which mic will be
%           used as origin mic, ie. the one which received the signal first
% Step 4:   Calculate phase differences for 4x4 array next to origin mic
% Step 5:   Determine if need to adjust for wrap around vertically or
%           horizontally based on above phase readings from 3x3 array
% Step 6:   Adjust for wrap around accordingly
% Step 7:   Convert phase differences into points on the incoming plane
%           wave
% Step 8:   Fit a plane of best fit to incoming plane wave
% Step 9:   Calculate normal to plane and determing azimuth angle and
%           elevation angle
%
% Input Arguments
%   mic_num       - Vector defining which mics are in use/recorded by the
%                   signal tap in Quartus
%   t_arr_lc      - The array holding the time values, after compensating 
%                   for the lag introduced by the filter 
%   mic_filt_lc   - Array holding filtered mic signals, lag compensated
%   mic_mapping   - Array that defines how the mics are physically
%                   arranged
%   tof_est       - The estimated time of flights to each object for each
%                   mic
%   mic_half_amp_index - Index locations in mic_filt_lc of each half
%                   amplitude point of each peak detected
%   sig_samp_length    - Input that determines how long the signal sample
%                   that is used to calculate phase difference is, in ms
%   threshold_plane    - Defining threshold for inliers, used in 
%                        RANSACFITPLANE function
%   plot_flag     - Flag used to determine if want to plot 3d planes
%
% Output Arguments
%   ori_mic_vec   - The mic used as the origin phase for each object
%                   detected
%   phase_array   - Array containing the phase differences calculated for
%                   each object
%   phase_array_wrap_adj - As above, but adjusted for wrap around problem
%                   associated with phase calculation
%   plane_pts     - The points on the arriving planes, extrapolated from
%                   phase_array_wrap_adj, (z values only)
%   az_el_ang     - Array containing the azimuth angle and elevation angle
%                   estimated for each object, first row is the azimuth
%                   angles and the second angle is the elevation angles

function [ori_mic_vec, phase_array, phase_array_wrap_adj, plane_pts, az_el_ang] = ang_calc_func(mic_num, t_arr_lc, mic_filt_lc, mic_mapping, tof_est, mic_half_amp_index, sig_samp_length, threshold_plane, plot_flag)
    
    %---------------------------------------------------------------------%
    %                     OUTER LOOP FOR EACH OBECT                       %
    %---------------------------------------------------------------------%
    % Determining how many object detected, loop code this number of times
    % Starting at 2 to account for transmit pulse
    fprintf('\n\t---------------------------------------------------------------------------------\n');
    fprintf('\t\t\t\t\t\t\t\t\tBEARING READINGS');
    fprintf('\n\t---------------------------------------------------------------------------------\n\n');
    
    % Initialsing output arrays
    ori_mic_vec = zeros(1, size(tof_est,2));
    phase_array = zeros(16, size(tof_est,2));
    phase_array_wrap_adj = zeros(16, size(tof_est,2));
    plane_pts = zeros(16, size(tof_est,2));
    az_el_ang = zeros(2, size(tof_est,2)-1);
    
    % Plot variables and setup
    mic_dist = 0.00415;         % mic seperation distance
    plane_y_val = (ones(4,1)*[0,-mic_dist,-2*mic_dist,-3*mic_dist])';       % y values of mics
    plane_x_val = ones(4,1)*[0,mic_dist,2*mic_dist,3*mic_dist];             % x values of mics
    if (plot_flag)
        figure;     % creating figure for plots if plot flag is 1
        set(gcf, 'Position', [500, 300, 900, 550])
    end
    
    
    for counter = 2:(size(mic_half_amp_index, 2))
        
        % Print statements for each object
        fprintf('\tThe bearing readings to OBJECT %g are:\n',counter-1);
        
        %-----------------------------------------------------------------%
        %                     EXTRACTING INDEXES                          %
        %-----------------------------------------------------------------%
        % Extracting tof estimates and half amplitude indexes to use
        tof_est_vec = tof_est(:,counter);
        half_amp_index = mic_half_amp_index(:,counter);
        
        
        %-----------------------------------------------------------------%
        %                   DETERMINING ORIGIN MIC                        %
        %-----------------------------------------------------------------%
        % First step is to place the time of flight readings into array
        % based on the mapping of the microphones
        tof_mic_mapped = tof_est_vec(mic_mapping);
        
        % Replacing all 0s with NaN to be able to use inbuilt matlab mean
        % while exclading nan's, ie. way of excluding zeros from mean
        tof_mic_mapped(tof_mic_mapped==0) = NaN;
        
        % Assign top left as origin if 0,0
        % Assign top right as origin if 0,1
        % Assign bottom left as origin if 1,0
        % Assign bottom right as origin if 1,1
        % Using two flags to determine if average from top/bottom,
        % left/right, in position 1 or 4
        row_flag = 1;
        col_flag = 1;
        if (mean(tof_mic_mapped(:,1),'omitnan') > mean(tof_mic_mapped(:,4),'omitnan'))
            % Column flag set to one if plane wave hits mic array on the
            % right hand side first, else stays as zero
            col_flag = 4;
        end
        
        if (mean(tof_mic_mapped(1,:),'omitnan') > mean(tof_mic_mapped(4,:),'omitnan'))
            % Row flag set to one if plane wave hits mic array from the
            % bottom first, else stays as zero
            row_flag = 4;
        end
        
        % Finding origin mic number and placing in origin mic array
        ori_mic = mic_mapping(row_flag,col_flag);
        ori_mic_vec(1, counter) = ori_mic;
        
        
        %-----------------------------------------------------------------%
        %        EXTRACTING SIGNALS AND COMPUTING PHASE DIFFERENCE        %
        %-----------------------------------------------------------------%
        % Extracting the signals at the correct half amplitude point and
        % computing the phase difference compared against the origin mic
        % Input signal sample length in milliseconds -> convert to number
        % of samples
        samp_length = round((sig_samp_length/1000)/t_arr_lc(2));
        
        % Extracting origin mic sample
        samp_start_ind = half_amp_index(ori_mic);           % starting point of samples defined by origin mic half amplitude point
        signal_a = mic_filt_lc(ori_mic, (samp_start_ind:samp_start_ind + samp_length));
        
        % For loop moving through mic signals and comparing them against
        % origin mic signal to calculate phase
        for counter_2 = 1:16
            
            % Extracting signal b
            signal_b = mic_filt_lc(counter_2, (samp_start_ind:samp_start_ind + samp_length));
            
            % Insert breakpoint at end of this for loop to plot signals
            % figure; plot(signal_a); hold on; plot(signal_b)
            
            % Calculating phase difference using dot product
            % Dot product approximates the phase difference between sin waves
            dot_product = dot(signal_a,signal_b);
            norm_product = (norm(signal_a)*norm(signal_b));
            phase_shift = acosd(dot_product/norm_product);
            
            % Placing phase shift in phase shift array
            phase_array(counter_2,counter) = phase_shift;
            
        end
        
        % Converting to visual mic mapping
        phase_array_vector = phase_array(:,counter);                %% CHANGE PHASE ARRAY TO WRAP AROUND ADJUSTED PHASE ARRAY AFTER FIXING
        phase_shift_visual = phase_array_vector(mic_mapping);
        phase_shift_visual = real(phase_shift_visual);

        %-----------------------------------------------------------------%
        %                DEALING WITH WRAP AROUND ISSUE                   %
        %-----------------------------------------------------------------%
        % Dealing with the wrap around that exists due to dot product phase
        % calculations. ie. when the phase difference between two waveforms
        % is greater than 180 degrees, the result reported should be
        % 360-calculated phase difference. To accomplish this dynamically
        % need to first determine if expected phase would be above 180
        % based on other mic readings in the array
        
        % Wrap around checks differ depending on which mic is the origin
        % mic, ie. if origin mic is in position (1,1) need to check if
        % issue in column 4 and row 4
        % Use two different if statements to determine which checks to do
        
        %---------------------ROW WRAP AROUND CHECK-----------------------%
        % Row wrap around check
        if (row_flag == 1)
             
            % If mic origin in row 1, check for wrap-around effect in row 4
            for counter_2 = 1:4
                
                % If statement checking if wrap around effect
                % potentially present in current row, across columns
                % Need to extract third column value and test if
                % greater than 100
                row_3_val = phase_shift_visual(3,counter_2);
                
                % If row_val_3 is NaN extrapolate from 2nd column value,
                % assuming linear gradient
                if (isnan(row_3_val))
                    row_3_val = 2*phase_shift_visual(counter_2,2);
                end
                
                % If statement if col_3_val greater than 100, then wrap
                % around affect potentially present, adjust accordingly
                if (row_3_val > 100)
                    
                    % Checking each row to see if wrap around issue exists
                    % Calculating gradient between mic readings
                    grad_1 = phase_shift_visual(2,counter_2) - phase_shift_visual(1,counter_2);
                    grad_2 = phase_shift_visual(3,counter_2) - phase_shift_visual(2,counter_2);

                    % Placing in gradient vector and determining average sign
                    % across the array
                    grad_vector = [grad_1, grad_2];
                    grad_vector = sign(grad_vector);
                    grad_sign = mean(grad_vector,'omitnan');

                    % If grad_sign is NaN, make assumption that sign is +ve
                    if (isnan(grad_sign))
                        grad_sign = 1;
                    end

                    % Calculating gradient between last column, with and
                    % without wrap around adjustment
                    grad_3 = phase_shift_visual(4,counter_2) - phase_shift_visual(3,counter_2);
                    if (isnan(grad_3))
                        % If the entry is NaN need to recalculate gradient
                        % Approximate empty entry as twice of entry next to it
                        grad_3 = (phase_shift_visual(1,counter_2) - 2*phase_shift_visual(3,counter_2));
                    end

                    % Determining if wrap around exists
                    wrap_flag = 0;          % no wrap around initially assumed
                    if (sign(grad_3) ~= sign(grad_sign))

                        % If gradient better for wrap around adjustment, wrap
                        % around exists, therefore set wrap flag =1
                        wrap_flag = 1;

                    end

                    % If wrap flag on
                    if (wrap_flag)
                        % Adjusting reading in phase_shift_array_visual
                        phase_shift_visual(4,counter_2) = 360 - phase_shift_visual(4,counter_2);
                    end
                end      
            end
            
        else
            
            % If row flag not in 1, origin mic is in row 4, need to
            % detect wrap around in row 1
            % If mic origin in row 4, check for wrap-around effect in row 1
            for counter_2 = 1:4

                % If statement checking if wrap around effect
                % potentially present in current row, across columns
                % Need to extract third column value and test if
                % greater than 100
                row_2_val = phase_shift_visual(2,counter_2);
                
                % If col_val_3 is NaN extrapolate from 2nd column value,
                % assuming linear gradient
                if (isnan(row_2_val))
                    row_2_val = 2*phase_shift_visual(3,counter_2);
                end
                
                % If statement if col_3_val greater than 100, then wrap
                % around affect potentially present, adjust accordingly
                if (row_2_val > 100)
                
                    % Checking each row to see if wrap around issue exists
                    % Calculating gradient between mic readings
                    grad_1 = phase_shift_visual(3,counter_2) - phase_shift_visual(4,counter_2);
                    grad_2 = phase_shift_visual(2,counter_2) - phase_shift_visual(3,counter_2);

                    % Placing in gradient vector and determining average sign
                    % across the array
                    grad_vector = [grad_1, grad_2];
                    grad_vector = sign(grad_vector);
                    grad_sign = mean(grad_vector,'omitnan');
                    
                    % If grad_sign is NaN, make assumption that sign is +ve
                    if (isnan(grad_sign))
                        grad_sign = 1;
                    end
                    
                    % Calculating gradient for first column
                    grad_3 = phase_shift_visual(1,counter_2) - phase_shift_visual(2,counter_2);
                    if (isnan(grad_3))
                        % If the entry is NaN need to recalculate gradient
                        % Approximate empty entry as twice of entry next to it
                        grad_3 = (phase_shift_visual(1,counter_2) - 2*phase_shift_visual(3,counter_2));
                    end
                    
                    
                    % Determining if wrap around exists
                    wrap_flag = 0;          % no wrap around initially assumed
                    if (sign(grad_3) ~= sign(grad_sign))

                        % If gradient better for wrap around adjustment, wrap
                        % around exists, therefore set wrap flag = 1
                        wrap_flag = 1;

                    end

                    % If wrap flag on
                    if (wrap_flag)
                        % Adjusting reading in phase_shift_array_visual
                        phase_shift_visual(1,counter_2) = 360 - phase_shift_visual(1,counter_2);
                    end
                end
            end
        end    
        %-------------------END ROW WRAP AROUND CHECK---------------------%
        
        
        %------------------COLUMN WRAP AROUND CHECK-----------------------%
        % Column wrap around check
        if (col_flag == 1)
             
            % If mic origin in col 1, check for wrap-around effect in col 4
            for counter_2 = 1:4
                
                % If statement checking if wrap around effect
                % potentially present in current row, across columns
                % Need to extract third column value and test if
                % greater than 100
                col_3_val = phase_shift_visual(counter_2,3);
                
                % If col_val_3 is NaN extrapolate from 2nd column value,
                % assuming linear gradient
                if (isnan(col_3_val))
                    col_3_val = 2*phase_shift_visual(counter_2,2);
                end
                
                % If statement if col_3_val greater than 100, then wrap
                % around affect potentially present, adjust accordingly
                if (col_3_val > 100)
                    
                    % Checking each row to see if wrap around issue exists
                    % Calculating gradient between mic readings
                    grad_1 = phase_shift_visual(counter_2,2) - phase_shift_visual(counter_2,1);
                    grad_2 = phase_shift_visual(counter_2,3) - phase_shift_visual(counter_2,2);

                    % Placing in gradient vector and determining average sign
                    % across the array
                    grad_vector = [grad_1, grad_2];
                    grad_vector = sign(grad_vector);
                    grad_sign = mean(grad_vector,'omitnan');

                    % If grad_sign is NaN, make assumption that sign is +ve
                    if (isnan(grad_sign))
                        grad_sign = 1;
                    end

                    % Calculating gradient between last column, with and
                    % without wrap around adjustment
                    grad_3 = phase_shift_visual(counter_2,4) - phase_shift_visual(counter_2,3);
                    if (isnan(grad_3))
                        % If the entry is NaN need to recalculate gradient
                        % Approximate empty entry as twice of entry next to it
                        grad_3 = (phase_shift_visual(counter_2,1) - 2*phase_shift_visual(counter_2,3));
                    end

                    % Determining if wrap around exists
                    wrap_flag = 0;          % no wrap around initially assumed
                    if (sign(grad_3) ~= sign(grad_sign))

                        % If gradient better for wrap around adjustment, wrap
                        % around exists, therefore set wrap flag =1
                        wrap_flag = 1;

                    end

                    % If wrap flag on
                    if (wrap_flag)
                        % Adjusting reading in phase_shift_array_visual
                        phase_shift_visual(counter_2,4) = 360 - phase_shift_visual(counter_2,4);
                    end
                end      
            end
            
        else
            
            % If column flag not in 1, origin mic is in column 4, need to
            % detect wrap around in column 1
            % If mic origin in col 4, check for wrap-around effect in col 4
            for counter_2 = 1:4

                % If statement checking if wrap around effect
                % potentially present in current row, across columns
                % Need to extract third column value and test if
                % greater than 100
                col_2_val = phase_shift_visual(counter_2,2);
                
                % If col_val_3 is NaN extrapolate from 2nd column value,
                % assuming linear gradient
                if (isnan(col_2_val))
                    col_2_val = 2*phase_shift_visual(counter_2,3);
                end
                
                % If statement if col_3_val greater than 100, then wrap
                % around affect potentially present, adjust accordingly
                if (col_2_val > 100)
                
                    % Checking each row to see if wrap around issue exists
                    % Calculating gradient between mic readings
                    grad_1 = phase_shift_visual(counter_2,3) - phase_shift_visual(counter_2,4);
                    grad_2 = phase_shift_visual(counter_2,2) - phase_shift_visual(counter_2,3);

                    % Placing in gradient vector and determining average sign
                    % across the array
                    grad_vector = [grad_1, grad_2];
                    grad_vector = sign(grad_vector);
                    grad_sign = mean(grad_vector,'omitnan');
                    
                    % If grad_sign is NaN, make assumption that sign is +ve
                    if (isnan(grad_sign))
                        grad_sign = 1;
                    end
                    
                    % Calculating gradient for first column
                    grad_3 = phase_shift_visual(counter_2,1) - phase_shift_visual(counter_2,2);
                    if (isnan(grad_3))
                        % If the entry is NaN need to recalculate gradient
                        % Approximate empty entry as twice of entry next to it
                        grad_3 = (phase_shift_visual(counter_2,1) - 2*phase_shift_visual(counter_2,3));
                    end
                    
                    
                    % Determining if wrap around exists
                    wrap_flag = 0;          % no wrap around initially assumed
                    if (sign(grad_3) ~= sign(grad_sign))

                        % If gradient better for wrap around adjustment, wrap
                        % around exists, therefore set wrap flag = 1
                        wrap_flag = 1;

                    end

                    % If wrap flag on
                    if (wrap_flag)
                        % Adjusting reading in phase_shift_array_visual
                        phase_shift_visual(counter_2,1) = 360 - phase_shift_visual(counter_2,1);
                    end
                end
            end
        end     
        %------------------END COLUMN WRAP AROUND CHECK-------------------%
        
        % Placing corrected phase shifts into adjust phase array
        % Moving phase shift visual values into array based on mic mapping
        % array
        for counter_2 = 1:16
            phase_array_wrap_adj(mic_mapping(counter_2),counter) = phase_shift_visual(counter_2);
        end
        
        % Changing NaNs to 0s
        phase_array_wrap_adj(isnan(phase_array_wrap_adj)) = 0;
        
        
        %-----------------------------------------------------------------%
        %              EXTRACTING Z VALUES OF PLANE POINTS                %
        %-----------------------------------------------------------------%
        % Extracting phase vector and converting to z values of arrival
        % plane. Phase shifts represent time delay between arrival times of 
        % the propogating plane wave.
        % Therefore, to convert phase shifts to time difference, need to compare
        % phase time against total period time ie: 360/(1/40000)=phi/time_diff
        % time_diff = phi/(40000*360)
        % The conversion to z values is made by multiplying by the speed of
        % sound
        phase_array_vector = phase_array_wrap_adj(:,counter);                %% CHANGE PHASE ARRAY TO WRAP AROUND ADJUSTED PHASE ARRAY AFTER FIXING
        arr_time_diff_arr_vec = phase_array_vector/(40000*360);
        plane_z_val_vec = arr_time_diff_arr_vec*343;
        plane_z_val_vec(isnan(plane_z_val_vec)) = 0;
        
        % Placing z value vector into plane points output
        plane_pts(:,counter) = plane_z_val_vec;
        
        % Converting plane_z_val_vec into correct mic mapping
        plane_z_val = plane_z_val_vec(mic_mapping);
        
        %-----------------------------------------------------------------%
        %              PLANE FITTING USING RANSACFITPLANE                 %
        %-----------------------------------------------------------------%
        % Defining plane as 3xN array
        point_select_vec = [1:6,7,8,9:16];      % need vector to convert arrays to vectors
        XYZ_1 = [plane_x_val(point_select_vec)',plane_y_val(point_select_vec)',plane_z_val(point_select_vec)'];

        % Defining threshold for inliers, used in RANSACFITPLANE function
        % threshold_plane = 0.001; 
        % Defined by function input
        
        % Using Ransac Fit Plane Function
        [B, P, inliers] = ransacfitplane(XYZ_1', threshold_plane, 0);
        
        % Defining Points on the Plane
        [x, y] = meshgrid(0:mic_dist*3/2:mic_dist*3,0:-mic_dist*3/2:-mic_dist*3);
        z_plane_wave = -1/B(3)*(B(1)*x + B(2)*y + B(4));                % Z values on the plane found by solving plane equation Ax +By +Cd +D = 0
        
        % Calculating Normal to the plane
        [Nx,Ny,Nz] = surfnorm(x,y,z_plane_wave,'FaceAlpha',0.5,'FaceColor',[1,0.3737,0.33]);        % Extracting surface normals
        
        
        %-----------------------------------------------------------------%
        %   CALCULATING AZIMUTH AND ELEVATION ANGLES FROM PLANE NORMALS   %
        %-----------------------------------------------------------------%
        % Using the plane normals calculated above to determine azimuth and
        % elevation angles
        % Angles found by using trigonometry with mic plane and normal vector

        % Horizontal Angle -> Azimuth
        az_angle = atand(abs(Nx(1,1))/abs(Nz(1,1)));            % finding absolute angle
        
        % Determining whether object is to the left or right of the normal
        % If it is left the angle is -ve, if it is right the angle is
        % positive
        if Nx(1,1) > 0
            % Plane is approaching from the left side if Nx(1,1) > 0
            az_angle = -az_angle;
        end
        
        % Vertical Angle -> Elevation
        el_angle = atand(abs(Ny(1,1))/abs(Nz(1,1))); % finding absolute angle

        % Determining whether plane is coming from above or below
        if Ny(1,1) > 0
            % Plane is approacing from below if Nt(1,1) > 0
            el_angle = -el_angle;
        end
        
        % Placing angles into output array
        az_el_ang(1,counter-1) = az_angle;
        az_el_ang(2,counter-1) = el_angle;
        
        %-----------------------------------------------------------------%
        %                       PLOTTING RESULTS                          %
        %-----------------------------------------------------------------%
        % Plotting 3D figures if plot flag on
        if (plot_flag)
            
            % Defining subplot to plot to, -1 due to transmit pulse
            subplot(1, (size(tof_est,2)-1),counter-1);
            
            % Plotting points in space
            scatter3(plane_x_val(point_select_vec),plane_y_val(point_select_vec),plane_z_val(point_select_vec),'filled')
            axis equal;         % Setting axis as normal
            title_string = sprintf('3D Plot of Incoming Plane Wave for Object %g',counter-1);
            title(title_string);
            hold on;
            
            % Plotting mic plane
            [x, y] = meshgrid(0:mic_dist:mic_dist*3,0:-mic_dist:-mic_dist*3); % Generate x and y data
            z = zeros(size(x, 1)); % Generate z data
            surf(x, y, z, 'FaceColor',[0 0.7 1],'FaceAlpha',0.7);
            
            % Plotting fitted plane
            [x, y] = meshgrid(0:mic_dist*3/2:mic_dist*3,0:-mic_dist*3/2:-mic_dist*3);
            surf(x,y,z_plane_wave,'FaceAlpha',0.5,'FaceColor',[1,0.3737,0.33]);
            
            % Plotting normal from mic plane
            plot3(mic_dist*3/2,-mic_dist*3/2,0,'bo','markersize',15,'markerfacecolor','blue','HandleVisibility','off');
            norm_div_scale = 400;           % scaling normal vector to graph
            quiver3(mic_dist*3/2,-mic_dist*3/2,0,0,0,1/norm_div_scale,'b','linewidth',2)
            
            % Plotting point at middle of the fitted plane and normal
            plot3(mic_dist*3/2,-mic_dist*3/2,-1/B(3)*(B(1)*mic_dist*3/2 + B(2)*-mic_dist*3/2 + B(4)),'ro','markersize',15,'markerfacecolor','red','HandleVisibility','off');
            quiver3(mic_dist*3/2,-mic_dist*3/2,-1/B(3)*(B(1)*mic_dist*3/2 + B(2)*-mic_dist*3/2 + B(4)),Nx(1,1)/norm_div_scale,Ny(1,1)/norm_div_scale,Nz(1,1)/norm_div_scale,'r','linewidth',2)
            
            hold off;
            
        end
        
        
        %-----------------------------------------------------------------%
        %                      PRINTING RESULTS                           %
        %-----------------------------------------------------------------%
        fprintf('\tAzimuth Angle Estimated -> %.3g degrees\n', az_el_ang(1,counter-1));
        fprintf('\tElevation Angle Estimated -> %.3g degrees\n', az_el_ang(2,counter-1));
        fprintf('\tThe phase shifts calculated with Mic %g as the origin is:\n\n',ori_mic);
        disp(uint16(phase_shift_visual));
        
        
    end
    
    % Inserting legend on 3D plots after loop so only appears on one graph
    if (plot_flag)
        % Naming Legend
        legend('Plane Points','Mic Plane','Fitted Plane','Normal to Mic Plane','Normal to Incident Plane','Location','bestoutside');
    end
    
end