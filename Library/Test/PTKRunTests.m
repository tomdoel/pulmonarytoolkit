function PTKRunTests(tests_to_run)
    % PTKRunTests. Part of the PTK test framework
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    if (nargin > 0) && ~isempty(tests_to_run)
        if ischar(tests_to_run)
            test_classes = {tests_to_run};
        else
            test_classes = tests_to_run;
        end
    else
        test_directory = PTKDirectories.GetTestSourceDirectory;
        test_classes = PTKDiskUtilities.GetListOfClassFiles(test_directory, 'PTKTest');
    end
    RunTests(test_classes);
end

function RunTests(test_classes)
    num_tests = numel(test_classes);
    if num_tests == 1
        test_string = 'test';
    else
        test_string = 'tests';
    end
    disp(['Running ' test_string '...']);
    passed = 0;
    failed = 0;
    
    for test_class = test_classes
        test_class_name = test_class{1};
        try
            class_handle = feval(test_class_name);
            class_handle.delete();
            disp([' + Passed: ' char(test_class_name)]);
            passed = passed + 1;
        catch ex
            disp(['***** FAILED: ' char(test_class_name)]);
            failed = failed + 1;
        end
    end
    disp(['Complete. ' int2str(failed+passed) ' ' test_string ' run. ' int2str(passed) ' passed. ' int2str(failed) ' failed. ' ]);
end