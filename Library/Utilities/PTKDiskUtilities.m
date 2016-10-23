classdef PTKDiskUtilities
    % PTKDiskUtilities. Disk-related utility functions.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)
        
        function [filename, path_name, save_type] = SaveImageDialogBox(path_name)
            % Dialog for exporting a 2D image
            filespec = {...
                '*.tif', 'TIF (*.tif)';
                '*.jpg', 'JPG (*.jpg)';
                };
            
            if isempty(path_name) || ~ischar(path_name) || exist(path_name, 'dir') ~= 7
                path_name = '';
            end
            
            [filename, path_name, filter_index] = uiputfile(filespec, 'Save image as', fullfile(path_name, ''));
            switch filter_index
                case 1
                    save_type = 'tif';
                case 2
                    save_type = 'jpg';
                otherwise
                    save_type = [];
            end
            
        end

        function [is_meta_header, raw_filename] = IsFileMetaHeader(header_filename, reporting)
            meta_header = PTKDiskUtilities.ReadMetaHeader(header_filename, reporting);
            if (~isempty(meta_header)) && isfield(meta_header, 'ElementDataFile')
                is_meta_header = true;
                raw_filename = meta_header.ElementDataFile;
            else
                is_meta_header = false;
                raw_filename = [];
            end
        end
        
        function meta_header = ReadMetaHeader(header_filename, reporting)
            file_id = fopen(header_filename);
            if (file_id <= 0)
                reporting.Error('PTKDiskUtilities:OpenFileFailed', ['Unable to open file ' header_filename]);
            end
            
            try
                % Reads in the meta header data: meta_header_data{1} are the field names,
                % meta_header_data{2} are the values
                meta_header_data = strtrim(textscan(file_id, '%s %s', 'delimiter', '='));
            catch exc
                fclose(file_id);
                meta_header = [];
                return;
            end
            fclose(file_id);
            
            meta_header = [];
            
            data_filename_index = find(ismember(meta_header_data{1}, 'ElementDataFile'));
            if ~isempty(data_filename_index)
                values_array = meta_header_data{2};
                data_filename = values_array{data_filename_index};
                if strcmp(data_filename, 'LOCAL')
                    reporting.ShowWarning('PTKDiskUtilities:LocalDataNotSupported', 'PTK does not currently support image files with data embedded in the same file as the metaheader.');
                    meta_header = [];
                    return;
                end
            end
            
            
            for index = 1 : length(meta_header_data{1});
                meta_header.(genvarname(meta_header_data{1}{index})) = meta_header_data{2}{index};
            end
        end
        
        function [image_type, principal_filename, secondary_filenames] = GuessFileType(image_path, image_filename, default_guess, reporting)
            [~, name, ext] = fileparts(image_filename);
            if strcmp(ext, '.mat')
                image_type = PTKImageFileFormat.Matlab;
                principal_filename = {image_filename};
                secondary_filenames = {};
                return;

            % For metaheader files (mhd/mha) we also fetch the filename of the
            % raw image data
            elseif strcmp(ext, '.mhd') || strcmp(ext, '.mha')
                image_type = PTKImageFileFormat.Metaheader;
                [is_meta_header, raw_filename] = PTKDiskUtilities.IsFileMetaHeader(fullfile(image_path, image_filename), reporting);
                if ~is_meta_header
                    reporting.Error('PTKDiskUtilities:OpenMHDFileFailed', ['Unable to read metaheader file ' image_filename]);
                end
                principal_filename = {image_filename};
                secondary_filenames = {raw_filename};
                return;
                
            % If a .raw file is selected, look for the corresponding .mha or
            % .mhd file. We thrown an exception if no file is found, it cannot
            % be loaded or the raw filename does not match the raw file we are
            % loading
            elseif strcmp(ext, '.raw')
                [principal_filename, secondary_filenames] = PTKDiskUtilities.GetHeaderFileFromRawFile(image_path, name, reporting);
                if isempty(principal_filename)
                    reporting.ShowWarning('PTKDiskUtilities:HeaderFileLoadError', ['Unable to find valid header file for ' fullfile(image_path, image_filename)], []);
                else
                    if ~strcmp(secondary_filenames{1}, image_filename)
                        reporting.Error('PTKDiskUtilities:MetaHeaderRawFileMismatch', ['Mismatch between specified image filename and entry in ' principal_filename{1}]);
                    end
                    image_type = PTKImageFileFormat.Metaheader;
                    return;
                end
            end

            % Unknown file type. Try looking for a header file
            [principal_filename_mh, secondary_filenames_mh] = PTKDiskUtilities.GetHeaderFileFromRawFile(image_path, name, reporting);
            if (~isempty(principal_filename_mh)) && (strcmp(secondary_filenames_mh{1}, image_filename))
                image_type = PTKImageFileFormat.Metaheader;
                principal_filename = principal_filename_mh;
                secondary_filenames = secondary_filenames_mh;
                return;
            end
            
            % Test for a DICOM image
            if PTKDicomUtilities.IsDicom(image_path, image_filename)
                image_type = PTKImageFileFormat.Dicom;
                principal_filename = {image_filename};
                secondary_filenames = {};
                return;
            end

            % If all else fails, use the guess
            image_type = default_guess;
            principal_filename = {image_filename};
            secondary_filenames = {};
        end
        
        function [principal_filename, secondary_filenames] = GetHeaderFileFromRawFile(image_path, image_filename, reporting)
            [~, name, ~] = fileparts(image_filename);
            if exist(fullfile(image_path, [name '.mha']), 'file')
                header_filename = [name '.mha'];
            elseif exist(fullfile(image_path, [name '.mhd']), 'file')
                header_filename = [name '.mhd'];
            else
                principal_filename = {};
                secondary_filenames = {};
                return;
            end
            
            [is_meta_header, raw_filename] = PTKDiskUtilities.IsFileMetaHeader(fullfile(image_path, header_filename), reporting);
            if ~is_meta_header
                principal_filename = {};
                secondary_filenames = {};
                return;
            end
            principal_filename = {header_filename};
            secondary_filenames = {raw_filename};
        end
        
        function Save(filename, value) %#ok<INUSD>
            save(filename, '-struct', 'value', '-v7');
        end
        
        function value = Load(filename) %#ok<INUSD>
            value = load(filename, '-mat');
        end
        
        function result = SaveStructure(file_path, filename_base, result, compression, reporting)
            result = PTKDiskUtilities.ConvertStructAndSaveRawImageData(result, file_path, filename_base, 0, compression, reporting);

            filename = [fullfile(file_path, filename_base) '.mat'];
            PTKDiskUtilities.Save(filename, result);
        end

        function results = LoadStructure(file_path, filename_base, reporting)
            filename = [fullfile(file_path, filename_base) '.mat'];
            results_struct = PTKDiskUtilities.Load(filename);
            results = PTKDiskUtilities.ConvertStructAndLoadRawImageData(results_struct, file_path, filename_base, reporting);
        end
        
        function [new_structure, next_index] = ConvertStructAndSaveRawImageData(old_structure, file_path, filename_base, next_index, compression, reporting)
            if isstruct(old_structure)
                field_names = fieldnames(old_structure);
                new_structure = struct;
                for field = field_names'
                    field_name = field{1};
                    [new_structure.(field_name), next_index] = PTKDiskUtilities.ConvertStructAndSaveRawImageData(old_structure.(field_name), file_path, filename_base, next_index, compression, reporting);
                end
            else
                if isa(old_structure, 'PTKImage')
                    reporting.LogVerbose(['Saving raw image data for ' filename_base]);
                    if next_index == 0
                        file_suffix = '';
                    else
                        file_suffix = ['_' int2str(next_index)];
                    end
                    raw_image_file_name = [filename_base file_suffix];
                    header = PTKSavePtkImage(old_structure, file_path, raw_image_file_name, compression, reporting);
                    next_index = next_index + 1;
                    new_structure = header;
                else
                    new_structure = old_structure;
                end
            end
        end
        
        function new_structure = ConvertStructAndLoadRawImageData(old_structure, file_path, filename_base, reporting)
            if isstruct(old_structure)
                field_names = fieldnames(old_structure);
                for field = field_names'
                    field_name = field{1};
                    new_structure.(field_name) = PTKDiskUtilities.ConvertStructAndLoadRawImageData(old_structure.(field_name), file_path, filename_base, reporting);
                end
            else
                new_structure = old_structure;
                if isa(old_structure, 'PTKImage')
                    old_structure.LoadRawImage(file_path, reporting);
                end
            end
        end
        
        function SaveImageCapture(capture, file_name, save_type, reporting)
            reporting.ShowProgress('Exporting image');
            if isa(file_name, 'CoreFilename');
                file_name = file_name.FullFile;
            end
            switch save_type
                case 'tif'
                    imwrite(capture.cdata, file_name, 'tif');
                case 'jpg'
                    imwrite(capture.cdata, file_name, 'jpg', 'Quality', 70);
                otherwise
                    reporting.Error('PTKDiskUtilities:SaveImageCapture:UnknownImageType', ['SaveImageCapture() does not support the image type ', save_type]);
            end
            reporting.CompleteProgress;
        end
        
        function compression_supported = CompressionSupported(compression, data_type, reporting)
            compression_supported = true;
            
            switch compression
                case {[], ''}
                    return;
                    
                case 'png'
                    switch data_type
                        case {'int32', 'uint32', 'int64', 'uint64'}
                            compression_supported = false;
                            return;
                    end
                case {'tiff', 'deflate'}
                    switch data_type
                        case {'int32', 'uint32', 'int64', 'uint64'}
                            compression_supported = false;
                            return;
                    end
                otherwise
                    reporting.Error('PTKDiskUtilities:CompressionSupported:UnknownCompressionType', ['I do not recognise the compression types  ', compression]);
            end
            
        end
        
        function SavePatchFile(patch_object, filename, reporting)
            try
                value = [];
                value.patch = patch_object;
                PTKDiskUtilities.Save(filename, value);
            catch ex
                reporting.ErrorFromException('PTKDiskUtilities:FailedtoSavePatchFile', ['Unable to save PTK patch file ' filename], ex);
            end
        end
        
        function patch = LoadPatch(filename, reporting)
            try
                if exist(filename, 'file')
                    patch_struct = PTKDiskUtilities.Load(filename);
                    patch = patch_struct.patch;
                else
                    reporting.Error('PTKDiskUtilities:PatchFileNotFound', 'No patch file found.');
                    patch = [];
                end
                
            catch ex
                reporting.ErrorFromException('PTKDiskUtilities:FailedtoLoadPatchFile', ['Error when loading patch file ' filename '.'], ex);
            end
        end
        
    end
end

