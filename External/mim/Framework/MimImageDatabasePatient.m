classdef MimImageDatabasePatient < handle
    % MimImageDatabasePatient. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        Name
        VisibleName
        ShortVisibleName
        PatientId
        SeriesMap
    end
    
    methods
        function obj = MimImageDatabasePatient(name, id)
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
            obj.SeriesMap(series_id) = MimImageDatabaseSeries(series_id, single_image_metainfo);
        end
        
        function DeleteSeries(obj, series_uid)
            obj.SeriesMap.remove(series_uid);
        end
        
        
        function series = GetListOfSeries(obj)
            series = obj.SeriesMap.values;
            dates = CoreContainerUtilities.GetFieldValuesFromSet(series, 'Date');
            times = CoreContainerUtilities.GetFieldValuesFromSet(series, 'Time');
            date_time = strcat(dates, times);
            
            % Remove any empty values to ensure sort works
            empty_values = cellfun(@isempty, date_time);
            date_time(empty_values) = {''};

            [~, sorted_indices] = CoreTextUtilities.SortFilenames(date_time);
            series = series(sorted_indices);
        end
        
        function num_series = GetNumberOfSeries(obj)
            num_series = double(obj.SeriesMap.Count);
        end
        
    end
    
    methods (Access = private)
        function SetVisibleNames(obj, name, id)
            [visible_name, short_visible_name] = DMUtilities.PatientNameToString(name);
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
        function obj = loadobj(a)
            % This method is called when the object is loaded from disk.
            
            if isa(a, 'MimImageDatabasePatient')
                obj = a;
            else
                % In the case of a load error, loadobj() gives a struct
                obj = MimImageDatabasePatient;
                for field = fieldnames(a)'
                    if isprop(obj, field{1})
                        mp = findprop(obj, (field{1}));
                        if (~mp.Constant) && (~mp.Dependent) && (~mp.Abstract) 
                            obj.(field{1}) = a.(field{1});
                        end
                    end
                end
            end
            
            % If the visible names are not set then set them now
            if isempty(obj.ShortVisibleName) || isempty(obj.VisibleName)
                obj.SetVisibleNames(obj.Name, obj.PatientId);
            end
        end
    end
end