classdef TestTextUtilities < CoreTest
    % TestImageTextUtilities. Tests for the PTKTextUtilities class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestTextUtilities
            % Test for StripFileparts method
            fs = filesep;
            filename_1 = ['Banana' fs 'Orange' fs 'MyName.ext'];
            filename_2 = ['Scott' fs 'Kubrick' fs 'NoName.bla'];
            both_filenames = {filename_1, filename_2};
            obj.Assert(strcmp('MyName', CoreTextUtilities.StripFileparts(filename_1)), 'Expected filename');
            obj.Assert(strcmp('NoName', CoreTextUtilities.StripFileparts(filename_2)), 'Expected filename');
            obj.Assert(strcmp({'MyName', 'NoName'}, CoreTextUtilities.StripFileparts(both_filenames)), 'Expected filename');
        end
    end
end