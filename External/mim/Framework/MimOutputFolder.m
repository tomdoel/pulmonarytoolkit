classdef MimOutputFolder < CoreBaseClass
    % Used to save and keep track of results and graphs saved to the output folder.
    %
    % The output folder stores files the user may wish to preserve, such as 
    % analysis results and graphs. This class provides a consistent way of writing
    % out such results, keeping track of them so that the user can be informed
    % when new results have been added.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        Config % Used to fetch the load/save name
        Directories % Class for fetching base output directory
        FrameworkAppDef % Used for generating new classes using class factory
        
        OutputFolder % Caches the output folder for this dataset        
        OutputRecords % Records of files stored in the Output folder
        
        DatasetDiskCache % Used for persisting the records between sessions
        ImageTemplates
        ImageUid
        
        ChangedFolders % List of output folders which have been modified since last call to OpenChangedFolders
    end
    
    methods
        function obj = MimOutputFolder(framework_app_def, dataset_disk_cache, image_info, image_templates, reporting)
            obj.Config = framework_app_def.GetFrameworkConfig();
            obj.Directories = framework_app_def.GetFrameworkDirectories();
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.FrameworkAppDef = framework_app_def;
            obj.ImageTemplates = image_templates;
            obj.ImageUid = image_info.ImageUid;
            
            obj.OutputRecords = obj.FrameworkAppDef.GetClassFactory.CreateEmptyOutputInfo();
            
            % Loads cached template data
            obj.Load(reporting);
        end
        
        function SaveTableAsCSV(obj, plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters, dataset_stack, reporting)
            date_text = date;
            output_folder = obj.GetOutputPath(dataset_stack, reporting);
            file_path = fullfile(output_folder, subfolder_name);
            mim_file_name = CoreFilename(file_path, file_name);
            new_record = obj.FrameworkAppDef.GetClassFactory.CreateOutputInfo(plugin_name, description, mim_file_name, date_text);
            CoreDiskUtilities.CreateDirectoryIfNecessary(file_path);
            context_list = obj.FrameworkAppDef.GetContextDef.GetContextLabels;
            MimSaveTableAsCSV(file_path, file_name, table, file_dim, row_dim, col_dim, filters, context_list, reporting);
            obj.AddRecord(new_record, reporting);
            obj.ChangedFolders{end + 1} = file_path;
        end

        function SaveFigure(obj, figure_handle, plugin_name, subfolder_name, file_name, description, dataset_stack, reporting)
            date_text = date;
            output_folder = obj.GetOutputPath(dataset_stack, reporting);
            file_path = fullfile(output_folder, subfolder_name);
            mim_file_name = CoreFilename(file_path, file_name);
            new_record = obj.FrameworkAppDef.GetClassFactory.CreateOutputInfo(plugin_name, description, mim_file_name, date_text);
            CoreDiskUtilities.CreateDirectoryIfNecessary(file_path);
            CoreDiskUtilities.SaveFigure(figure_handle, fullfile(file_path, file_name));
            obj.AddRecord(new_record, reporting);
            obj.ChangedFolders{end + 1} = file_path;
        end
        
        function SaveSurfaceMesh(obj, plugin_name, subfolder_name, file_name, description, segmentation, smoothing_size, small_structures, coordinate_system, template_image, dataset_stack, reporting)
            date_text = date;
            output_folder = obj.GetOutputPath(dataset_stack, reporting);
            file_path = fullfile(output_folder, subfolder_name);
            mim_file_name = CoreFilename(file_path, file_name);
            new_record = obj.FrameworkAppDef.GetClassFactory.CreateOutputInfo(plugin_name, description, mim_file_name, date_text);
            CoreDiskUtilities.CreateDirectoryIfNecessary(file_path);
            MimCreateSurfaceMesh(file_path, file_name, segmentation, smoothing_size, small_structures, coordinate_system, template_image, reporting);
            obj.AddRecord(new_record, reporting);
            obj.ChangedFolders{end + 1} = file_path;
        end

        function RecordNewFileAdded(obj, plugin_name, file_path, file_name, description, reporting)
            date_text = date;
            mim_file_name = CoreFilename(file_path, file_name);
            new_record = obj.FrameworkAppDef.GetClassFactory.CreateOutputInfo(plugin_name, description, mim_file_name, date_text);
            obj.AddRecord(new_record, reporting);
            obj.ChangedFolders{end + 1} = file_path;
        end

        function OpenChangedFolders(obj, reporting)
            obj.ChangedFolders = unique(obj.ChangedFolders);
            for folder = obj.ChangedFolders'
                reporting.OpenPath(folder{1}, 'New analysis result files have been added to the following output path');
            end
            obj.ChangedFolders = [];
        end
        
        function cache_path = GetOutputPath(obj, dataset_stack, reporting)
            if isempty(obj.OutputFolder)
                obj.CreateNewOutputFolder(dataset_stack, reporting)
            end
            cache_path = obj.OutputFolder;
        end        
    end
    
    
    methods (Access = private)

        function AddRecord(obj, new_record, reporting)
            obj.OutputRecords(end + 1) = new_record;
            obj.Save(reporting);
        end
        
        function Load(obj, reporting)
            % Retrieves previous records from the disk cache
        
            filename = obj.Config.OutputFolderCacheName;
            if obj.DatasetDiskCache.Exists(filename, [], reporting)
                info = obj.DatasetDiskCache.LoadData(filename, reporting);
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
        
        function Save(obj, reporting)
            % Stores current records in the disk cache
            
            info = [];
            info.OutputRecords = obj.OutputRecords;
            obj.DatasetDiskCache.SaveData(obj.Config.OutputFolderCacheName, info, reporting);
        end
        
        function CreateNewOutputFolder(obj, dataset_stack, reporting)
            root_output_path = obj.Directories.GetOutputDirectoryAndCreateIfNecessary;
            
            template = obj.ImageTemplates.GetTemplateImage(obj.FrameworkAppDef.GetContextDef.GetOriginalDataContext, dataset_stack, reporting);
            metadata = template.MetaHeader;
            
            if isfield(metadata, 'PatientName')
                [~, subfolder] = DMUtilities.PatientNameToString(metadata.PatientName);
            elseif isfield(metadata, 'PatientId')
                subfolder = metadata.PatientId;
            else
                subfolder = '';
            end
            
            if isempty(subfolder)
                subfolder = obj.ImageUid;
                subsubfolder = '';
            else
                subsubfolder = '';                
                if isfield(metadata, 'StudyDescription')
                    study_description = metadata.StudyDescription;
                else
                    study_description = '';
                end
                if isfield(metadata, 'SeriesDescription')
                    series_description = metadata.SeriesDescription;
                else
                    series_description = '';
                end
                if ~isempty(study_description) && ~isempty(series_description)
                    subsubfolder = [study_description '_' series_description];
                elseif ~isempty(study_description)
                    subsubfolder = study_description;
                elseif ~isempty(series_description)
                    subsubfolder = series_description;
                end
            end

            subfolder = CoreTextUtilities.MakeFilenameValid(subfolder);
            if isempty(subsubfolder)
                obj.OutputFolder = fullfile(root_output_path, subfolder);
            else
                subsubfolder = CoreTextUtilities.MakeFilenameValid(subsubfolder);
                obj.OutputFolder = fullfile(root_output_path, subfolder, subsubfolder);
            end
            
        end
    end
end