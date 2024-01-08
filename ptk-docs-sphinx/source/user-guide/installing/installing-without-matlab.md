# Installing the Pulmonary Toolkit without Matlab

If you do not need to develop your own plugins and scripts, you can run the Pulmonary Toolkit without a Matlab license by installing a [pre-built release](https://github.com/tomdoel/pulmonarytoolkit/releases)

```{warning} Pre-built releases are not available for the latest versions of the Pulmonary Toolkit. The available versions do not have the latest featuers and bug fixes.
```

Each release has two executables; the PTK GUI runs the full graphical user interface, or you can use PTK Command-Line to run pre-compiled scripts from a command prompt/terminal window or batch file/shell script.

The pre-built releases are compiled using specific versions of Matlab. In order to run them, you will need to install the free Matlab Runtime (MCR) for the exact same version of Matlab. On Windows, you also need to install the free Visual C++ Redistributable. Details are provided on the release page: https://github.com/tomdoel/pulmonarytoolkit/releases
Pre-built releases do not provide an update mechanism, and you cannot write your own plugins or scripts.



You can also compile PTK yourself. Compiling PTK requires a Matlab license, but using the compiled version does not require a license.

Running compiled version requires the following:
 * The free Matlab MCR to be installed, which MUST match the version of Matlab used to compile PTK.
 * (Windows only): the Visual Studio runtime distributable which matches the version of Visual Studio used to compile PTK
 * the compiled PTK files: e.g. `PulmonaryToolkit.exe` and `PulmonaryToolkitApi.exe` or equivalent for macOS/linux
 * (macOS/Linux) - certain environment variables might need to be set in order to locate the correct version of the Matlab MCR - see Mathworks documentation for more details

If no pre-compiled versions are available, you can compile PTK yourself. If you wish to run your own PTKScripts or plugins, you will also need to compile PTK yourself, since PTK can only run scripts and plugins included in the compilation (this is a restriction of the Matlab compiler). Compiling PTK requires Matlab, but once compiled, the compiled version can be run without a Matlab licence.

`PulmonaryToolkit.exe` runs the graphical user interface (GUI)
`PulmonaryToolkitApi.exe` runs a specified PTKScript using the API. The PTKScript must be compiled into the application (see above). When running `PulmonaryToolkitApi.exe` specify the script as the first argument, and then any additional arguments that your script requires.
