classdef PTKImageDatabasePatient < handle
    % PTKImageDatabasePatient. Part of the internal framework of the Pulmonary Toolkit.
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
    
    properties (SetAccess = private)
        Name
        VisibleName
        ShortVisibleName
        PatientId
        SeriesMap
    end
    
    methods
        function obj = PTKImageDatabasePatient(name, id)
            if nargin > 0  
                obj.Name = name;
                obj.PatientId = id;
                obj.SetVisibleNames(name, id);
                obj.SeriesMap = containers.Map;
            end
        end
        
        function series = AddImage(obj, single_image_metainfo)
            series_id = single_image_metainfo.SeriesUid;
            if ~obj.SeriesMap.isKey(series_id)
                obj.AddSeries(series_id, single_image_metainfo);
            end
            series = obj.SeriesMap(series_id);
            series.AddImage(single_image_metainfo);            
        end
        
        function AddSeries(obj, series_id, single_image_metainfo)
            obj.SeriesMap(series_id) = PTKImageDatabaseSeries(single_image_metainfo.SeriesDescription, single_image_metainfo.StudyDescription, single_image_metainfo.Modality, single_image_metainfo.Date, single_image_metainfo.Time, series_id, single_image_metainfo.PatientId);
        end
        
        function DeleteSeries(obj, series_uid)
            obj.SeriesMap.remove(series_uid)
        end
        
        
        function series = GetListOfSeries(obj)
            series = obj.SeriesMap.values;
            dates = PTKContainerUtilities.GetFieldValuesFromSet(series, 'Date');
            times = PTKContainerUtilities.GetFieldValuesFromSet(series, 'Time');
            date_time = strcat(dates, times);
            
            % Remove any empty values to ensure sort works
            empty_values = cellfun(@isempty, date_time);
            date_time(empty_values) = {''};

            [~, sorted_indices] = PTKTextUtilities.SortFilenames(date_time);
            series = series(sorted_indices);
        end
        
        function num_series = GetNumberOfSeries(obj)
            num_series = double(obj.SeriesMap.Count);
        end
        
    end
    
    methods (Access = private)
        function SetVisibleNames(obj, name, id)
            [visible_name, short_visible_name] = PTKDicomUtilities.PatientNameToString(name);
            if isempty(visible_name)
                if isempty(id)
                    visible_name = 'Unknown';
                else
                    visible_name = id;
                end
            end
            if isempty(short_visible_name)
                if isempty(id)
                    short_visible_name = 'Unknown';
                else
                    short_visible_name = id;
                end
            end
            obj.VisibleName = visible_name;
            obj.ShortVisibleName = short_visible_name;
        end
    end
    
    methods (Static)
        function obj = loadobj(obj)
            % This method is called when the object is loaded from disk.
            % If the visible names are not set then set them now
            if isempty(obj.ShortVisibleName) || isempty(obj.VisibleName)
                obj.SetVisibleNames(obj.Name, obj.PatientId);
            end
        end
    end
end