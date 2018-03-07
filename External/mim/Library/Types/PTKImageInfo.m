classdef PTKImageInfo
    % PTKImageInfo. A structure for holding information related to images
    %
    %     PTKImageInfo is used to specify data about the files that comprise a
    %     dataset. When importing new data, it is only necessary to specify the
    %     path, filenames and image type. When subsequently loading data,
    %     specifying the uids mean these don't have to be reloaded from the
    %     metadata.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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
        function obj = PTKImageInfo(path, filenames, image_type, uid, study_uid, modality)
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
            elseif isstruct(value)
                if isfield(value, 'ValueNames') && numel(value.ValueNames) == 1
                    obj.ImageFileFormat = MimImageFileFormat.(value.ValueNames{1});
                else
                    obj.ImageFileFormat = [];
                end
            else
                obj.ImageFileFormat = value;
            end
        end
    end
    
    methods (Static)
        % Copies values from another PTKImageInfo object, but only those
        % properies which are not empty
        function [new_info, anything_changed] = CopyNonEmptyFields(image_info, other_image_info)
            new_info = image_info;
            anything_changed = false;
            metaclass = ?PTKImageInfo;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list)
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

