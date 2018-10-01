% This code is written by Roger Zou (Student ID: 26029901)
% Last Modified 12.09.2018
%
% TEXT_PROCESSING_FUNCTION - reads in table data and outputs it in a matrix
%
% Usage C_mat = text_processing_func(filename,filepath, row_count, filename_endnumber)
%
% This code reads in data stored in a table and outputs the relevant data
% into a matrix. Additional functionality includes ability to read in
% different files differentiated by their ending numbers.
%
% Input Arguments
%   filename - String containing the file name to be read in
%   filepath - String containing the pathway to the file on the computer
%   row count - number of rows to be read in from the table file
%   file_name_endnumber - Optional input to be used if multiple files to be
%                         read in
% 
% Output Arguments
%   C_mat - Matrix form output of table data read in

function C_mat = text_processing_func(filename,filepath, col_count, filename_endnumber)
    
    % Setting filename_endnumber to empty array if no input
    if nargin == 3
        filename_endnumber = 1;
    end
    
    % Determining file string used in file read
    file_loc = sprintf('%s%s%s%i.tbl',filepath,'\',filename',filename_endnumber);
    
    % Reading in table file
    C = fileread(file_loc);
    
    %---------------------------------------------------------------------%
    
    % Processing table data
    % Searching for the location of decimal points
    % Needed to clear text at the beginning of the character array
    decimal_index = strfind(C,'.');

    % Note: First two decimals are full stops in sentences, therefore, take the
    % fourth index and remove data beforehand (also remove first line of XXXX)
    array_start_index = decimal_index(4) - 14;       % subtract 15 to give characters before start of the line

    % Take array out of file
    C_array = C(1,array_start_index:end);

    % Removing greater than signs
    C_array = C_array(C_array ~= 62);       % ASCI for > is 62

    % Removing equal signs
    C_array = C_array(C_array ~= 61);       % ASCI for = is 61

    % Removing decimal point
    C_array = C_array(C_array ~= 46);       % ASCI for . is 46
    
    % Extracting mic and transmission pulse data
    C_mat_hold = sscanf(C_array, '%x',  [col_count+2, inf]);         % +2 to column count due to first index values
    C_mat_hold = C_mat_hold(:,1:2:end-1);           % extracting every second column, getting rid of last 0s
    
    % Outputting Matrix
    C_mat = C_mat_hold;
    
end