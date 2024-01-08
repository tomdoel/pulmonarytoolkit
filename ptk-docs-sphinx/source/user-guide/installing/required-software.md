# Required software

The recomended way to run the Pulmonary Toolkit is through Matlab.

You need to have the following software installed:

Required:
  * Matlab version R2010b or later
  * The Matlab Image Processing Toolbox
  * C++ compiler (required to use advance features such as lobe segmentation).

Recommended:
* A git client

```{tip}
You can run an older version of PTK without these requirements by installing a pre-built executable. Be aware this will not have the latest features and bug fixes. See [Installing without Matlab](../user-guide/installing-without-matlab) for more information.
```

---

## 1. Installing Matlab and the Matlab Image Processing Toolbox

The Pulmonary Toolkit requires [Matlab](http://www.mathworks.com/products/matlab/) version R2010b (also known as release 7.11) or later. The add-on [Matlab Image Processing Toolbox](http://www.mathworks.com/products/image/ is also required.


### If you don’t currently have Matlab installed

Matlab is a commercial product but if you are a student or work for an academic institution, your IT department may have Matlab licences which you can use on your own machine. You will first need to install Matlab and the Image Processing Toolbox from the Mathworks website (http://www.mathworks.co.uk) - this may require you to create a free Mathworks account. You then need to link your account to the licence keys or licence servers provided by your institution.

Octave is not currently supported. Please see [Octave Compatibility](../developer/octave-compatibility.md) for more details.


### If you already have Matlab installed

You can check the Matlab version by typing
```
>> ver
```

in the Matlab command window. You should see something like

```
------------------------------------------------------------------
MATLAB Version: 8.2.0.701 (R2013b)
Operating System: Mac OS X  Version: 10.8.5 Build: 12F45
Java Version: Java 1.7.0_11-b21 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode
------------------------------------------------------------------
MATLAB                                Version 8.2        (R2013b)
Image Processing Toolbox              Version 8.3        (R2013b)
```
If your Matlab version is less than 7.11, you will need to update. Click on the Help menu, and Check for Updates.
If your licence is due to expire, you can check for licence updates. In the current version, this is found on the Home tab. Click the arrow underneath Help, select Licensing and click Update Current Licenses.





---

## 2. Installing a C++ compiler

Some parts of the Pulmonary Toolkit require a C++ compiler. Your system may already have a C++ compiler installed, or you may have installed the MinGW compiler as part of your Matlab installation.

You can verify by running the following command in Matlab

>> mex -setup

Matlab will attempt to find your compiler. If it successfully finds one or more compilers, they will be listed in the command window. Press the number of the compiler you wish to use.

If you do not have a compiler installed, you need to install one yourself. Please see the Mathworks site https://uk.mathworks.com/support/compilers.html for details of which C++ compilers are supported for your version of Matlab. You will also 

:warning: If you do not install a C++ compiler, some parts of the Pulmonary Toolkit will be very slow, and other parts will not function at all.


### Windows

Mathworks provide a link to the free MinGW compiler: https://uk.mathworks.com/support/compilers.html

Alternatively, Microsoft provides a free Community edition of Visual Studio which can be downloaded from https://www.visualstudio.com. **Please note this is different to Visual Studio Code***. Please check supported compiler versions at https://uk.mathworks.com/support/compilers.html.


### macOS

Apple provides a C++ compiler as part of its free Command Line Tools. You can install these from a terminal using the following command:
```
$ xcode-select --install
```

For older versions of macOS you can install Xcode for free and then install the Command Line Tools from within Xcode. You can also download command line tools from the Apple developer site here: http://developer.apple.com/downloads. You may have to create a free developer account.
Warning: when Apple releases a new version of macOS and Xcode, sometimes to get these new compilers to work you need to modify files such as  (MATLAB)/bin/maci64/mexopts/clang++_maci64.xml and (MATLAB)/bin/maci64mexopts/clang_maci64.xml and add entries for the new version of the SDK. Mathworks usually update these files in their next Matlab release. Please check the Matlab support sites and Stack Overflow for more information.



### Linux
You probably already have the gcc compiler installed - you can check where it is installed by typing the following in a terminal window:
```
$ which gcc
```

### Verifying your C++ compiler (optional)

Once you have a C++ compiler installed, you can check that Matlab can find the compiler. To do this, launch Matlab and type the following:
```
>> mex -setup
```


Compilation problems
The first time you run the Pulmonary Toolkit (see Tutorial 1), it will attempt to run the above command to ensure the C++ compiler is correctly set up. Then it will attempt to automatically compile the C++ files it requires. If there are problems, errors will be reported to the command window. Compilation be be attempted a second time when you next run the Toolkit, but if this fails again, then further compilation will not be attempted. Once you fix the compiler you can force the Pulmonary Toolkit to recompile the files using the following commands:
```
>> ptk_main = PTKMain();
>> ptk_main.Recompile();
```


---

## 3. Installing a Git client

The main PTK codebase lives on GitHub: https://github.com/tomdoel/pulmonarytoolkit. While it is _possible_ to download the source files directly as a zip file from GitHub, I would _strongly_ advise using git to clone the repository from GitHub. This makes it easy to "pull" the latest changes from GitHub as new versions are released. It is also much easier to keep track of your own changes using version control.

### Visual git clients

You may prefer to install a visual git client such as [GitHub Desktop](https://desktop.github.com), [SourceTree](https://www.sourcetreeapp.com) or [GitKraken](https://www.gitkraken.com). Some of these may require registration but have free plans. Windows also has [TortoiseGit](https://tortoisegit.org) which integrates directly into Windows Explorer.

### Command-line git clients

Many operating systems already have command-line git installed, so if you are comfortable using the terminal you can use this. To check if you have a command-line git installed, type the following in a Terminal or Command Prompt:
```
git --help
```

macOS users might be prompted to install command-line tools when running this command - if so, this will install git for you.

If you don't have a command-line git installed, or if you want to update your command-line git to a newer version, [see the official docs](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git). You can also use package managers such as Homebrew (macOS) which allow you to install new versions without affecting with your system installation.

