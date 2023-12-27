classdef MimImageDatabaseSeries < handle
    % MimImageDatabaseSeries.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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
        function obj = MimImageDatabaseSeries(series_id, single_image_metainfo)
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
                
                obj.ImageMap = containers.Map();
                
                obj.Version = obj.CurrentVersionNumber;
            end
        end
        
        function visible_path = GetVisiblePath(obj)
            if obj.ImageMap.Count == 1
                filenames = obj.ImageMap.values();
                first_filename = filenames{1};
                visible_path = first_filename.FullFile;                
            else
                visible_path = obj.FirstImagePath;
            end
        end
        
        function AddImage(obj, single_image_metainfo)
            obj.ImageMap(single_image_metainfo.ImageUid) = CoreFilename(single_image_metainfo.ImagePath, single_image_metainfo.ImageFilename);
        end
        
        function num_images = NumberOfImages(obj)
            num_images = obj.ImageMap.Count;
        end
        
        function image_info = GetImageInfo(obj)
            filenames_cells = [];
            filenames_objects = obj.ImageMap.values();
            for image_index = 1 : numel(filenames_objects)
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
        function obj = loadobj(a)
            % This method is called when the object is loaded from disk.
            
            if isa(a, 'MimImageDatabaseSeries')
                obj = a;
            else
                % In the case of a load error, loadobj() gives a struct
                obj = MimImageDatabaseSeries;
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