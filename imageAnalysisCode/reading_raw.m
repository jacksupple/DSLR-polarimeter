%% Process RAW image with dcraw
% This code requires you have DCRAW application by Dave Coffin:
%       https://www.dechifro.org/dcraw/
% Based on https://www.rcsumner.net/raw_guide/RAWguide.pdf

function [black, saturation, wb_multipliers] = reading_raw(image_path,image_name,raw_ext,dcraw_path)

    % First get information about the image from dcraw
    command = ['"',fullfile(dcraw_path,'dcraw.exe'),'" -v -w -T "',fullfile(image_path,[image_name,raw_ext]),'"'];
    [~,cmdout] = system(command);

    % Extract image information from cmd output from first dcraw run
    cmdout_parts    = strsplit(cmdout,[" ",","]);
    % get the black value
    black_ind       = find(strcmp(cmdout_parts,'darkness'))+1;
    black           = str2num(cmdout_parts{black_ind});
    clearvars black_ind
    % get the white value
    saturation_ind	= find(strcmp(cmdout_parts,'saturation'))+1;
    saturation   	= str2num(cmdout_parts{saturation_ind});
    clearvars saturation_ind
    % get the white balance multipliers
    RGBscale_ind    = find(cellfun(@(x) ~isempty(x),strfind(cmdout_parts,'multipliers')),1)+[1 2 3];
    wb_multipliers	= cellfun(@(x) str2num(x),cmdout_parts(RGBscale_ind));
    clearvars RGBscale_ind

    % Next call dcraw to generate a 16 bit per pixel TIFF file
    %   -4 : writes linear 16-bit, unbrightened and un-gamma-corrected image, same as ‘-6 -W -g 1 1’
    %   -D : Foregoes demosaicing
    %   -T : Writes to TIFF file instead of PPM
    command = ['"',fullfile(dcraw_path,'dcraw.exe'),'" -4 -D -T "',fullfile(image_path,[image_name,raw_ext]),'"'];
    system(command)

end


