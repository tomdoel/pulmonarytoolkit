# Running the Pulmonary Toolkit without Matlab

PTK can be run without a Matlab license by using a pre-bult release version of PTK.

You can find pre-compiled versions of PTK under the GitHub [releases](https://github.com/tomdoel/pulmonarytoolkit/releases) page.

```{warning} Pre-built releases are not available for the latest versions of the Pulmonary Toolkit. The available versions do not have the latest featuers and bug fixes.
```

You can also compile PTK yourself. Compiling PTK requires a Matlab license, but using the compiled version does not require a license. See [Compiling](../developer/compiling.md) for more details.

If you want to include your own plugins or scripts, or you need the latest PTK features and bug fixces, you will need to compile PTK yourself.

Running compiled version typically requires the following:
 * The free Matlab MCR to be installed, which MUST match the version of Matlab used to compile PTK.
 * (Windows only): the Visual Studio runtime distributable which matches the version of Visual Studio used to compile PTK
 * the compiled PTK files: e.g. `PulmonaryToolkit.exe` and `PulmonaryToolkitApi.exe` or equivalent for macOS/linux
 * (macOS/Linux) - certain environment variables might need to be set in order to locate the correct version of the Matlab MCR - see Mathworks documentation for more details

Pre-compiled releases include two executables:

* `PulmonaryToolkit.exe` runs the graphical user interface (GUI)
* `PulmonaryToolkitApi.exe` runs a specified PTKScript using the API. The PTKScript must be compiled into the application (see above). When running `PulmonaryToolkitApi.exe` specify the script as the first argument, and then any additional arguments that your script requires.


`PulmonaryToolkit.exe` launches the graphical user interface (GUI) application (the same as you would normally run by excecuting `ptk` from within Matlab). 
`PulmonaryToolkitApi.exe` runs a specified PTKScript using the API. The PTKScript must be compiled into the application (see above). When running `PulmonaryToolkitApi.exe` specify the script as the first argument, and then any additional arguments that your script requires.
