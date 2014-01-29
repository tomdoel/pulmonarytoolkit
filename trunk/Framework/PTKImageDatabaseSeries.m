classdef PTKImageDatabaseSeries < handle
    % PTKImageDatabaseSeries.
    %
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
    
    properties (SetAccess = private)
        Name
        StudyName
        ImageMap
        Modality
        Date
        Time
        SeriesUid
        PatientId
        
        Version
        FirstImagePath
        ImageFileFormat
        StudyUid
        
    end
    
    methods
        function obj = PTKImageDatabaseSeries(series_id, single_image_metainfo)
            if nargin > 0
                obj.Name = single_image_metainfo.SeriesDescription;
                obj.StudyName = single_image_metainfo.StudyDescription;
                obj.Modality = single_image_metainfo.Modality;
                obj.Date = single_image_metainfo.Date;
                obj.Time = single_image_metainfo.Time;
                obj.SeriesUid = series_id;
                obj.PatientId = single_image_metainfo.PatientId;
                
                obj.FirstImagePath = single_image_metainfo.ImagePath;
                obj.ImageFileFormat = single_image_metainfo.ImageFileFormat;
                obj.StudyUid = single_image_metainfo.StudyUid;
                
                obj.ImageMap = containers.Map;
                
                obj.Version = obj.CurrentVersionNumber;
            end
        end
        
        function AddImage(obj, single_image_metainfo)
            obj.ImageMap(single_image_metainfo.ImageUid) = PTKFilename(single_image_metainfo.ImagePath, single_image_metainfo.ImageFilename);
        end
        
        function num_images = NumberOfImages(obj)
            num_images = obj.ImageMap.Count;
        end
        
        function image_info = GetImageInfo(obj)
            filenames_cells = [];
            filenames_objects = obj.ImageMap.values;
            for image_index = 1 : numel(filenames_objects);
                filenames_cells{end + 1} = filenames_objects{image_index};
            end
            path = obj.FirstImagePath;
            image_type = obj.ImageFileFormat;
            uid = obj.SeriesUid;
            study_uid = obj.StudyUid;
            modality = obj.Modality;
            image_info = PTKImageInfo(path, filenames_cells, image_type, uid, study_uid, modality);
        end
        
    end
    
    
    methods (Static)
        function obj = loadobj(obj)
            % This method is called when the object is loaded from disk.
            
            % In the first implementation, the ImageMap was a map of image
            % uids to image metainfo. Now we replace it with a simple list of
            % PTKFilename objects
            if isempty(obj.Version)
                image_infos = obj.ImageMap.values;
                
                % These propeties did not exist in the first version of the
                % class
                obj.FirstImagePath = image_infos{1}.ImagePath;
                obj.ImageFileFormat = image_infos{1}.ImageFileFormat;
                obj.StudyUid = image_infos{1}.StudyUid;
        
                filenames = containsers.Map;
                for image_index = 1 : numel(image_infos);
                    single_image_info = image_infos{image_index};
                    filenames(single_image_info.ImageUid) = PTKFilename(single_image_info.ImagePath, single_image_info.ImageFilename);
                end
                
                % Replace the map with the array of PTKFilename objects
                obj.ImageMap = filenames;
                
                obj.Version = obj.CurrentVersionNumber;
                
            elseif (obj.Version == 2)
                % Version 3 changes the image list to a map to UIDs
                % The database will be rebuilt, so the following is a temporary change to get the
                % database in a good state before the rebuild happens
                image_map = containers.Map;
                for image_index = 1 : numel(obj.ImageMap);
                    image_uid = int2str(image_index);
                    image_map(image_uid) = obj.ImageMap(image_index);
                end
                obj.ImageMap = image_map;
                
                obj.Version = obj.CurrentVersionNumber;
            end
        end
    end
    
end