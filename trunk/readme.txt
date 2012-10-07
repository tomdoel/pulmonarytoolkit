Pulmonary Toolkit
Lung medical image analysis and visualisation software for Matlab.

This code is open source and available free to download from the project website:
    http://code.google.com/p/pulmonarytoolkit

Author: Tom Doel, 2012  www.tomdoel.com
Distributed under the GNU GPL v3 licence. Please see website for details.


Summary
-------

The Pulmonary Toolkit is a software suite developed by Tom Doel. It is designed 
for the analysis of 3D medical lung images for research use.

It comprises:
  * a GUI application for visualising and analysing clinical lung images (CT & MRI);
  * a library of lung analysis algorithms which can be called from your own code;
  * a rapid prototyping framework for developing new algorithms, which fully integrates with the GUI application.

This software requires Matlab and the Matlab Image Processing Toolbox.
Some functionality also requires a C++ compiler to be installed. Please see the website for details.
    http://code.google.com/p/pulmonarytoolkit

This software is intended for research purposes only. It is not intended for clinical use.



Licence
-------

The code in the project (except for code in the External folder) is distributed under the GNU GPL v3 licence. 
See licence.txt or the website for details.

Code in the External folder:
 The External folder contains code imported from other open-source projects, which may be covered by different licences.
 Please see the licence files, which are contained in the corresponding folder for each project.
 
 Note: the licenses for these projects permit the code to be distributed with this project.



Getting started
---------------

To run the gui, run

    ptk

at the Matlab command line.

For more details please read the wiki at
    http://code.google.com/p/pulmonarytoolkit


Scripting
---------

To use the toolkit in your own programs, create an instance of TDPTK and use 
this to create TDDataset objects for each dataset you want to work with.

For more information see the code wiki http://code.google.com/p/pulmonarytoolkit



Adding new functionality
-----------------------

You add new functionality to the toolkit by creating new plugin files in the 
User directory. You do not need to modify any existing files - new plugins are 
detected automatically and buttons are added to the user interface.

To add a new algorithm (a routine which produces a result) you create a new 
plugin class inherited from TDPlugin.
To add a new way of visualising, exporting or importing data you create a new 
gui plugin class inherited from TDGuiPlugin.

Your plugins should be in the User/Plugins/ and User/GuiPlugins/ folders unless 
they are being comitted to the TDPTK codebase, in which case they should be in 
the Plugins/ and GuiPlugins/ folders.

For more information see the code wiki http://code.google.com/p/pulmonarytoolkit




Folders
-------

Library - suite of image processing, file access and utility functions. You can 
    use these in your own programs. These functions can be used independently 
    of the rest of the Toolkit as they do not depend on any files outside of the 
    Library folder.
Library\mex - image processing algorithms which use mex and so must be compiled 
    first. The Toolkit normally compiles these automatically as required.

Plugins - contains a Plugin class for each high-level algorithm in the Toolkit.
    Plugins are the algorithmic building blocks of the Toolkit. They appear as 
    buttons in the GUI and are invoked by clicking the button.
    If you are using the API, plugins are invoked using the GetResult() method.
    A plugin represents a high-level concept such as airway segmentation, or an 
    intermediate stage such as trachea detection. When the Plugin runs it 
    generates any required inputs (normally by executing other Plugins), then 
    executes the appropriate functions (usually part of the Library) to generate
    the Plugin result. So for example, the airway segmentatinon Plugin will 
    first fetch the result of the trachea detection Plugin, and then use this 
    result in a call to the Library routines to segment the airways.
    Plugin classes are therefore an interface layer between the Framework, 
    the Library and the GUI.
    Plugin classes also contain properties which describe how the plugin button
    is displayed in the GUI and how the plugin relates to the Framework.
    You can create your own plugins in the User/Plugins folder.

Framework - core classes forming the toolkit. You use some of these classes to 
    use the API.

Gui - classes forming the optional graphical user interface
Gui\GuiPlugins - contains pugins which are specific to the GUI, which provide buttons on the user 
    interface for non-algorithm operations such as importing, exporting and visualising data

bin - compiled mex files are stored here.

External - library functions imported from different open-source projects.
           Note: these may have different licensing requirements

User - where you store your own routines which are not committed to the codebase

User/GuiPlugins - your own gui-related plugins

User/Library - your own image-processing algorithms

User/mex - your own mex algorithms

User/Plugins - your own algorithm-related plugins
