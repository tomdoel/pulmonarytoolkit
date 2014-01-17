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
        CurrentVersionNumber = 2
    end
    
    properties (SetAccess = private)
        Name
        StudyName
        ImageMap % Array of PTKFilename objects
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
                
                obj.ImageMap = PTKFilename.empty;
                
                obj.Version = obj.CurrentVersionNumber;
            end
        end
        
        function AddImage(obj, single_image_metainfo)
            obj.ImageMap(end + 1) = PTKFilename(single_image_metainfo.ImagePath, single_image_metainfo.ImageFilename);
        end
        
        function num_images = NumberOfImages(obj)
            num_images = numel(obj.ImageMap);
        end
        
        function image_info = GetImageInfo(obj)
            filenames_cells = [];
            filenames_objects = obj.ImageMap;
            for image_index = 1 : numel(filenames_objects);
                filenames_cells{end + 1} = filenames_objects(image_index);
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
        
                filenames = PTKFilename.empty;
                for image_index = 1 : numel(image_infos);
                    single_image_info = image_infos{image_index};
                    filenames(end + 1) = PTKFilename(single_image_info.ImagePath, single_image_info.ImageFilename);
                end
                
                % Replace the map with the array of PTKFilename objects
                obj.ImageMap = filenames;
                
                obj.Version = obj.CurrentVersionNumber;
                
            end
        end
    end
    
end