classdef PTKFileGrouper < PTKBaseClass
    % PTKFileGrouper. Used to separate a series of Dicom images into groups of coherent images
    %
    %     PTKFileGrouper splits a series of Dicom images into 'bins' or 'groups'
    %     of images with similar orientations and image properties. For example,
    %     a series containing a scout image will typically be separated into a
    %     group containing the scan images and another group containing the
    %     scout image. Similarly, a localiser series containing images in multiple
    %     orientations will typically be separated into a separate group for
    %     each orientation. 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    
    properties (Access = private)
        FileGroupings
    end
    
    methods
        function obj = PTKFileGrouper
            obj.FileGroupings = PTKFileGrouping.empty;
        end
        
        % Adds a new image. If the metadata is coherent with an existing group,
        % we add the image to that group. Otherwise we create a new group.
        function AddFile(obj, metadata)
            grouping = obj.FindGrouping(metadata);
            if ~isempty(grouping)
                grouping.AddFile(metadata);
            else
                obj.NewGrouping(metadata);
            end
        end

        % Returns the number of groups in this data
        function number_of_groups = NumberOfGroups(obj)
            number_of_groups = numel(obj.FileGroupings);
        end

        % Return the PTKFileGrouping with the gretest number of images
        function largest_group = GetLargestGroup(obj)
            
            % Get the length of each group of metadata
            grouping_lengths = cellfun(@numel, {obj.FileGroupings.Metadata});
            
            % Sort the lengths in descending order
            [~, sort_index] = sort(grouping_lengths, 'descend');
            
            % Return the metadata sorted by length
            largest_group = obj.FileGroupings(sort_index(1));
        end

    end
    
    methods (Access = private)
        
        function grouping = FindGrouping(obj, metadata)
            for grouping = obj.FileGroupings
                if grouping.Matches(metadata)
                    return;
                end
            end
            grouping = [];
        end
        
        function NewGrouping(obj, metadata)
            obj.FileGroupings(end + 1) = PTKFileGrouping(metadata);
        end
        
    end
end