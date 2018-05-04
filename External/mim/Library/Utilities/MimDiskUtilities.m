classdef MimDiskUtilities
    % MimDiskUtilities. Disk-related utility functions.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    methods (Static)
        
        function [filename, path_name, save_type] = SaveImageDialogBox(path_name)
            % Dialog for exporting a 2D image
            filespec = {...
                '*.tif', 'TIF (*.tif)';
                '*.jpg', 'JPG (*.jpg)';
                '*.png', 'PNG (*.png)';
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
                case 3
                    save_type = 'png';
                otherwise
                    save_type = [];
            end
            
        end

        function [is_meta_header, raw_filename] = IsFileMetaHeader(header_filename, reporting)
            meta_header = mha_read_header(header_filename);
            if (~isempty(meta_header)) && isfield(meta_header, 'DataFile')
                is_meta_header = true;
                raw_filename = meta_header.DataFile;
            else
                is_meta_header = false;
                raw_filename = [];
            end
        end
        
        function meta_header = ReadMetaHeader(header_filename, reporting)
            file_id = fopen(header_filename);
            if (file_id <= 0)
                reporting.Error('MimDiskUtilities:OpenFileFailed', ['Unable to open file ' header_filename]);
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
                    reporting.ShowWarning('MimDiskUtilities:LocalDataNotSupported', 'This application does not currently support image files with data embedded in the same file as the metaheader.');
                    meta_header = [];
                    return;
                end
            end
            
            for index = 1 : length(meta_header_data{1})
                meta_header.(genvarname(meta_header_data{1}{index})) = meta_header_data{2}{index};
            end
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
            
            [is_meta_header, raw_filename] = MimDiskUtilities.IsFileMetaHeader(fullfile(image_path, header_filename), reporting);
            if ~is_meta_header
                principal_filename = {};
                secondary_filenames = {};
                return;
            end
            principal_filename = {header_filename};
            secondary_filenames = {raw_filename};
        end
        
        function Save(filename, value) %#ok<INUSD>
            if isempty(filename)
                reporting.Error('MimDiskUtilities:NoSettingsFilename', 'The file could not be saved as the specified filename was empty.');
            else
                if ~isstruct(value)
                    reporting.Error('MimDiskUtilities:NotAStruct', 'The file could not be saved as the variable was not in a structure.');
                end
                save(filename, '-struct', 'value', '-v7');
            end
        end
        
        function SaveAsXml(name, filename, value, reporting)
            CoreSaveXml(value, name, filename, reporting);
        end
        
        function SaveAsSimplifiedXml(name, filename, value, reporting)
            CoreSaveXmlSimplified(value, name, filename, reporting);
        end
        
        function value = Load(filename) %#ok<INUSD>
            value = load(filename, '-mat');
        end

        function SaveImageCapture(capture, file_name, save_type, reporting)
            reporting.ShowProgress('Exporting image');
            if isa(file_name, 'CoreFilename')
                file_name = file_name.FullFile;
            end
            switch save_type
                case 'tif'
                    imwrite(capture.cdata, file_name, 'tif');
                case 'jpg'
                    imwrite(capture.cdata, file_name, 'jpg', 'Quality', 70);
                case 'png'
                    imwrite(capture.cdata, file_name, 'png', 'Software', 'TD Pulmonary Toolkit');
                otherwise
                    reporting.Error('MimDiskUtilities:SaveImageCapture:UnknownImageType', ['SaveImageCapture() does not support the image type ', save_type]);
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
                    reporting.Error('MimDiskUtilities:CompressionSupported:UnknownCompressionType', ['I do not recognise the compression types  ', compression]);
            end
            
        end
        
        function SavePatchFile(patch_object, filename, reporting)
            try
                value = [];
                value.patch = patch_object;
                MimDiskUtilities.Save(filename, value);
            catch ex
                reporting.ErrorFromException('MimDiskUtilities:FailedtoSavePatchFile', ['Unable to save patch file ' filename], ex);
            end
        end
        
        function patch = LoadPatch(filename, reporting)
            try
                if exist(filename, 'file')
                    patch_struct = MimDiskUtilities.Load(filename);
                    patch = patch_struct.patch;
                else
                    reporting.Error('MimDiskUtilities:PatchFileNotFound', 'No patch file found.');
                    patch = [];
                end
                
            catch ex
                reporting.ErrorFromException('MimDiskUtilities:FailedtoLoadPatchFile', ['Error when loading patch file ' filename '.'], ex);
            end
        end
        
    end
end

