# Running PTK without Matlab

_Added in PTK v0.6.6_

PTK can be run without a Matlab license by using a compiled version of PTK.
You can find pre-compiled versions of PTK under the GitHub [releases](https://github.com/tomdoel/pulmonarytoolkit/releases) page. You can also compile PTK yourself compile it yourself. Compiling PTK requires a Matlab license, but using the compiled version does not require a license.

Running compiled version requires the following:
 * The free Matlab MCR to be installed, which MUST match the version of Matlab used to compile PTK.
 * (Windows only): the Visual Studio runtime distributable which matches the version of Visual Studio used to compile PTK
 * the compiled PTK files: e.g. `PulmonaryToolkit.exe` and `PulmonaryToolkitApi.exe` or equivalent for macOS/linux
 * (macOS/Linux) - certain environment variables might need to be set in order to locate the correct version of the Matlab MCR - see Mathworks documentation for more details

If no pre-compiled versions are available, you can compile PTK yourself. If you wish to run your own PTKScripts or plugins, you will also need to compile PTK yourself, since PTK can only run scripts and plugins included in the compilation (this is a restriction of the Matlab compiler). Compiling PTK requires Matlab, but once compiled, the compiled version can be run without a Matlab licence.

`PulmonaryToolkit.exe` runs the graphical user interface (GUI)
`PulmonaryToolkitApi.exe` runs a specified PTKScript using the API. The PTKScript must be compiled into the application (see above). When running `PulmonaryToolkitApi.exe` specify the script as the first argument, and then any additional arguments that your script requires.
