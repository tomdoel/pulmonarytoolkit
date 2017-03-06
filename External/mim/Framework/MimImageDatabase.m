classdef MimImageDatabase < handle
    % MimImageDatabase. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Constant)
        CurrentVersionNumber = 4
        LocalDatabaseId = '&#LOCAL_IMAGE_DATABASE#&'
        LocalDatabaseName = 'My data'
    end
    
    events
        DatabaseHasChanged
        SeriesHasBeenDeleted
    end
    
    properties (Access = private)
        Filename
        LegacyFilename
        
        PatientMap
        SeriesMap
        IsNewlyCreated
        Version  
        
        VersionHasChanged
        
        CachedSortedPaths
        CachedSortedUids
    end
    
    methods
        function obj = MimImageDatabase(filename)
            if nargin > 0
                obj.Filename = filename;
            end
            obj.PatientMap = containers.Map;
            obj.SeriesMap = containers.Map;
            obj.Version = obj.CurrentVersionNumber;
            obj.VersionHasChanged = false;
        end
        
        function AddImage(obj, single_image_metainfo)
            patient_id = single_image_metainfo.PatientId;
            if ~obj.PatientMap.isKey(patient_id)
                obj.AddPatient(single_image_metainfo.PatientName, single_image_metainfo.PatientId);
            end
            patient = obj.PatientMap(patient_id);
            series = patient.AddImage(single_image_metainfo);
            obj.SeriesMap(series.SeriesUid) = series;
            obj.InvalidateCachedPaths;
        end
        
        function datasets = GetAllSeriesForThisPatient(obj, project_id, patient_id, group_patients)
            datasets = [];
            if strcmp(project_id, MimImageDatabase.LocalDatabaseId)
                all_details = obj.GetAllPatientInfosForThisPatient(patient_id, group_patients);
                for patient_details_cell = all_details
                    for patient_details = all_details{1}
                        datasets = [datasets, patient_details.GetListOfSeries];
                    end
                end
            end
        end
        
        
        function patient_info = GetPatient(obj, patient_id)
            patient_info = obj.PatientMap(patient_id);
        end
        
        function series_info = GetSeries(obj, series_uid)
            series_info = obj.SeriesMap(series_uid);
        end
        
        function uids = GetSeriesUids(obj)
            uids = obj.SeriesMap.keys;
        end
        
        function series_exists = SeriesExists(obj, series_uid)
            series_exists = obj.SeriesMap.isKey(series_uid);
        end
        
        function [paths, uids] = GetListOfPaths(obj)
            if ~isempty(obj.CachedSortedPaths) && ~isempty(obj.CachedSortedUids)
                paths = obj.CachedSortedPaths;
                uids = obj.CachedSortedUids;
                return;
            end
            
            if obj.SeriesMap.isempty
                paths = [];
                uids = [];
            else
                uids = obj.SeriesMap.keys;
                values = obj.SeriesMap.values;
                paths = CoreContainerUtilities.GetFieldValuesFromSet(values, 'GetVisiblePath');
                
                % Sort the uids and paths by the pathname
                [~, sorted_indices] = CoreTextUtilities.SortFilenames(paths);
                paths = paths(sorted_indices);
                uids = uids(sorted_indices);
            end
            obj.CachedSortedPaths = paths;
            obj.CachedSortedUids = uids;

        end
        
        function [names, ids, short_visible_names, patient_id_map] = GetListOfPatientNames(obj, project_id, group_patients)
            [names, ids, short_visible_names, ~, ~, patient_id_map] = obj.GetListOfPatientNamesWithOptionalSeriesCount(project_id, false, group_patients);
        end
        
        function [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = GetListOfPatientNamesAndSeriesCount(obj, project_id, group_patients)
            [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = obj.GetListOfPatientNamesWithOptionalSeriesCount(project_id, true, group_patients);
        end
        
        function [project_names, project_ids] = GetListOfProjects(obj)
            project_names = {obj.LocalDatabaseName};
            project_ids = {obj.LocalDatabaseId};
        end
        
        function DeleteSeries(obj, series_uids, reporting)
            if ~iscell(series_uids)
                series_uids = {series_uids};
            end
            
            anything_changed = false;
            
            for series_uid_cell = series_uids
                series_uid = series_uid_cell{1};
            
                if obj.SeriesMap.isKey(series_uid)
                    anything_changed = true;
                    patient_id = obj.SeriesMap(series_uid).PatientId;
                    patient = obj.PatientMap(patient_id);
                    patient.DeleteSeries(series_uid);
                    if obj.PatientMap(patient_id).GetNumberOfSeries < 1
                        obj.PatientMap.remove(patient_id);
                    end
                    obj.SeriesMap.remove(series_uid);
                    notify(obj, 'SeriesHasBeenDeleted', CoreEventData(series_uid));
                end
            end
            if anything_changed
                obj.InvalidateCachedPaths;
                obj.SaveDatabase(reporting);
                notify(obj, 'DatabaseHasChanged');
            end
        end

        function Rebuild(obj, uids_to_update, rebuild_all, framework_app_def, reporting)
            reporting.ShowProgress('Updating image database');
            
            % Checks the disk cache and adds any missing datasets to the database.
            % Specifying a list of uids forces those datasets to update.
            % The rebuild_menu flag builds the database from scratch
            
            % Get the complete list of cache folders, unless we are only
            % updating specific uids
            if isempty(uids_to_update) || rebuild_all
                uids = framework_app_def.GetFrameworkDirectories.GetUidsOfAllDatasetsInCache;
            else
                uids = uids_to_update;
            end
            
            % If we are rebuilding the database or are updating specific uids then
            % we force each entry to be updated
            if ~isempty(uids_to_update) || rebuild_all
                rebuild_for_each_uid = true;
            else
                rebuild_for_each_uid = false;
            end
            
            % If we are rebuilding the menu then remove existings entries
            if rebuild_all
                obj.PatientMap = containers.Map;
                obj.SeriesMap = containers.Map;
            end
            
            tags_to_get = [];

            stage_index = 0;
            num_stages = numel(uids);
            
            database_changed = false;
            
            if ~isempty(uids)
                for uid = uids
                    stage_index = stage_index + 1;
                    temporary_uid = uid{1};
                    if ~obj.SeriesMap.isKey(temporary_uid) || rebuild_for_each_uid
                        if ~rebuild_for_each_uid
                            reporting.ShowMessage('MimImageDatabase:UnimportedDatasetFound', ['Dataset ' temporary_uid ' was found in the disk cache but not in the image database file. I am adding this dataset to the image database. This may occur if the database file was recently removed.']);
                        end
                        try
                            % Only update the progress for datasets we are actually checking
                            reporting.UpdateProgressStage(stage_index, num_stages);
                            cache_directory = framework_app_def.GetFrameworkDirectories.GetCacheDirectory;
                            image_info_cache_name = framework_app_def.GetFrameworkConfig.ImageInfoCacheName;
                            if 2 == exist(fullfile(cache_directory, temporary_uid, [image_info_cache_name '.mat']), 'file')
                                cache_parent_directory = cache_directory;
                            else
                                cache_parent_directory = framework_app_def.GetFrameworkDirectories.GetFrameworkDatasetCacheDirectory;
                            end
                            temporary_disk_cache = MimDiskCache(cache_parent_directory, temporary_uid, framework_app_def.GetFrameworkConfig, reporting);
                            temporary_image_info = temporary_disk_cache.Load(image_info_cache_name, [], reporting);

                            file_path = temporary_image_info.ImagePath;
                            file_names = temporary_image_info.ImageFilenames;
                            for filename = file_names
                                try
                                    next_filename = filename{1};
                                    if isa(next_filename, 'CoreFilename')
                                        next_filepath = next_filename.Path;
                                        next_filename = next_filename.Name;
                                    else
                                        next_filepath = file_path;
                                    end

                                    if CoreDiskUtilities.FileExists(next_filepath, next_filename)
                                        if isempty(tags_to_get)
                                            tags_to_get = DMDicomDictionary.GroupingDictionary;
                                        end
                                        single_image_metainfo = MimGetSingleImageInfo(next_filepath, next_filename, tags_to_get, reporting);
                                        obj.AddImage(single_image_metainfo);
                                    else
                                        reporting.ShowWarning('MimImageDatabase:FileNotFound', ['The image ' fullfile(next_filepath, next_filename) ' could not be found. '], []);
                                    end
                                catch exc
                                    reporting.ShowWarning('MimImageDatabase:AddImageFailed', ['An error occured when adding image ' fullfile(next_filepath, next_filename) ' to the databse. Error: ' exc.message], exc);
                                end
                            end

                            database_changed = true;

                        catch exc
                            reporting.ShowWarning('MimImageDatabase:AddDatasetFailed', ['An error occured when adding dataset ' temporary_uid ' to the databse. Error: ' exc.message], exc);
                        end
                    end                
                end
            end
            
            
            if database_changed || obj.GetAndResetVersionChanged
                reporting.UpdateProgressAndMessage(100, 'Saving changes to database');
                obj.InvalidateCachedPaths;
                obj.SaveDatabase(reporting);
                notify(obj, 'DatabaseHasChanged');
            end
            
            reporting.CompleteProgress;
        end
        
        function SaveDatabase(obj, reporting)
            if isempty(obj.Filename)
                reporting.ErrorFromException('MimImageDatabase:FilenameNotSpecified', 'No image database filename has been specified.', ex);
            end
            
            try
                value = [];
                value.database = obj;
                MimDiskUtilities.Save(obj.Filename, value);
                if ~isempty(obj.LegacyFilename) && (2 == exist(obj.LegacyFilename, 'file'))
                    delete(obj.LegacyFilename);
                    obj.LegacyFilename = [];
                end
            catch ex
                reporting.ErrorFromException('MimImageDatabase:FailedtoSaveDatabaseFile', ['Unable to save database file ' obj.Filename], ex);
            end
        end
        
        function ReportChangesToDatabase(obj)
            notify(obj, 'DatabaseHasChanged');
        end
    end
    
    methods (Access = private)
        function [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = GetListOfPatientNamesWithOptionalSeriesCount(obj, project_id, count_series, group_patients)
            % Returns list of patient names, ids and family names, sorted by the
            % short visible name
            
             if ~strcmp(project_id, MimImageDatabase.LocalDatabaseId)
                names = {};
                ids = {};
                short_visible_names = {};
                num_series = [];
                num_patients_combined = [];
                patient_id_map = containers.Map;
                return;
            end

            ids = obj.PatientMap.keys;
            values = obj.PatientMap.values;
            names = CoreContainerUtilities.GetFieldValuesFromSet(values, 'VisibleName');
            short_visible_names = CoreContainerUtilities.GetFieldValuesFromSet(values, 'ShortVisibleName');
            num_series = CoreContainerUtilities.GetMatrixOfFieldValuesFromSet(values, 'GetNumberOfSeries');

            if isempty(short_visible_names)
                names = [];
                ids = [];
                short_visible_names = [];
                num_series = [];
                num_patients_combined = [];
                patient_id_map = containers.Map;
                return;
            end
            
            % Sort by the short visible name
            % Remove any empty values to ensure sort works
            empty_values = cellfun(@isempty, short_visible_names);
            short_visible_names(empty_values) = {'Unknown'};
            [~, sorted_indices] = CoreTextUtilities.SortFilenames(short_visible_names);
            
            names = names(sorted_indices);
            ids = ids(sorted_indices);
            short_visible_names = short_visible_names(sorted_indices);
            num_series = num_series(sorted_indices);
            num_patients_combined = ones(size(num_series));
            
            % Merge together patients with same name if this is specified by the settings
            if group_patients
                
                % Get unique names, but don't group together 'Unknown' patients
                unique_names = short_visible_names;
                random_name = CoreSystemUtilities.GenerateUid;
                for empty_index = 1 : find(empty_values)
                    unique_names{empty_index} = [random_name, int2str(empty_index)];
                end
                
                [unique_names, ia, ic] = unique(unique_names);

                
                short_visible_names = unique_names;
                ids_subset = ids(ia);
                names = names(ia);
                
                if count_series
                    total_num_series = zeros(size(ids_subset));
                    num_patients_combined = zeros(size(ids_subset));
                    for series_index = 1 : length(num_series)
                        total_num_series(ic(series_index)) = total_num_series(ic(series_index)) + num_series(series_index);
                        num_patients_combined(ic(series_index)) = num_patients_combined(ic(series_index)) + 1;
                    end
                    num_series = total_num_series;
                else
                    num_series = [];
                    num_patients_combined = [];
                end

                % A map of all patient IDs to the main patient ID for each patient group
                patient_id_map = containers.Map(ids, ids_subset(ic));
                
                ids = ids_subset;
                
            else
                patient_id_map = containers.Map(ids, ids);
            end
        end
        
        function patient_info = GetPatients(obj, group_patients)
            patient_info = obj.PatientMap.values;
            family_names = CoreContainerUtilities.GetFieldValuesFromSet(patient_info, 'Name');
            family_names = CoreContainerUtilities.GetFieldValuesFromSet(family_names, 'FamilyName');
            short_visible_names = CoreContainerUtilities.GetFieldValuesFromSet(patient_info, 'ShortVisibleName');

            if isempty(family_names)
                patient_info = [];
                return
            end

            % Sort by the short visible name
            % Remove any empty values to ensure sort works
            empty_values = cellfun(@isempty, short_visible_names);
            short_visible_names(empty_values) = {'Unknown'};
            [sorted_visible_names, sorted_indices] = CoreTextUtilities.SortFilenames(short_visible_names);
            
            patient_info = patient_info(sorted_indices);
            
            % Merge together patients with same name if this is specified by the settings
            if group_patients
                unique_names = sorted_visible_names;
                
                % We don't want 'Unknown' patient names to be grouped together, so temporarily
                % assign them each a unique random name
                random_name = CoreSystemUtilities.GenerateUid;
                for empty_index = 1 : find(empty_values)
                    unique_names{empty_index} = [random_name, int2str(empty_index)];
                end
                
                [un, idx_last, idx] = unique(unique_names);
                unique_idx = accumarray(idx(:), (1:length(idx))', [], @(x) {x});
                patient_info_grouped = cellfun(@(x) [patient_info{x}], unique_idx, 'UniformOutput', false);
                patient_info_grouped = patient_info_grouped';
                
                patient_info = patient_info_grouped;
            end
        end
        
        function patient_info = GetAllPatientInfosForThisPatient(obj, patient_id, group_patients)
            if group_patients
                patient_info_grouped = obj.GetPatients(group_patients);
                for group = patient_info_grouped
                    for group_member = group{1}
                        if strcmp(group_member.PatientId, patient_id)
                            patient_info = group;
                            return;
                        end
                    end
                end
                patient_info = [];
                return;
            else
                patient_info = obj.GetPatient(patient_id);
            end
        end
        
        function has_changed = GetAndResetVersionChanged(obj)
            has_changed = obj.VersionHasChanged;
            obj.VersionHasChanged = false;
        end
        
        function InvalidateCachedPaths(obj)
            obj.CachedSortedPaths = [];
            obj.CachedSortedUids = [];            
        end
        
        function AddPatient(obj, patient_name, patient_id)
            obj.PatientMap(patient_id) = MimImageDatabasePatient(patient_name, patient_id);
        end       
    end
    
    methods (Static)
        function database = LoadDatabase(framework_app_def, reporting)
            try
                database_filename = framework_app_def.GetFrameworkDirectories.GetImageDatabaseFilePath;
                legacy_database_filename = framework_app_def.GetFrameworkDirectories.GetLegacyImageDatabaseFilePath;
                                
                if exist(database_filename, 'file')
                    database_struct = MimDiskUtilities.Load(database_filename);
                    database = database_struct.database;
                    database.IsNewlyCreated = false;
                    database.VersionHasChanged = isempty(database.Version) || (database.Version ~= MimImageDatabase.CurrentVersionNumber);                    
                    database.Version = MimImageDatabase.CurrentVersionNumber;

                elseif exist(legacy_database_filename, 'file')
                    % Support for version 3 and previous, which had a
                    % different image database filename
                    
                    database_struct = MimDiskUtilities.Load(legacy_database_filename);
                    database = database_struct.database;
                    database.Filename = database_filename;
                    database.IsNewlyCreated = false;
                    database.VersionHasChanged = isempty(database.Version) || (database.Version ~= MimImageDatabase.CurrentVersionNumber);

                    % Set legacy filename for deletion when the database is next saved
                    database.LegacyFilename = legacy_database_filename; 
                    
                    % Version 3 has changes to the maps used to store filenames; this requires a
                    % rebuild of the image database
                    if database.Version == 2
                        database.Rebuild([], true, framework_app_def, reporting);
                    end
                    
                    database.Version = MimImageDatabase.CurrentVersionNumber;
                    
                    
                else
                    reporting.ShowWarning('MimImageDatabase:DatabaseFileNotFound', 'No image database file found. Will create new one on exit', []);
                    database = MimImageDatabase(database_filename);
                    database.IsNewlyCreated = true;
                end
                
                database.Filename = database_filename;
                if database.IsNewlyCreated
                    database.Rebuild([], true, framework_app_def, reporting);
                end
                
            catch ex
                reporting.ErrorFromException('MimImageDatabase:FailedtoLoadDatabaseFile', ['Error when loading database file ' database_filename '. Try deleting this file.'], ex);
            end
        end
        
        function obj = loadobj(a)
            % This method is called when the object is loaded from disk.
            
            if isa(a, 'MimImageDatabase')
                obj = a;
            else
                % In the case of a load error, loadobj() gives a struct
                obj = MimImageDatabase;
                for field = fieldnames(a)'
                    if isprop(obj, field{1})
                        mp = findprop(obj, (field{1}));
                        if (~mp.Constant) && (~mp.Dependent) && (~mp.Abstract) 
                            obj.(field{1}) = a.(field{1});
                        end
                    end
                end
            end
            
        end
    end    
end