classdef PTKRunFile < MimScript
    % PTKRunFile. Script for importing data and running plugins listed in an input file
    %
    % To run this file from the Matlab command line, use 
    %     PTKUtils.RunScript('PTKRunFile', data_file, uid_filter, plugin_file, output_file);
    %
    % To run this file from the API, run:
    %     PulmonaryToolkitAPI PTKRunFile data_file uid_filter plugin_file output_file
    %
    % Parameters:
    %     data_file - filename of a text file containing a list of paths to
    %         import, one per line. Use [] to specify run on existing datasets
    %     uid_filter - Only run ananlysis for dataset UIDs matching this
    %         regular expression
    %     plugin_file - For each matching dataset UID, run all plugin names
    %         listed in this text file, one per line
    %     output_file - Logging output for these files will be written here
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        InterfaceVersion = '1'
        Version = '1'
        Category= 'Analysis'
    end
    
    methods (Static)
        function output = RunScript(ptk_obj, reporting, varargin)
            failures = [];
            success = [];
            ignored = [];
            
            input_data_file = varargin{1};
            uid_filter = varargin{2};
            input_plugin_list = varargin{3};
            output_file_name = varargin{4};
            
            fileID = fopen(output_file_name, 'w');
            fprintf(fileID, '%s\n', 'Started...');
            fclose(fileID);
            
            uids_to_process = PTKRunFile.GetDatasetUids(input_data_file, ptk_obj, reporting);
            
            % Filter out matching uids
            uids_to_process = PTKRunFile.FilterUids(uids_to_process, uid_filter);
            
            % Get list of plugins to run
            plugins_to_process = PTKRunFile.GetPlugins(input_plugin_list, reporting);

            if isempty(plugins_to_process)
                fileID = fopen(output_file_name, 'a');
                fprintf(fileID, '%s\n', 'Nothing to do');
                fclose(fileID); 
            end
            
            for uid = uids_to_process
                this_uid = uid{1};
                plugin = [];
                im_path = [];
                try
                    dataset = ptk_obj.CreateDatasetFromUid(this_uid);
                    im_info = dataset.GetImageInfo();
                    im_path = im_info.ImagePath;

                    for plugin = plugins_to_process
                        dataset.GetResult(plugin{1});
                    end

                    success{end + 1} = this_uid; %#ok<AGROW>
                    fileID = fopen(output_file_name, 'a');
                    fprintf(fileID, 'Success: %s %s\n', this_uid, im_path);
                    fclose(fileID);

                catch ex
                    failures{end + 1} = this_uid; %#ok<AGROW>
                    fileID = fopen(output_file_name, 'a');
                    fprintf(fileID, 'Failed: %s %s (plugin %s)\n', this_uid, im_path, plugin{1});
                    fclose(fileID);
                    reporting.ShowWarning('PTKImportAndAnalyse:Failure', ['Failure on dataset ' this_uid ' : ' ex.message], ex);
                end
            end

            fileID = fopen(output_file_name, 'a');
            fprintf(fileID, '%s\n', '...Complete');
            fclose(fileID);
            output.Failures = failures;
            output.Success = success;
            output.Ignored = ignored;
        end
    end
    
    methods (Static, Access = private)
        
        function uids_to_process = GetDatasetUids(input_data_file, ptk_obj, reporting)
            % Import data and get list of UIDs
            if isempty(input_data_file)
                image_database = ptk_obj.GetImageDatabase();
                uids_to_process = image_database.GetSeriesUids();
            else
                uids_to_process = {};            
                [input_data_file_path, input_data_file_name, input_data_file_ext] = fileparts(input_data_file);
                fr = CoreTextFileReader(input_data_file_path, [input_data_file_name input_data_file_ext], reporting);
                
                while ~fr.Eof
                    next_input_path = fr.NextLine();
                    if ~isempty(next_input_path)
                        uids_to_process = [uids_to_process, ptk_obj.ImportData(next_input_path)]; %#ok<AGROW>
                    end
                end
            end            
        end
        
        function uids_to_process = FilterUids(uids_to_process, uid_filter)
            if ~isempty(uid_filter)
                uid_matches = regexp(uids_to_process, regexptranslate('wildcard', uid_filter), 'match');
                uids_to_process = uids_to_process(~cellfun(@isempty,  uid_matches));
            end
            
            uids_to_process = unique(uids_to_process);
        end
        
        function plugins_to_process = GetPlugins(input_plugin_list, reporting)
            if isempty(input_plugin_list)
                plugins_to_process = {};
            else
                plugins_to_process = {};            
                [input_plugins_file_path, input_plugins_file_name, input_plugins_file_ext] = fileparts(input_plugin_list);
                fr = CoreTextFileReader(input_plugins_file_path, [input_plugins_file_name, input_plugins_file_ext], reporting);
                
                while ~fr.Eof
                    next_plugin_name = fr.NextLine();
                    if ~isempty(next_plugin_name)
                        plugins_to_process = [plugins_to_process, next_plugin_name]; %#ok<AGROW>
                    end
                end
            end
        end

    end
end