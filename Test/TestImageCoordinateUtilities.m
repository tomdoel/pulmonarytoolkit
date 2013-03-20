classdef TestImageCoordinateUtilities < PTKTest
    % TestImageCoordinateUtilities. Tests for the TestImageCoordinateUtilities class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestImageCoordinateUtilities
            mock_reporting = MockReporting;
            
            % Test GetDimensionPermutationVectorFromDicomOrientation
            obj.Assert(isequal(PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation([1 0 0 0 1 0]', mock_reporting), [1, 2, 3]), 'Expected result');
            obj.Assert(isequal(PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation([1 0 0 0 0 1]', mock_reporting), [3, 2, 1]), 'Expected result');
            obj.Assert(isequal(PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation([0 1 0 0 0 1]', mock_reporting), [2, 3, 1]), 'Expected result');
            obj.Assert(isequal(PTKImageCoordinateUtilities.GetDimensionPermutationVectorFromDicomOrientation([0.9964, -0.0851, 0, 0, 0, -1.0000]', mock_reporting), [3, 2, 1]), 'Expected result');
            
            % Test GetDimensionIndexFromOrientation
            obj.Assert(1 == PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation([1,0,0] , mock_reporting), 'Expected result');
            obj.Assert(1 == PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation([1,0,0]', mock_reporting), 'Expected result');
            obj.Assert(2 == PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation([0,1,0] , mock_reporting), 'Expected result');
            obj.Assert(2 == PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation([0,1,0]', mock_reporting), 'Expected result');
            obj.Assert(3 == PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation([0,0,1] , mock_reporting), 'Expected result');
            obj.Assert(3 == PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation([0,0,1]', mock_reporting), 'Expected result');
        end
    end    
end

