classdef PTKImageDatabase < handle
    % PTKImageDatabase. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Constant)
        CurrentVersionNumber = 3
    end
    
    properties (Access = private)
        PatientMap
        SeriesMap
        IsNewlyCreated
        Version  
        
        VersionHasChanged
        
        CachedSortedPaths
        CachedSortedUids
    end
    
    methods
        function obj = PTKImageDatabase
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
        end
        
        function patient_info = GetPatients(obj)
            patient_info = obj.PatientMap.values;
            family_names = PTKContainerUtilities.GetFieldValuesFromSet(patient_info, 'Name');
            family_names = PTKContainerUtilities.GetFieldValuesFromSet(family_names, 'FamilyName');
            short_visible_names = PTKContainerUtilities.GetFieldValuesFromSet(patient_info, 'ShortVisibleName');

            if isempty(family_names)
                patient_info = [];
                return
            end

            % Sort by the short visible name
            % Remove any empty values to ensure sort works
            empty_values = cellfun(@isempty, short_visible_names);
            short_visible_names(empty_values) = {'Unknown'};
            [~, sorted_indices] = PTKTextUtilities.SortFilenames(short_visible_names);
            
            patient_info = patient_info(sorted_indices);
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
                paths = PTKContainerUtilities.GetFieldValuesFromSet(values, 'GetVisiblePath');
                
                % Sort the uids and paths by the pathname
                [~, sorted_indices] = PTKTextUtilities.SortFilenames(paths);
                paths = paths(sorted_indices);
                uids = uids(sorted_indices);
            end
            obj.CachedSortedPaths = paths;
            obj.CachedSortedUids = uids;

        end
        
        function [names, ids, short_visible_names] = GetListOfPatientNames(obj)
            % Returns list of patient names, ids and fmaily names, sorted by the
            % short visible name
            ids = obj.PatientMap.keys;
            values = obj.PatientMap.values;
            names = PTKContainerUtilities.GetFieldValuesFromSet(values, 'VisibleName');
            short_visible_names = PTKContainerUtilities.GetFieldValuesFromSet(values, 'ShortVisibleName');

            if isempty(short_visible_names)
                names = [];
                ids = [];
                short_visible_names = [];
                return;
            end
            
            % Sort by the short visible name
            % Remove any empty values to ensure sort works
            empty_values = cellfun(@isempty, short_visible_names);
            short_visible_names(empty_values) = {'Unknown'};
            [~, sorted_indices] = PTKTextUtilities.SortFilenames(short_visible_names);
            
            names = names(sorted_indices);
            ids = ids(sorted_indices);
            short_visible_names = short_visible_names(sorted_indices);
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
                end
            end
            if anything_changed
                obj.InvalidateCachedPaths;
                obj.SaveDatabase(reporting);
            end
        end

        function Rebuild(obj, uids_to_update, rebuild_all, reporting)
            reporting.ShowProgress('Updating image database');
            
            % Checks the disk cache and adds any missing datasets to the database.
            % Specifying a list of uids forces those datasets to update.
            % The rebuild_menu flag builds the database from scratch
            
            % Get the complete list of cache folders, unless we are only
            % updating specific uids
            if isempty(uids_to_update) || rebuild_all
                uids = PTKDirectories.GetUidsOfAllDatasetsInCache;
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
            
            for uid = uids
                stage_index = stage_index + 1;
                temporary_uid = uid{1};
                if ~obj.SeriesMap.isKey(temporary_uid) || rebuild_for_each_uid
                    if ~rebuild_for_each_uid
                        reporting.ShowMessage('PTKImageDatabase:UnimportedDatasetFound', ['Dataset ' temporary_uid ' was found in the disk cache but not in the image database file. I am adding this dataset to the image database. This may occur if the database file was recently removed.']);
                    end
                    try
                        % Only update the progress for datasets we are actually checking
                        reporting.UpdateProgressStage(stage_index, num_stages);
                        cache_parent_directory = PTKDirectories.GetCacheDirectory;
                        temporary_disk_cache = PTKDiskCache(cache_parent_directory, temporary_uid, reporting);
                        temporary_image_info = temporary_disk_cache.Load(PTKSoftwareInfo.ImageInfoCacheName, [], reporting);

                        file_path = temporary_image_info.ImagePath;
                        file_names = temporary_image_info.ImageFilenames;
                        for filename = file_names
                            try
                                next_filename = filename{1};
                                if isa(next_filename, 'PTKFilename')
                                    next_filepath = next_filename.Path;
                                    next_filename = next_filename.Name;
                                else
                                    next_filepath = file_path;
                                end
                                
                                if PTKDiskUtilities.FileExists(next_filepath, next_filename)
                                    if isempty(tags_to_get)
                                        tags_to_get = PTKDicomDictionary.GroupingTagsDictionary(false);
                                    end
                                    single_image_metainfo = PTKGetSingleImageInfo(next_filepath, next_filename, tags_to_get, reporting);
                                    obj.AddImage(single_image_metainfo);
                                else
                                    reporting.ShowWarning('PTKImageDatabase:FileNotFound', ['The image ' fullfile(next_filepath, next_filename) ' could not be found. '], []);
                                end
                            catch exc
                                reporting.ShowWarning('PTKImageDatabase:AddImageFailed', ['An error occured when adding image ' fullfile(next_filepath, next_filename) ' to the databse. Error: ' exc.message], exc);
                            end
                        end
                        
                        database_changed = true;
                        
                    catch exc
                        reporting.ShowWarning('PTKImageDatabase:AddDatasetFailed', ['An error occured when adding dataset ' temporary_uid ' to the databse. Error: ' exc.message], exc);
                    end
                end                
            end
            
            
            if database_changed || obj.GetAndResetVersionChanged
                reporting.UpdateProgressAndMessage(100, 'Saving changes to database');
                obj.InvalidateCachedPaths;
                obj.SaveDatabase(reporting);
            end
            
            reporting.CompleteProgress;
        end
        
        function SaveDatabase(obj, reporting)
            database_filename = PTKDirectories.GetImageDatabaseFilePath;
            
            try
                value = [];
                value.database = obj;
                PTKDiskUtilities.Save(database_filename, value);
            catch ex
                reporting.ErrorFromException('PTKImageDatabase:FailedtoSaveDatabaseFile', ['Unable to save database file ' database_filename], ex);
            end
        end
    end
    
    methods (Access = private)
        function has_changed = GetAndResetVersionChanged(obj)
            has_changed = obj.VersionHasChanged;
            obj.VersionHasChanged = false;
        end
        
        function InvalidateCachedPaths(obj)
            obj.CachedSortedPaths = [];
            obj.CachedSortedUids = [];            
        end
        
        function AddPatient(obj, patient_name, patient_id)
            obj.PatientMap(patient_id) = PTKImageDatabasePatient(patient_name, patient_id);
        end
        
    end
    
    methods (Static)
        function database = LoadDatabase(reporting)
            try
                database_filename = PTKDirectories.GetImageDatabaseFilePath;
                if exist(database_filename, 'file')
                    database_struct = PTKDiskUtilities.Load(database_filename);
                    database = database_struct.database;
                    database.IsNewlyCreated = false;
                    database.VersionHasChanged = isempty(database.Version) || (database.Version ~= PTKImageDatabase.CurrentVersionNumber);
                    
                    % Version 3 has changes to the maps used to store filenames; this requires a
                    % rebuild of the image database
                    if database.Version == 2
                        database.Rebuild([], true, reporting);
                    end
                    
                    database.Version = PTKImageDatabase.CurrentVersionNumber;
                else
                    reporting.ShowWarning('PTKImageDatabase:DatabaseFileNotFound', 'No image database file found. Will create new one on exit', []);
                    database = PTKImageDatabase;
                    database.IsNewlyCreated = true;
                end
                
                if database.IsNewlyCreated
                    database.Rebuild([], true, reporting);
                end
                
            catch ex
                reporting.ErrorFromException('PTKImageDatabase:FailedtoLoadDatabaseFile', ['Error when loading database file ' database_filename '. Try deleting this file.'], ex);
            end
        end
        
    end
    
end