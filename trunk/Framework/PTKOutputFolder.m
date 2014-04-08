classdef PTKOutputFolder < handle
    % PTKOutputFolder. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKOutputFolder is used to save and keep track of results and graphs saved
    %     to the output folder.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)        
        OutputFolder % Caches the output folder for this dataset        
        OutputRecords % Records of files stored in the Output folder
        
        DatasetDiskCache % Used for persisting the records between sessions
        ImageTemplates
        Reporting % Callback for error reporting
        ImageUid
        
        ChangedFolders % List of output folders which have been modified since last call to OpenChangedFolders
    end
    
    methods
        function obj = PTKOutputFolder(dataset_disk_cache, image_info, image_templates, reporting)
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.ImageTemplates = image_templates;
            obj.ImageUid = image_info.ImageUid;
            obj.Reporting = reporting;
            
            obj.OutputRecords = PTKOutputInfo.empty;
            
            % Loads cached template data
            obj.Load;
        end
        
        function SaveTableAsCSV(obj, plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters, dataset_stack)
            date_text = date;
            output_folder = obj.GetOutputPath(dataset_stack);
            file_path = fullfile(output_folder, subfolder_name);
            ptk_file_name = PTKFilename(file_path, file_name);
            new_record = PTKOutputInfo(plugin_name, description, ptk_file_name, date_text);
            PTKDiskUtilities.CreateDirectoryIfNecessary(file_path);
            PTKSaveTableAsCSV(file_path, file_name, table, file_dim, row_dim, col_dim, filters, obj.Reporting);
            obj.AddRecord(new_record);
            obj.ChangedFolders{end + 1} = file_path;
        end

        function SaveFigure(obj, figure_handle, plugin_name, subfolder_name, file_name, description, dataset_stack)
            date_text = date;
            output_folder = obj.GetOutputPath(dataset_stack);
            file_path = fullfile(output_folder, subfolder_name);
            ptk_file_name = PTKFilename(file_path, file_name);
            new_record = PTKOutputInfo(plugin_name, description, ptk_file_name, date_text);
            PTKDiskUtilities.CreateDirectoryIfNecessary(file_path);
            PTKDiskUtilities.SaveFigure(figure_handle, fullfile(file_path, file_name));
            obj.AddRecord(new_record);
            obj.ChangedFolders{end + 1} = file_path;
        end
        
        function OpenChangedFolders(obj)
            obj.ChangedFolders = unique(obj.ChangedFolders);
            for folder = obj.ChangedFolders'
                obj.Reporting.OpenPath(folder{1}, 'New analysis result files have been added to the following output path');
            end
            obj.ChangedFolders = [];
        end
        
        function cache_path = GetOutputPath(obj, dataset_stack)
            if isempty(obj.OutputFolder)
                obj.CreateNewOutputFolder(dataset_stack)
            end
            cache_path = obj.OutputFolder;
        end        
    end
    
    
    methods (Access = private)

        function AddRecord(obj, new_record)
            obj.OutputRecords(end + 1) = new_record;
            obj.Save;
        end
        
        function Load(obj)
            % Retrieves previous records from the disk cache
        
            if obj.DatasetDiskCache.Exists(PTKSoftwareInfo.OutputFolderCacheName, [], obj.Reporting)
                info = obj.DatasetDiskCache.LoadData(PTKSoftwareInfo.OutputFolderCacheName, obj.Reporting);
                obj.OutputRecords = info.OutputRecords;
                if isfield(info, 'OutputFolder')
                    obj.OutputFolder = info.OutputFolder;
                else
                    obj.OutputFolder = [];
                end
            else
                obj.OutputFolder = [];
            end
        end
        
        function Save(obj)
            % Stores current records in the disk cache
            
            info = [];
            info.OutputRecords = obj.OutputRecords;
            obj.DatasetDiskCache.SaveData(PTKSoftwareInfo.OutputFolderCacheName, info, obj.Reporting);
        end
        
        function CreateNewOutputFolder(obj, dataset_stack)
            root_output_path = PTKDirectories.GetOutputDirectoryAndCreateIfNecessary;
            
            template = obj.ImageTemplates.GetTemplateImage(PTKContext.LungROI, dataset_stack);
            metadata = template.MetaHeader;
            
            if isfield(metadata, 'PatientName')
                [~, subfolder] = PTKDicomUtilities.PatientNameToString(metadata.PatientName);
            elseif isfield(metadata, 'PatientId')
                subfolder = metadata.PatientId;
            else
                subfolder = '';
            end

            if isempty(subfolder)
                subfolder = obj.ImageUid;
            end
            
            subfolder = PTKTextUtilities.MakeFilenameValid(subfolder);
            
            obj.OutputFolder = fullfile(root_output_path, subfolder);
        end
    end
end