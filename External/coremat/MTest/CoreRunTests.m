function CoreRunTests(testsOrDirectory)
    % CoreRunTests Runs MTest unit tests for Matlab
    %
    % Executes the specified unit tests and reports on the sucess and
    % failures.
    %
    % Syntax:
    %     CoreRunTests(testsOrDirectory);
    %
    %         testsOrDirectory - a folder or a cell array of strings, each containing the name of a test to run
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    if (nargin > 0) && ~isempty(testsOrDirectory)
        if iscell(testsOrDirectory)
            testClasses = testsOrDirectory;
        elseif CoreDiskUtilities.DirectoryExists(testsOrDirectory)
            testClasses = CoreDiskUtilities.GetListOfClassFiles(testsOrDirectory, 'CoreTest');
        elseif ischar(testsOrDirectory) && exist(testsOrDirectory, 'class') == 8
            testClasses = {testsOrDirectory};
        else
            throw(MException('CoreRunTests:UnrecognisedArgument', 'Please specify a test directory or a set of test class names to run'));
        end
        RunTests(testClasses);
    else
        disp('Please specify a test directory or a set of test class names to run');
    end
end

function RunTests(testClasses)
    numTests = numel(testClasses);
    if numTests == 1
        testString = 'test';
    else
        testString = 'tests';
    end
    disp(['Running ' testString '...']);
    passed = 0;
    failed = 0;
    
    for testClass = testClasses
        testClassName = testClass{1};
        try
            classHandle = feval(testClassName);
            classHandle.delete();
            disp([' + Passed: ' char(testClassName)]);
            passed = passed + 1;
        catch ex
            disp(['***** FAILED: ' char(testClassName)]);
            failed = failed + 1;
        end
    end
    disp(['Complete. ' int2str(failed+passed) ' ' testString ' run. ' int2str(passed) ' passed. ' int2str(failed) ' failed. ' ]);
end