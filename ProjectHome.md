The Pulmonary Toolkit is a software suite for the analysis of 3D medical lung images for academic research use.

This is experimental research software and is primarily intended to support our own work. However, we are happy for you to make use of the software, and we have therefore made the source code available for free under the open-source licence (GNU-GPL3).

While we are happy for you to make use of this software, please be aware that it is not designed or intended for general use and we can provide only limited support.

_Currently available as an experimental (alpha) version - see Releases below._

It comprises:
  * a library of lung analysis algorithms which can be called from your own code;
  * a GUI application for visualising and analysing clinical lung images (CT & MRI);
  * a rapid prototyping framework for developing new algorithms. This fully integrates with the GUI application, or can be used within your own code or through scripting.

This software requires Matlab (version R2010b or later) and the Matlab Image Processing Toolbox.
Some features also require a C++ compiler.

**Note: The Toolkit will not run with earlier versions of Matlab**


This software is intended for research purposes only. It is not intended for clinical use.


### Online manuals ###

PDF tutorials can be found in the Downloads folder after checking out the project, or you can download them directly here:

[Installing the Pulmonary Toolkit](https://pulmonarytoolkit.googlecode.com/svn/trunk/Documentation/PTK%20-%20Installing.pdf)

[Tutorial 1 - Loading and visualising data](https://pulmonarytoolkit.googlecode.com/svn/trunk/Documentation/PTK%20-%20Tutorial%201.pdf)

[Tutorial 2 - Exporting data](https://pulmonarytoolkit.googlecode.com/svn/trunk/Documentation/PTK%20-%20Tutorial%202.pdf)

[Tutorial 3 - Programming with the Pulmonary Toolkit](https://pulmonarytoolkit.googlecode.com/svn/trunk/Documentation/PTK%20-%20Tutorial%203.pdf)

[Tutorial 4 - Lobar analysis of CT data](https://pulmonarytoolkit.googlecode.com/svn/trunk/Documentation/PTK%20-%20Tutorial%204.pdf)


More tutorial guides will be added in the near future.



### What can I do with the Pulmonary Toolkit? ###

There are many ways of using the Toolkit, for example:

  * Use the GUI to load lung images from Dicom or mhd/raw files, perform automated analysis such as lobe segmentation or emphysema detection, and then save the results out;
  * Write your own plugins to perform image analysis tasks, such as regional detection of lung disease;
  * Write a Matlab script to perform automated analysis on hundreds of datasets using the Toolkit's API, for example gathering airway measurements;
  * Using the PTKViewer tool to quickly view 3D datasets from the Matlab command window;
  * Build your own medical application, by adding the Toolkit's image viewing panel (PTKViewerPanel) to your application;
  * Use the Toolkit's suite of library functions to help in loading/saving, image processing (e.g. 3D watershed transforms) and image analysis



### Requirements ###

To run the current alpha version you will need the following:
  * Matlab version R2010b or later
  * The Matlab Image Processing Toolbox
  * A C++ compiler
  * a Subversion client


### Releases ###

You can download and run the software but please be aware **the Toolkit is currently in alpha**. There is currently no stable release. We recommend you check out the latest version using Subversion and update regularly to obtain new features and bug fixes.

You can obtain the latest version of the code using Subversion - see the **Source** tab for more information. Subversion is a widely used version control system and free Subversion clients are available for all operating systems.

Please update your subversion checkout regularly to receive new features and fixes.


### Support ###

Support is provided via the wiki. Tutorials, documentation and help will be added to this wiki in the future.

If you are experiencing problems, please make sure you have the required version of Matlab and the Imaging Processing Toolbox. Please also ensure you have a suitable C++ compiler installed and set up. The Toolkit will not work correctly without these.

Please update your Subversion checkout to obtain the latest bug fixes.

The toolkit works primarily with medical Dicom images, but there is also limited support for mhd/mha files

Please note the email address associated with this project is not monitored.


### License ###

You may download and use the Toolkit subject to the conditions of the GNU GPL v3 license. Note that under this license you can use the Toolkit in your own software, but if you do, and if you distribute your software to anyone else, then you must also make your software source code freely available. See the GNU GPL v3 license for details.

_Note: Some parts of the software in the External folder are covered by different licences - see the licence files in the External folder for details_.