function image_data = MimLoad(file_path, filename_base, reporting)
    % MimLoad. Loads an image or a structure previously saved with MimSave
    %
    %    MimLoad allows you to load a structure from .mat and .raw files
    %    that have previously been saved using MimSave. MimLoad will
    %    decompress the images and combine into a single structure or image
    %    that matches the original image or structure saved.
    %
    %     Syntax
    %     ------
    %
    %         image_data = MimLoad(file_path, filename_base, reporting)
    %
    %             file_path       specify the location to save the files.
    %             filename_base   specify the file prefix. Suffixes will be
    %                             added automatically. A single header file
    %                             will be saved for the structure or image,
    %                             and a separate raw image file will be
    %                             created for each image in the structure
    %             reporting       an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %             image_data      is a PTKImage (or PTKDicomImage) class containing the image
    %                             to be saved, or a structure which could
    %                             contain one or more PTKImages
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %            
    
    filename = [fullfile(file_path, filename_base) '.mat'];
    results_struct = MimDiskUtilities.Load(filename);
    image_data = ConvertStructAndLoadRawImageData(results_struct, file_path, filename_base, reporting);
end

function new_structure = ConvertStructAndLoadRawImageData(old_structure, file_path, filename_base, reporting)
    if isstruct(old_structure)
        field_names = fieldnames(old_structure);
        new_structure = struct;
        for field = field_names'
            field_name = field{1};
            new_structure.(field_name) = ConvertStructAndLoadRawImageData(old_structure.(field_name), file_path, filename_base, reporting);
        end
    else
        new_structure = old_structure;
        if isa(old_structure, 'PTKImage')
            if ~old_structure.IsRawImageLoaded
                raw_image = CoreLoadRawImage(file_path, old_structure.CachedRawImageFilename, old_structure.CachedDataType, old_structure.CachedImageSize, old_structure.CachedRawImageCompression, reporting);
                old_structure.LoadCachedRawImage(raw_image);
            end
        end
    end
end


        
   