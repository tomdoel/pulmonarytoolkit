# Installing

## Requirements

You will need to install certain software before you can use the Pulmonary Toolkit. I recommend you install everything so that all the features are available to you. However, you can miss out certain programs if you don't mind not being able to use certain features.

Apart from Matlab and the Matlab Image Processing Toolbox, all the required software is free and available for Windows, Linux and Mac OSX.


### Required software ##

  * Matlab version R2010b or later
  * The Matlab Image Processing Toolbox
  * C++ compiler (required to use advance features such as lobe segmentation).

Linux users may already have gcc installed. Max OSX users can download Xcode free from the Apple AppStore. Windows users can install Visual Studio C++ Express free from Microsoft.

### Recommended software ##
  * [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)(in order to download and update the software)
  * A gui client for Git to make it easier to update the software, e.g. [SourceTree](https://www.sourcetreeapp.com)

Note: while it is possible do download PTK as a zip file from GitHub, you will not be able to update it automatically to new versions and you won't be able to commit your changes or contribute to the project. I therefore recommend using Git.


## Installing - step by step instructions #

  * Install [Matlab](http://www.mathworks.com/products/matlab/) and the [Matlab Image Processing Toolbox](http://www.mathworks.com/products/image/).

Note: Matlab is a paid-for product, but if you are associated with an educational institution it may have licenses you can use.

  * Install a C++ compiler (e.g. XCode, Visual Studio Express, gcc)
  * Choose your compiler using mex on Matlab
```
mex -setup
```
Note: you will not be able to run the advance Toolkit features until you have set up a C++ compiler.

  * Install a Git client.

Git is the industry-standard version control system. It allows you to download the Pulmonary Toolkit and to update it ('pull') to receive new features and box fixes without losing any changes or additions you have made.

In addition, you can maintain your own clone of the software, allowing you to safely preserve your changes while continuing to receive updates from the main project.

Mac and Linux users will probably already have git installed - to check, open a terminal window and type

```
git --help
```

On OSX (Mac users) you may be prompted to install command-line tools - this will install git for you.

Even if you have git installed, you may wish to update to the latest version - [see here for details](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)(in order to download and update the software)

  * Install a gui client for Git

You can use Git on the command-line, but you may find it easier to use a graphical interface such as SourceTree - [available free here](https://www.sourcetreeapp.com)

You can also use the GitHub app.


  * Check out the Pulmonary Toolkit using Git

**Using a command-line git client**, execute the following:
```
git clone https://github.com/tomdoel/pulmonarytoolkit.git
```

**Or, if you are using SourceTree, click 'New/Clone' and 'Clone from URL'**

  * Run the Toolkit, either using the GUI:
```
ptk
```
or using the API
```
ptk_main = PTKMain;
```
Provided you have set up your compiler, the Toolkit should automatically compile the mex files the first time it starts up. This may take a few minutes. It only needs to do this once, or when the source files change.

### Compilation errors

If the mex compilation fails (e.g. you have not set up a C++ compiler) you will need to fix your compiler installation and then force the Toolkit to re-run compilation using
```
ptk_main = PTKMain;
ptk_main;
```
