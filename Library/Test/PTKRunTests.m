function PTKRunTests(tests_or_folder)
    % PTKRunTests. Runs PTK unit tests
    %
    %     tests_to_run - All tests will be run if this argument is omitted
    %     
    %     
    %
    % Executes all the tests that can be found and reports on the sucess and
    % failures.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    if (nargin == 0) || isempty(tests_or_folder)
        tests_or_folder = PTKDirectories.GetTestSourceDirectory;
    end
        
    CoreRunTests(tests_or_folder);
end