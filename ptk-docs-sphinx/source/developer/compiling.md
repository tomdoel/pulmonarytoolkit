# Compiling PTK into an application executable

```{attention}Requires the Matlab Compiler```

You can compile PTK into application executables. Once compiled, these can be run on any computer with the same operating system without Matlab or a Matlab licence. You may however need to install supporting software such as the free Matlab Compiler Runtime.

Compiling will generate two executables; one for running the normal PTK graphical user interface, and one which runs automated processing scripts without a GUI, suitable for batch processing.

Compiling PTK yourself will include your own Plugins and modifications into the compilation, provided the source files are within the PTK directory structure.

To run the compilation you to have Matlab and the Matlab Compiler installed. Please note that the Matlab Compiler is different to the C++ compiler you may have installed during PTK installation. The Matlab Compiler is a component of Matlab which you may need to install. If you are using an institutional licence, it is likely that use of the Matlab Compiler is included in your licence, but be aware that some Matlab licenses such as the home licence do not include use of the Matlab Compiler. 

You compile PTK by running the `CompilePTK()` script from within Matlab

```matlab
CompilePTK()
```

This will generate the two executables:

* `PulmonaryToolkit.exe` runs the graphical user interface (GUI)
* `PulmonaryToolkitApi.exe` runs a specified PTKScript using the API. The PTKScript must be compiled into the application (see above). When running `PulmonaryToolkitApi.exe` specify the script as the first argument, and then any additional arguments that your script requires.

## Running the compiled applications

Running your own compiled version of PTK has the same requirements as running a [pre-compiled version](../installing/running-without-matlab.md).

Typically, running compiled version requires the following:
 * The free Matlab MCR to be installed, which MUST match the version of Matlab used to compile PTK.
 * (Windows only): the Visual Studio runtime distributable which matches the version of Visual Studio used to compile PTK
 * the compiled PTK files: e.g. `PulmonaryToolkit.exe` and `PulmonaryToolkitApi.exe` or equivalent for macOS/linux
 * (macOS/Linux) - certain environment variables might need to be set in order to locate the correct version of the Matlab MCR - see Mathworks documentation for more details
