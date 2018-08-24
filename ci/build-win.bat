setlocal EnableDelayedExpansion

set MATLAB_EXE=%1
set MATLAB_SCRIPT=%2

echo Running script %MATLAB_SCRIPT% using executable %MATLAB_EXE% on Windows
echo Path: %PATH%

set MATCOMMAND="try, run('%MATLAB_SCRIPT%'), catch ex, system(['ECHO Exception during %MATLAB_SCRIPT%: ' ex.message]), exit(1), end, exit(0);"
%MATLAB_EXE% -wait -nodisplay -nosplash -nodesktop -logfile ci-output.log -r %MATCOMMAND%
set LEVEL=!ERRORLEVEL!
if exist ci-output.log (
    type ci-output.log
) else (
    echo Log file not found
)
echo ...end of log file


if not "!LEVEL!" == "0" (
    echo ERROR: Exit Code = !LEVEL!
	exit /b 1
)
