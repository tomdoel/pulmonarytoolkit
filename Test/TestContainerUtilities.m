classdef TestContainerUtilities < CoreTest
    % TestContainerUtilities. Tests for the PTKContainerUtilities class.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestContainerUtilities
            obj.TestConvertToSet;
        end
        
        function TestConvertToSet(obj)
            input_1 = 'banana';
            input_2 = {'apple'};
            input_3 = {'orange', 'kiwi', 'grape'};
            input_4 = [1, 2, 3, 4, 5];
            input_5 = [11, 12; 13, 14];
            input_6 = [CorePair('wx', 88), CorePair('yz', 99)];
            
            obj.Assert(isequal(CoreContainerUtilities.ConvertToSet(input_1), {'banana'}), 'Expected conversion');
            obj.Assert(~isequal(CoreContainerUtilities.ConvertToSet(input_1), 'banana'), 'Expected conversion');
            obj.Assert(isequal(CoreContainerUtilities.ConvertToSet(input_2), {'apple'}), 'Expected conversion');
            obj.Assert(isequal(CoreContainerUtilities.ConvertToSet(input_3), input_3), 'Expected conversion');
            obj.Assert(isequal(CoreContainerUtilities.ConvertToSet(input_4), {1, 2, 3, 4, 5}), 'Expected conversion');
            obj.Assert(isequal(CoreContainerUtilities.ConvertToSet(input_5), {11, 12; 13, 14}), 'Expected conversion');
            
            output_6 = CoreContainerUtilities.ConvertToSet(input_6);
            obj.Assert(iscell(output_6), 'Expected conversion');
            obj.Assert(strcmp(output_6{1}.First, 'wx'), 'Expected conversion');
            obj.Assert(output_6{1}.Second == 88, 'Expected conversion');
            obj.Assert(strcmp(output_6{2}.First, 'yz'), 'Expected conversion');
            obj.Assert(output_6{2}.Second == 99, 'Expected conversion');
        end
    end
end