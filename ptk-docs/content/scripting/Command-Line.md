PTK can be run from the command line, or from scripts or batch files in your system. If you have Matlab installed on your system, you can use the Matlab executable to run PTK. If you want to run without calling Matlab, you will need to first compile PTK into executables using Matlab on the same machine or a compatible platform, or obtain a precompiled version suitable for your system. In either case, you can either run the PTK GUI application in an interactive mode, or you can run PTK is a non-iterative mode where you specify a PTKScript file to be executed.

# Running the PTK GUI via Matlab from the macOS terminal

You need a command similar to this (replace with your Matlab version and the path to `PulmonaryToolkit.m`)

    /Applications/MATLAB_R2015b.app/bin/matlab -nosplash -nodesktop -r "run('/PATH_TO_PTK/PulmonaryToolkit.m');"

# Running the PTK GUI via Matlab from the linux terminal

You may need to set `LD_PRELOAD`, for example:

    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/local/R2015b/bin/matlab -nosplash -nodesktop -r "run('/PATH_TO_PTK/PulmonaryToolkit.m');"

# Running PTK via Matlab from the Windows Command Prompt

    "C:\Program Files\MATLAB\R2015b\bin\matlab.exe" -wait -nosplash -nodesktop -r "run('/PATH_TO_PTK/PulmonaryToolkit.m');"

# Running a PTK Script in a non-interactive mode 

If you want to execute a PTKScript and you don't want to bring up the GUI, then you can run the above commands but do the following:

* Replace `PulmonaryToolkit.m` with `PulmonaryToolkitApi.m` to run the API 
* You must add arguments to the `PulmonaryToolkitApi` function call. The first argument is the name of the PTKScript to run. Subsequent arguments are those required by the script.
* You can add a `-nodisplay` option to the `Matlab` call, as you don't need a GUI

# Example batch file for running a PTKScript

Here is a sample batch script illustrating how to return error codes for successful completion or failure of a PTKScript.  (Note: this is not a tested example, it is just for illustration)

    echo Running script
    call "C:\Program Files\MATLAB\R2015b\bin\matlab.exe" -wait -nodisplay -nosplash -nodesktop -r "try, cd('PATH_TO_PTK'), PulmonaryToolkitApi SCRIPTNAME ARGUMENTS, catch ex, disp(['Exception during PulmonaryToolkitApi.m: ' ex.message]), exit(1), end,     exit(0);"

    if not "%ERRORLEVEL%" == "0" (
        echo Exit Code = %ERRORLEVEL%
	    exit /b 1
    )

# Example bash script for running a PTKScript

Here is a sample macOS bash script illustrating how to return error codes for successful completion or failure of a PTKScript. (Note: this is not a tested example, it is just for illustration)

    #!/bin/bash
    /Applications/MATLAB_R2015b.app/bin/matlab -nosplash -nodesktop -r "try, cd(PATH_TO_PATH), PulmonaryToolkitAPI SCRIPTNAME ARGUMENTS, catch ex, disp(['Exception when running PulmonaryToolkitAPI: ' ex.message]), exit(1), end, exit(0); "
    if [ $? -eq 0 ]; then
	echo "Success"
	exit 0;
    else
	echo "Failure"
	exit 1;
    fi


# Running PTK without Matlab

You can run PTK without having Matlab installed, but you will need to compile it first within Matlab, or obtain a precompiled version. 

NB. Please do not confuse the compiling of mex files (a standard part of running PTK) with the compiling of the PTK application (an additional process which you only need to perform to run PTK on a system without Matlab).

* You can compile PTK yourself by running the `CompilePTK` script from within Matlab. This requires the Matlab compiler
* You will need to install the Matlab MCR on the target machine. This must be the same version as the version of Matlab used to compile PTK. If you have a different version, you must also install the correct version of the MCR. You can have multiple versions of the MCR installed on one machine. MCRs are available free from the Mathworks website.
* On Windows, you may need to install the Visual Studio redistributable on the target machine. The redistributable is available free from the Microsoft website.
 



