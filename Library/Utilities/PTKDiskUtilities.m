classdef PTKDiskUtilities
    % PTKDiskUtilities. Disk-related utility functions.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)
        
        % Returns a path to the user's home folder
        function home_directory = GetUserDirectory
            if (ispc)
                home_directory = getenv('USERPROFILE');
            else
                home_directory = getenv('HOME');
            end
        end
        
        % Returns a list of files in the specified directory
        function file_list = GetDirectoryFileList(path, filename)
            files = dir(fullfile(path, filename));
            number_files = length(files);
            file_list = {};
            for i = 1 : number_files
                filename = files(i).name;
                isdir = files(i).isdir;
                if (filename(1) ~= '.' && ~isdir)
                    file_list{end + 1} = filename; %#ok<AGROW>
                end
            end
        end
        
        % Returns a list of files in the specified directory
        function dir_list = GetListOfDirectories(path)
            files = dir(fullfile(path, '*'));
            number_files = length(files);
            dir_list = {};
            for i = 1 : number_files
                filename = files(i).name;
                isdir = files(i).isdir;
                if (filename(1) ~= '.' && isdir)
                    dir_list{end + 1} = filename; %#ok<AGROW>
                end
            end
        end
        
        % Opens an explorer/finder window at the specified path
        function OpenDirectoryWindow(directory_path)
           if ispc
               
               if ~exist(directory_path, 'dir')
                   error('Directory not found');
               end
               
               dos(['explorer.exe ' directory_path]);
           
           elseif ismac
               unix(['Open ' directory_path]);
           else
               warning('PTKDiskUtilities:NotImplementedForUnix', 'Not implemented for unix');
           end
        end
        
        % Displays a dialog for selecting files
        function [path, filenames, filter_index] = ChooseFiles(text_to_display, path, allow_multiple_files, file_spec)
            
            if isempty(path)
                path = PTKDiskUtilities.GetUserDirectory;
            end
            
            if (allow_multiple_files)
                ms = 'on';
            else
                ms = 'off';
            end
            
            input_path = path;
            if (input_path(end) ~= '/')
                input_path = [path '/'];
            end
            
            [filenames, path, filter_index] = uigetfile(file_spec, text_to_display, input_path, 'MultiSelect', ms);
            if (length(filenames) == 1) && (filenames == 0)
                path = [];
                filenames = [];
                filter_index = [];
            end
            if (~iscell(filenames))
                filenames = {filenames};
            end
        end
        
        % Creates a random unique identifier        
        function uid = GenerateUid
            % On unix systems, if java is not running we can use the system
            % command
            if isunix && ~usejava('jvm')
                [status, uid] = system('uuidgen');
                if status ~= 0
                    error('Failure running uuidgen');
                end
            else
                uid = char(java.util.UUID.randomUUID);
            end
        end
        
        function dicom_filenames = RemoveNonDicomFiles(image_path, filenames)
            dicom_filenames = [];
            for index = 1 : length(filenames)
                if (isdicom(fullfile(image_path, filenames{index}))) && (~strcmp(filenames{index}, 'DICOMDIR'))
                    dicom_filenames{end + 1} = filenames{index};
                end
            end
        end
        
        function image_info = GetListOfDicomFiles(image_path)
            filenames = PTKTextUtilities.SortFilenames(PTKDiskUtilities.GetDirectoryFileList(image_path, '*'));
            filenames = PTKDiskUtilities.RemoveNonDicomFiles(image_path, filenames);
            image_type = PTKImageFileFormat.Dicom;            
            image_info = PTKImageInfo(image_path, filenames, image_type, [], [], []);
        end

        function CreateDirectoryIfNecessary(dir_name)
            if ~exist(dir_name, 'dir')
                mkdir(dir_name);
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
            
            for index = 1 : length(meta_header_data{1});
                meta_header.(meta_header_data{1}{index}) = meta_header_data{2}{index};
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
                    reporting.Error('PTKDiskUtilities:OpenMHDFileFailed', ['Unable to read metaheader file ' header_filename]);
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
                    reporting.Error('PTKDiskUtilities:HeaderFileLoadError', ['Unable to find valid header file for ' fullfile(image_path, image_filename)]);
                end
                if ~strcmp(secondary_filenames{1}, image_filename)
                    reporting.Error('PTKDiskUtilities:MetaHeaderRawFileMismatch', ['Mismatch between specified image filename and entry in ' principal_filename{1}]);
                end
                image_type = PTKImageFileFormat.Metaheader;
                return;
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
            if ~strcmp(image_filename, 'DICOMDIR') && isdicom(fullfile(image_path, image_filename))
                image_type = PTKImageFileFormat.Dicom;
                principal_filename = {image_filename};
                secondary_filenames = {};
                return;
            end

            % If all else fails, use the guess
            image_type = default_guess;
            principal_filename = image_filename;
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
    end
end

