classdef DMFileGrouping < CoreBaseClass
    % DMFileGrouping. Stores a set of Dicom metadata structures, corresponding
    %     to a coherent sequence of images
    %
    %     DMFileGrouping objects are created by the DMFileGrouper class,
    %     which separates and groups images into coherent sequences according to
    %     their metadata.
    %        
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %    
        
    properties (SetAccess = private)
        Metadata
    end
    
    methods
        function obj = DMFileGrouping(metadata)
            if ~isempty(metadata)
                obj.Metadata{1} = metadata;
            end
        end
        
        function AddFile(obj, metadata)
            obj.Metadata{end + 1} = metadata;
        end
        
        % Determine if a file with specified metadata should be grouped with
        % these files
        function match = Matches(obj, other_metadata)
            
            if numel(obj.Metadata) > 1
                additional_image = obj.Metadata{2};
            else
                additional_image = [];
            end
            
            match = DMAreImagesInSameGroup(obj.Metadata{1}, other_metadata, additional_image);
        end
        

        % Sorts the images according to slice location, and computes values for
        % slice thickness and global origin
        function [slice_thickness, global_origin_mm, sorted_positions] = SortAndGetParameters(obj, reporting)
            [sorted_indices, slice_thickness, global_origin_mm, sorted_positions] = DMSortImagesByLocation(obj, reporting);
            if numel(obj.Metadata) > 1
                if isempty(sorted_indices)
                    reporting.ShowWarning('DMFileGrouping:UnableToSortFiles', 'The images in this series may appear in the wrong order because I was unable to determine the correct ordering');
                else
                    obj.Metadata = obj.Metadata(sorted_indices);
                end
            end
        end
    end
end

