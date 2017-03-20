function MimSave(file_path, filename_base, image_data, compression, reporting)
    % MimSave. Saves an image or a structure containing images, with compression support
    %
    %    MimSave allows you to save a structure as a .mat file, where every
    %    PTKImage in the structure has its raw data saved as a separate
    %    .raw file, with compression if supported. Use MimLoad to reload
    %    the structure.
    %
    %     Syntax
    %     ------
    %
    %         MimSave(file_path, filename_base, image_data, compression, reporting)
    %
    %             file_path       specify the location to save the files.
    %             filename_base   specify the file prefix. Suffixes will be
    %                             added automatically. A single header file
    %                             will be saved for the structure or image,
    %                             and a separate raw image file will be
    %                             created for each image in the structure
    %             image_data      is a PTKImage (or PTKDicomImage) class containing the image
    %                             to be saved, or a structure which could
    %                             contain one or more PTKImages
    %             compression     the compression to use when saving the
    %                             raw data in PTKImage files
    %             reporting       an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %            
    
    result = ConvertStructAndSaveRawImageData(image_data, file_path, filename_base, 0, compression, reporting);
    filename = [fullfile(file_path, filename_base) '.mat'];
    MimDiskUtilities.Save(filename, result);
end

function [new_structure, next_index] = ConvertStructAndSaveRawImageData(old_structure, file_path, filename_base, next_index, compression, reporting)
    if isstruct(old_structure)
        new_structure = struct;
        field_names = fieldnames(old_structure);
        for field = field_names'
            field_name = field{1};
            [new_structure.(field_name), next_index] = ConvertStructAndSaveRawImageData(old_structure.(field_name), file_path, filename_base, next_index, compression, reporting);
        end
    else
        if isa(old_structure, 'PTKImage')
            reporting.LogVerbose(['Saving raw image data for ' filename_base]);
            if next_index == 0
                file_suffix = '';
            else
                file_suffix = ['_' int2str(next_index)];
            end
            raw_image_file_name = [filename_base file_suffix '.raw'];
            
            if (length(size(old_structure.RawImage)) ~= 3) || (~MimDiskUtilities.CompressionSupported(compression, class(old_structure.RawImage), reporting))
                % Compression currently only supports 3D images
                compression = [];
            end
            
            % Create a header file if requested. The header is the image object
            % minus the raw image data, and contains the raw image filename
            header = old_structure.CreateHeader(raw_image_file_name, compression);
            
            % Save the pixel data with compression, if supported
            CoreSaveRawImage(old_structure.RawImage, file_path, raw_image_file_name, compression, reporting);
            
            next_index = next_index + 1;
            new_structure = header;
        else
            new_structure = old_structure;
        end
    end
end


