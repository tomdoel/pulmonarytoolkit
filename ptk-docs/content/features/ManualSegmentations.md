# Manual segmentations

You can create and edit manual (user-created) segmentations. This is useful if you want to perform analysis on one or more manually-drawn regions instead of (or in addition to) the regions that would generated automatically by a Plugin.

For example, PTK's `Analyse` tab includes a `CT Regional` section with tools for computing metrics from regions in the CT image. Normally this includes `Lung analysis` and `Lobe analysis` which use the lung and lobe regions generated by PTK. But if you create your own manual segmentations, then an additional `Manual regions` tool will appear, allowing you to compute similar metrics for all the manual regions you have created.

You can also import regions created by an external tool.


## Creating manual segmentations in the PTK user interface

A list of existing manual segmentations for this dataset is shown on the `Segment` tab.
 * Click to load a manual segmentation and display it as an overlay on the image.
 * Press the `+` button to create a new manual segmentation.
 * Right-click on a segmentation to rename, duplicate or delete.

Use the `Correct` tab to edit the segmentation. This uses the same interactive tools that are used to correct automatic segmentations.
 * The paint tool paints a sphere of a given label colour. You can select any colour 0-255 using the colour buttons or the custom label number edit box. Zero erases the colours. You can change the size of the sphere using the slider. A toggle button allows you to toggle whether the paint tool will paint over any voxels, or only change existing coloured voxels.
 * The boundary tool allows you to shift (in 3D) a boundary between two colours. Click on a point near an existing boundary and the boundary will shift in 3D to match that point.


## Writing plugins that work with manual segmentations

The key to using manual segmentations with plugins is to write your plugin to use

is to set the plugin's `ContextSet` property to `PTKContextSet.Any`use an incoming `Context`





Some PTK Plugins

 You could also use this to



You can write plugins that process

This allows you to write plugins that analyse manually-defined regions instead of (or in addition to) regions generated automatically by plugins.



While a plugin will often create
This allows you to run analysis on These allow to to run analysis over

The PTK GUI provides some basic tools to create and edit manual segmentations; you can also use external tools (such as ITK-Snap) by exporting a manual segmentation to an appropriate file format, modifying using the external tool, and then importing the modified file.


## Using manual segmentations programatically

You can export and import manual segmentations.

The analyse tab has a button which will run lung analysis over all regions you have created in the manual segmentations.