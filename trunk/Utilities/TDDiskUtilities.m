classdef TDDiskUtilities
    % TDDiskUtilities. Disk-related utility functions.
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
               warning('TDDiskUtilities:NotImplementedForUnix', 'Not implemented for unix');
           end
        end
        
        % Displays a dialog for selecting files
        function [path, filenames, filter_index] = ChooseFiles(text_to_display, path, allow_multiple_files, file_spec)
            
            if isempty(path)
                path = TDDiskUtilities.GetUserDirectory;
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
            uid = char(java.util.UUID.randomUUID);
        end
    end
end

