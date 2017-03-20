classdef PTKImageDatabaseSeries
    % PTKImageDatabaseSeries. Legacy support class for backwards compatibility. Replaced by MimImageDatabaseSeries
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    methods (Static)
        function obj = loadobj(obj)
            % This method is called when the object is loaded from disk.
            
            if ~isfield(obj, 'Version')
                obj.Version = [];
            end
            
            % In the first implementation, the ImageMap was a map of image
            % uids to image metainfo. Now we replace it with a simple list of
            % CoreFilename objects
            if isempty(obj.Version)
                image_infos = obj.ImageMap.values;
                
                % These propeties did not exist in the first version of the
                % class
                obj.FirstImagePath = image_infos{1}.ImagePath;
                obj.ImageFileFormat = image_infos{1}.ImageFileFormat;
                obj.StudyUid = image_infos{1}.StudyUid;
        
                filenames = containers.Map;
                for image_index = 1 : numel(image_infos)
                    single_image_info = image_infos{image_index};
                    filenames(single_image_info.ImageUid) = CoreFilename(single_image_info.ImagePath, single_image_info.ImageFilename);
                end
                
                % Replace the map with the array of CoreFilename objects
                obj.ImageMap = filenames;
                
                obj.Version = obj.CurrentVersionNumber;
                
            elseif (obj.Version == 2)
                % Version 3 changes the image list to a map to UIDs
                % The database will be rebuilt, so the following is a temporary change to get the
                % database in a good state before the rebuild happens
                image_map = containers.Map;
                for image_index = 1 : numel(obj.ImageMap)
                    image_uid = int2str(image_index);
                    image_map(image_uid) = obj.ImageMap(image_index);
                end
                obj.ImageMap = image_map;
                
                obj.Version = obj.CurrentVersionNumber;
            end
            
            obj = MimImageDatabaseSeries.loadobj(obj);
        end
    end
    
end