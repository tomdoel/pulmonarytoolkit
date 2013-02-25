function PTKRunTests
    % PTKRunTests. Part of the PTK test framework
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
    
    test_directory = PTKDirectories.GetTestSourceDirectory;
    test_classes = PTKDiskUtilities.GetListOfClassFiles(test_directory, 'PTKTest');
    RunTests(test_classes);
end

function RunTests(test_classes)
    disp('Running tests...');
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
    disp(['Complete. ' int2str(failed+passed) ' tests run. ' int2str(passed) ' passed. ' int2str(failed) ' failed. ' ]);
end