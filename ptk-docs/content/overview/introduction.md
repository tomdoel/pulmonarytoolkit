# Introduction

## The Pulmonary Toolkit (PTK)

version: ALPHA 1.1
Please note this version is not stable.

 * [Getting Started](getting-started)
 * [Sample Data](../resources/SampleData)
 * [Citing in publications, posters etc.](../resources/Citations)
 * [Release notes for version v0.8](../developer/ReleaseNotes0.8)
 * [Release notes for version v0.7](../developer/ReleaseNotes0.7)


## Overview

The Pulmonary Toolkit is a software suite for the analysis of 3D medical lung images for academic research use.

This is experimental research software and is primarily intended to support our own work. However, we are happy for you to make use of the software, and we have therefore made the source code available for free under the open-source licence (GNU-GPL3).

It comprises:
  * a library of lung analysis algorithms which can be called from your own code;
  * a GUI application for visualising and analysing clinical lung images (CT & MRI);
  * a rapid prototyping framework for developing new algorithms. This fully integrates with the GUI application, or can be used within your own code or through scripting.

This software requires Matlab (version R2010b or later) and the Matlab Image Processing Toolbox.
Some features also require a C++ compiler.

**Note: The Toolkit will not run with earlier versions of Matlab**

This software is intended for research purposes only. It is not intended for clinical use.


## Online manuals

PDF tutorials can be found in the Downloads folder after checking out the project, or you can download them directly here:

Please note some of the information in the tutorials may be out of date.

[Installing the Pulmonary Toolkit](https://github.com/tomdoel/pulmonarytoolkit/raw/master/Documentation/PTK%20-%20Installing.pdf)

[Tutorial 1 - Loading and visualising data](https://github.com/tomdoel/pulmonarytoolkit/raw/master/Documentation/PTK%20-%20Tutorial%201.pdf)

[Tutorial 2 - Exporting data](https://github.com/tomdoel/pulmonarytoolkit/raw/master/Documentation/PTK%20-%20Tutorial%202.pdf)

[Tutorial 3 - Programming with the Pulmonary Toolkit](https://github.com/tomdoel/pulmonarytoolkit/raw/master/Documentation/PTK%20-%20Tutorial%203.pdf)

[Tutorial 4 - Lobar analysis of CT data](https://github.com/tomdoel/pulmonarytoolkit/raw/master/Documentation/PTK%20-%20Tutorial%204.pdf)



### What can I do with the Pulmonary Toolkit?

There are many ways of using the Toolkit, for example:

  * Use the GUI to load lung images from Dicom or mhd/raw files, perform automated analysis such as lobe segmentation or emphysema detection, and then save the results out;
  * Write your own plugins to perform image analysis tasks, such as regional detection of lung disease;
  * Write a Matlab script to perform automated analysis on hundreds of datasets using the Toolkit's API, for example gathering airway measurements;
  * Using the PTKViewer tool to quickly view 3D datasets from the Matlab command window;
  * Build your own medical application, by adding the Toolkit's image viewing panel (PTKViewerPanel) to your application;
  * Use the Toolkit's suite of library functions to help in loading/saving, image processing (e.g. 3D watershed transforms) and image analysis



### Requirements

To run the current alpha version you will need the following:
  * Matlab version R2010b or later
  * The Matlab Image Processing Toolbox
  * A C++ compiler compatible with Matlab
  * (recommended) a Git client


### Releases

You can download and run the software but please be aware **the Toolkit is currently in alpha**. There is currently no stable release. We recommend you check out the latest version using Git and update regularly to obtain new features and bug fixes.

See the GitHub website for more information on how to obtain the source code. While you can download a zip file, I recommend you use Git as it is easier to obtain updates. Git clients are available for all operating systems

Please pull changes regularly from the GitHub repository to receive new features and fixes.

PTK has an experimental auto-update mechanism where you will be prompted to update when an update appears on the MASTER branch exists. This depends on git being correctly configured.


### Support

If you have questions or problems, please check the following:
 * You have the Matlab Image Processing Toolbox installed and licensed;
 * You have the latest master version of PTK (update using `git pull`);
 * You have a C++ compiler that is fully compatible with your version of Matlab;
 * Your C++ compiler can be found and invoked by Matlab (see `mex` for details).

Documentation and help:
 * see the wiki pages on GitHub;
 * download the tutorials;
 * code documentation using `doc <functionname>` - many of the PTK classes and functions are documented;
 * Issues page on GitHub.

If you still have problems, please create a new issue on GitHub.

The toolkit works primarily with medical Dicom images, but there is also limited support for mhd/mha files. At the time of writing, the dev branch includes improved mha/mhd support and some untested support for other file formats such as NIFTI.


### License

You may download and use the Toolkit subject to the conditions of the GNU GPL v3 license. Note that under this license you can use the Toolkit in your own software, but if you do, and if you distribute your software to anyone else, then you must also make your software source code freely available. See the GNU GPL v3 license for details.

_Note: Some parts of the software in the External folder are covered by different licences - see the licence files in the External folder for details_.
