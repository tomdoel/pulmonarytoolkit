classdef MimImageInfo
    % MimImageInfo. A structure for holding information related to images
    %
    %     MimImageInfo is used to specify data about the files that comprise a
    %     dataset. When importing new data, it is only necessary to specify the
    %     path, filenames and image type. When subsequently loading data,
    %     specifying the uids mean these don't have to be reloaded from the
    %     metadata.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties
        ImagePath
        ImageFilenames
        ImageFileFormat
        ImageUid
        StudyUid
        Modality
    end
    
    methods
        function obj = MimImageInfo(path, filenames, image_type, uid, study_uid, modality)
            if nargin > 0
                obj.ImagePath = path;
                obj.ImageFilenames = filenames;
                obj.ImageFileFormat = image_type;
                obj.ImageUid = uid;
                obj.StudyUid = study_uid;
                obj.Modality = modality;
            end
        end
        
        function obj = set.ImageFileFormat(obj, value)
            % Legacy conversion
            if isa(value, 'PTKImageFileFormat')
                obj.ImageFileFormat = value.MimImageFileFormat;                
            else
                obj.ImageFileFormat = value;
            end
        end
    end
    
    methods (Static)
        % Copies values from another MimImageInfo object, but only those
        % properies which are not empty
        function [new_info, anything_changed] = CopyNonEmptyFields(image_info, other_image_info)
            new_info = image_info;
            anything_changed = false;
            metaclass = ?MimImageInfo;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                other_value = other_image_info.(property.Name);
                if ~isempty(other_value)
                    if ~isequal(new_info.(property.Name), other_value)
                        new_info.(property.Name) = other_value;
                        anything_changed = true;
                    end
                end
            end
        end
    end
end

