classdef PTKFileGrouping < handle
    % PTKFileGrouping. Stores a set of Dicom metadata structures, corresponding
    %     to a coherent sequence of images
    %
    %     PTKFileGrouping objects are created by the PTKFileGrouper class,
    %     which separates and groups images into coherent sequences according to
    %     their metadata.
    %        
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
        
    properties (SetAccess = private)
        Metadata
    end
    
    methods
        function obj = PTKFileGrouping(metadata)
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
            match = PTKAreImagesInSameGroup(obj.Metadata{1}, other_metadata);
        end

        % Sorts the images according to slice location, and computes values for
        % slice thickness and global origin
        function [slice_thickness, global_origin_mm] = SortAndGetParameters(obj, reporting)
            [sorted_indices, slice_thickness, global_origin_mm] = PTKSortImagesByLocation(obj, reporting);
            if numel(obj.Metadata) > 1
                if isempty(sorted_indices)
                    reporting.ShowWarning('PTKFileGrouping:UnableToSortFiles', 'The images in this series may appear in the wrong order because I was unable to determine the correct ordering');
                else
                    obj.Metadata = obj.Metadata(sorted_indices);
                end
            end
        end
    end
end

