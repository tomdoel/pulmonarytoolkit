# Running PTK from the command line

PTK can be run from the command line, or from scripts or batch files in your system. If you have Matlab installed on your system, you can use the Matlab executable to run PTK. This runs PTK the same way as if you were running from within Matlab, so it gives you access to all of your custom Plugins or code modifications.

If you want to run PTK without calling Matlab, you will need to either obtain a pre-compiled release for your system from the GitHub site, or you will need to compile PTK yourself into executables using Matlab on the same machine or a compatible platform. You will need to compile PTK yourself if you want to customise the code or run your own Plugins. Running a compiled version of PTK does not require a Matlab license, but it does require the free Matlab MCR software to be installed. Compiling your own version of PTK requires a Matlab compiler license.

In all cases, you can either run the PTK GUI application in an interactive mode, or you can run PTK is a non-iterative mode where you specify a PTKScript file to be executed.


## How to start the PTK GUI from the command line using Matlab

### From the macOS terminal

You need a command similar to this (replace with your Matlab version and the path to `PulmonaryToolkit.m`)

    /Applications/MATLAB_R2015b.app/bin/matlab -nosplash -nodesktop -r "run('/PATH_TO_PTK/PulmonaryToolkit.m');"


### From the Linux terminal

You may need to set `LD_PRELOAD`, for example:

    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/local/R2015b/bin/matlab -nosplash -nodesktop -r "run('/PATH_TO_PTK/PulmonaryToolkit.m');"


### From the Windows Command Prompt

    "C:\Program Files\MATLAB\R2015b\bin\matlab.exe" -wait -nosplash -nodesktop -r "run('/PATH_TO_PTK/PulmonaryToolkit.m');"


## Running a PTK Script in a non-interactive mode

If you want to execute a PTKScript and you don't want to bring up the GUI, then you can run the above commands but do the following:

* Replace `PulmonaryToolkit.m` with `PulmonaryToolkitApi.m` to run the API
* You must add arguments to the `PulmonaryToolkitApi` function call. The first argument is the name of the PTKScript to run. Subsequent arguments are those required by the script.
* You can add a `-nodisplay` option to the `Matlab` call, as you don't need a GUI


### Example batch file for running a PTKScript

Here is a sample batch script illustrating how to return error codes for successful completion or failure of a PTKScript.  (Note: this is not a tested example, it is just for illustration)

    echo Running script
    call "C:\Program Files\MATLAB\R2015b\bin\matlab.exe" -wait -nodisplay -nosplash -nodesktop -r "try, cd('PATH_TO_PTK'), PulmonaryToolkitApi SCRIPTNAME ARGUMENTS, catch ex, disp(['Exception during PulmonaryToolkitApi.m: ' ex.message]), exit(1), end,     exit(0);"

    if not "%ERRORLEVEL%" == "0" (
        echo Exit Code = %ERRORLEVEL%
	    exit /b 1
    )


### Example bash script for running a PTKScript

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


## Running PTK without Matlab

You can run PTK without having Matlab installed by using a compiled version of PTK.
You can find pre-compiled versions of PTK for Windows, Linux and macOS under the GitHub [releases](https://github.com/tomdoel/pulmonarytoolkit/releases) page. You can also compile PTK yourself compile. Compiling PTK requires a Matlab license, but using the compiled version does not require a license.

Running compiled version requires the following:
 * The free Matlab MCR to be installed, which MUST match the version of Matlab used to compile PTK.
 * (Windows only): the Visual Studio runtime distributable which matches the version of Visual Studio used to compile PTK
 * the compiled PTK files: e.g. `PulmonaryToolkit.exe` and `PulmonaryToolkitApi.exe` or equivalent for macOS/linux
 * (macOS/Linux) - certain environment variables might need to be set in order to locate the correct version of the Matlab MCR - see Mathworks documentation for more details

In each release, two executables are included for each platform (Windows, Linux, macOS). On Windows the executables have `exe` and on macOS they have extension `app`. On Linux and macOS you may need to run the accompanying shell scripts (`.sh`) in order to correctly invoke the MCR.
 - `PulmonaryToolkit` runs the graphical user interface (GUI).
 - `PulmonaryToolkitApi` runs a specified PTKScript using the API. The PTKScript must be compiled into the application (see above). When running `PulmonaryToolkitApi.exe` specify the script as the first argument, and then any additional arguments that your script requires.



### Compiling PTK yourself

You can compile PTK yourself by running the `CompilePTK` script from within Matlab. This requires the Matlab compiler.
Compiling PTK yourself will include your own Plugins and modifications into the compilation, provided the source files are within the PTK directory structure.

Running your own compiled version of PTK has the same requirements as running a pre-compiled version, namely the appropriate MCR or an equivalent version of Matlab must be installed on the target machine.

NB. Don't confuse compiling of PTK with compiling of mex files. Compiling of mex files is a standard part of running PTK, whereas compiling PTK is something you only need to do if you are need to generate a stand-alone PTK executable and the pre-built ones are not suitable.
