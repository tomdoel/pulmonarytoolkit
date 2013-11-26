classdef TestCoordListToLabelMatrix < PTKTest
    % PTKCoordListToLabelMatrix. Tests for the PTKCoordListToLabelMatrix class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestCoordListToLabelMatrix
            mock_reporting = MockReporting;
            obj.CheckLabels({[1, 3, 5], [2, 44, 80], [13, 125]}, mock_reporting);
            obj.CheckLabels({[1, 5], [2, 44, 80, 33, 12, 3]}, mock_reporting);
        end
        
        function CheckLabels(obj, labels, reporting)
            template = PTKImage(zeros([5,5,5], 'uint8'));
            label_matrix = PTKCoordListToLabelMatrix(labels, template, reporting);
            
            all_points = [];
            for label_set_index = 1 : numel(labels)
                labels_set = labels{label_set_index};
                all_points = [all_points labels_set];
                for index = labels_set
                    value = label_matrix.RawImage(index);
                    obj.Assert(isequal(value, label_set_index), 'Label matrix set correctly');
                end
            end
            
            all_points = unique(all_points);
            num_points_in_image = sum(label_matrix.RawImage(:) > 0);
            obj.Assert(isequal(numel(all_points), num_points_in_image), 'Total number of points as expected');
        end
    end    
end

