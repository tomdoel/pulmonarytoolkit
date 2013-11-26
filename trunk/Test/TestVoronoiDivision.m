classdef TestVoronoiDivision < PTKTest
    % TestVoronoiDivision. Tests for the PTKVoronoiDivision class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestVoronoiDivision
            mock_reporting = MockReporting;
            labels_1 = {[1, 5, 21, 25], [126, 130, 146 150]};
            expected_output_1 = zeros([5,5,6], 'uint8');
            expected_output_1(1:75) = 1;
            expected_output_1(76:150) = 2;
            
            obj.CheckVoronoi(labels_1, expected_output_1, mock_reporting);
            obj.CheckArguments(labels_1, expected_output_1, mock_reporting);
        end
        
        function CheckVoronoi(obj, labels, expected_output, reporting)
            region_mask = PTKImage(zeros([5, 5, 6], 'uint8'));
            
            % Test list input
            label_matrix = PTKVoronoiDivision(region_mask, labels, reporting);
            obj.Assert(isequal(label_matrix.RawImage, expected_output), 'Label matrix set correctly');
            
            % Test image input
            initial_label_image = PTKCoordListToLabelMatrix(labels, region_mask, reporting);
            label_matrix = PTKVoronoiDivision(region_mask, initial_label_image, reporting);
            obj.Assert(isequal(label_matrix.RawImage, expected_output), 'Label matrix set correctly');            
        end
        
        function CheckArguments(obj, labels, expected_output, reporting)
            
            % Test non-PTKImage input
            reporting.AddExpectation('MockReporting.Error', 'PTKVoronoiDivision:BadInput');
            try
                label_matrix = PTKVoronoiDivision(zeros(5,5,5), labels, reporting);
            catch ex
                if ~isa(ex, 'PTKTestException')
                    PTKErrorUtilities.ThrowException('TestImageTemplates:WrongException', 'Test failure: test exception expected');
                    
                end
            end
            
            region_mask = PTKImage(zeros([5, 5, 6], 'uint8'));
            reporting.AddExpectation('MockReporting.Error', 'PTKVoronoiDivision:BadInput');
            try
                label_matrix = PTKVoronoiDivision(region_mask, zeros(5,5,5), reporting);
            catch ex
                if ~isa(ex, 'PTKTestException')
                    PTKErrorUtilities.ThrowException('TestImageTemplates:WrongException', 'Test failure: test exception expected');
                    
                end
            end
            
        end
    end    
end

