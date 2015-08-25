classdef TestImageCoordinateUtilities < PTKTest
    % TestImageCoordinateUtilities. Tests for the PTKImageCoordinateUtilities class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestImageCoordinateUtilities
            mock_reporting = MockReporting;
            
            obj.TestGetDimensionPermutationVectorFromDicomOrientation(mock_reporting);
            obj.TestGetDimensionIndicesAsArray(mock_reporting);
            obj.TestGetDimensionIndicesFromOrientations(mock_reporting);
        end
        
        function TestGetDimensionPermutationVectorFromDicomOrientation(obj, mock_reporting)
            
            % Test GetDimensionPermutationVectorFromDicomOrientation
            obj.Assert(isequal(PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation([1 0 0 0 1 0]', mock_reporting), [1, 2, 3]), 'Expected result');
            obj.Assert(isequal(PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation([1 0 0 0 0 1]', mock_reporting), [3, 2, 1]), 'Expected result');
            obj.Assert(isequal(PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation([0 1 0 0 0 1]', mock_reporting), [2, 3, 1]), 'Expected result');
            obj.Assert(isequal(PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation([0.9964, -0.0851, 0, 0, 0, -1.0000]', mock_reporting), [3, 2, 1]), 'Expected result');

        end
        
        function TestGetDimensionIndicesAsArray(obj, mock_reporting)
        
            % Test with rows
            obj.Assert(isequal([1,2,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([1,0,0], [0,1,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,1,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,1,0], [1,0,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,1,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,1], [1,0,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([1,3,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([1,0,0], [0,0,1], mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,3,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,1,0], [0,0,1], mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,2,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,1], [0,1,0], mock_reporting)), 'Expected result');

            % Test with columns
            obj.Assert(isequal([1,2,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([1,0,0]', [0,1,0]', mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,1,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,1,0]', [1,0,0]', mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,1,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,1]', [1,0,0]', mock_reporting)), 'Expected result');
            obj.Assert(isequal([1,3,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([1,0,0]', [0,0,1]', mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,3,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,1,0]', [0,0,1]', mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,2,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,1]', [0,1,0]', mock_reporting)), 'Expected result');

            % Test with negatives
            obj.Assert(isequal([1,2,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([-1,0,0], [0,-1,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,1,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,-1,0], [-1,0,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,1,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,-1], [-1,0,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([1,3,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([-1,0,0], [0,0,-1], mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,3,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,-1,0], [0,0,-1], mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,2,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,-1], [0,-1,0], mock_reporting)), 'Expected result');
            
            obj.Assert(isequal([1,2,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([-1,0,0], [0,1,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,1,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,-1,0], [1,0,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,1,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,-1], [1,0,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([1,3,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([-1,0,0], [0,0,1], mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,3,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,-1,0], [0,0,1], mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,2,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,-1], [0,1,0], mock_reporting)), 'Expected result');
            
            obj.Assert(isequal([1,2,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([1,0,0], [0,-1,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,1,3],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,1,0], [-1,0,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,1,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,1], [-1,0,0], mock_reporting)), 'Expected result');
            obj.Assert(isequal([1,3,2],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([1,0,0], [0,0,-1], mock_reporting)), 'Expected result');
            obj.Assert(isequal([2,3,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,1,0], [0,0,-1], mock_reporting)), 'Expected result');
            obj.Assert(isequal([3,2,1],TestImageCoordinateUtilities.GetDimensionIndicesAsArray([0,0,1], [0,-1,0], mock_reporting)), 'Expected result');
        end
        
        function TestGetDimensionIndicesFromOrientations(obj, mock_reporting)
            obj.Assert(isequal([1,2,3,0,0,1],TestImageCoordinateUtilities.GetCombinedDimensionPermutationVectorFromDicomOrientation([1,0,0,0,1,0], mock_reporting)), 'Expected result');
        end
    end
    
    methods (Static, Access = private)
        function dims_array = GetDimensionIndicesAsArray(v1, v2, reporting)
            [d1, d2, d3] = PTKImageCoordinateUtilities.GetDimensionIndicesFromOrientations(v1, v2, reporting);
            dims_array = [d1, d2, d3];
        end
        
        function combined_array = GetCombinedDimensionPermutationVectorFromDicomOrientation(orientation, reporting)
            [permutation_vector, flip] = PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation(orientation, reporting);
            combined_array = [permutation_vector, flip];
        end
    end
end

