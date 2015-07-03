# Requirements #

You will need to install certain software before you can use the Pulmonary Toolkit. I recommend you install everything so that all the features are available to you. However, you can miss out certain programs if you don't mind not being able to use certain features.

Apart from Matlab and the Matlab Image Processing Toolbox, all the required software is free and available for Windows, Linux and Mac OSX.


## Required software ##

  * Matlab version R2010b or later
  * The Matlab Image Processing Toolbox
  * a Subversion client (in order to download and update the software)

A variety of Subversion clients exist, e.g. Tortoise SVN, SmartSVN, SVNX.
Linux users can install subversion from http://subversion.apache.org/packages.html or using
```
$ sudo apt-get install subversion
```

  * C++ compiler (required to use advance features such as lobe segmentation).

Linux users may already have gcc installed. Max OSX users can download Xcode free from the Apple AppStore. Windows users can install Visual Studio C++ Express free from Microsoft.


# Installing - step by step instructions #

  * Install [Matlab](http://www.mathworks.com/products/matlab/) and the [Matlab Image Processing Toolbox](http://www.mathworks.com/products/image/).

Note: Matlab is a paid-for product, but if you are associated with an educational institution it may have licenses you can use.

  * Install a C++ compiler (e.g. XCode, Visual Studio Express, gcc)
  * Choose your compiler using mex on Matlab
```
mex -setup
```
Note: you will not be able to run the advance Toolkit features until you have set up a C++ compiler.

  * Install a [Subversion](http://subversion.apache.org/) client.

Subversion is a widely-used version control system. It allows you to download the Pulmonary Toolkit and to update it (to receive new features and box fixes) without losing any changes or additions you have made.

Linux users can install subversion from http://subversion.apache.org/packages.html or using
```
$ sudo apt-get install subversion
```

A variety of Subversion clients are available for Windows (e.g. Tortoise SVN, Smart SVN) and for Mac OSX (e.g. Smart SVN, SVNX). Mac users can install Subversion on the command line by installing XCode and then choosing "Command Line Tools"  from Xcode>Preferences>Downloads>Command Line Tools. Mac users with MacPorts installed can also obtain subversion this way.

  * Check out the Pulmonary Toolkit using Subversion

**Using a command-line Subversion client**, execute the following:
```
svn checkout http://pulmonarytoolkit.googlecode.com/svn/trunk/ pulmonarytoolkit
```

**Or, if you are using a Subversion GUI**, find the command to check out a repository. You want to check out the following repository as an anonymous user:
```
http://pulmonarytoolkit.googlecode.com/svn/trunk/
```

  * Run the Toolkit, either using the GUI:
```
ptk
```
or using the API
```
ptk_api = TDPTK;
```
Provided you have set up your compiler, the Toolkit should automatically compile the mex files the first time it starts up. This may take a few minutes. It only needs to do this once, or when the source files change.

## Compilation errors ##

If the mex compilation fails (e.g. you have not set up a C++ compiler) you will need to fix your compiler installation and then force the Toolkit to re-run compilation using
```
ptk_api = TDPTK;
ptk_api.Recompile;
```