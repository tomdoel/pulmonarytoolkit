# Markers

You can place markers on your image. Each marker is attached to a particular point in the image in 3D.

You might use a marker to indicate particular features in the image, for example reference points to be used in image registration. You could also use marker points to signify ground truth points, which can be used to evaluate an automatic segmentation.

Each marker has a **label**, which has an integer value between 1 and 255. These are presented with different colours on the screen. You might use a particular label to designate a particular feature. For simplicity, the GUI only allows you to set marker labels 1-7, but values up to 255 can be set programatically.

## Showing markers in the PTK GUI

Select the `Markers` tab to display markers and marker tools
 * The most recently used **marker set** for this dataset (if any exists) will be loaded and displayed.
 * If there is no existing marker set, click `+` to create a new one. Or you can just place a new marker, which will automatically create a new marker set called `MarkerPoints` (you can rename this later).

## Marker Sets
A **Marker Set** is a set of marker points. Only one set of markers is displayed at a time. The markers in the marker set may have different labels. For example, you could create a marker set to validate a fissure segmentation, by placing markers on each fissure. You can use different marker labels (colours) for each fissure, so all the markers are contained within the same marker set.

Any existing marker sets for this dataset are listed under `Marker Sets`:
  * Click on a marker set to load it
  * Click `+` to create a new marker set
  * Right-click on an existing marker set to show a menu to duplicate, rename or delete it


## Adding markers
 * Press the `+` button to create a new marker set.
 * Click on the image to place a marker point of the current colour. (NB. If you do not create a marker set, one will be created automatically with the name `MarkerSet` when you place your first marker point).
 * Press the marker colour button to change the label
 * To simplify use, markers of the same label (colour) cannot be placed too close to each other. If you click close to another marker, this will move that marker to this location. This makes it easier to refine marker locations.
 * Markers have a 3D location. Markers will only be shown for the current 2D image slice. As you cine through the volume, the markers for the current image slice will be shown.
 * Use the show/hide markers button to toggle display or markers on and off
 * Drag the marker to move it
 * Right click on a marker to bring up a menu to change the label or delete the marker
 * Use the label button to switch on or off display of coordinates for the markers in the image

## Marker navigation
 * The arrow buttons in the markers tab allow you to quickly change the currently viewed slice to find other slices which contain markers. So if you place markers only on certain slices of the image stack, you can quickly navigate between these slices.
 * The navigation depends on the orientation you are currently in.
 * The previous and next marker buttons (or left and right arrow keys) will move forward or backwards through the image stack by a fixed number of slices, but will stop if a slice contains markers. If you want to place markers at regular intervals through your volume, this makes it easy to skip a regular number of slices before you place each marker points.
 * The nearest marker button (or `space` key) will make you to the nearest slice containing marker points.
 * The first and last marker (or `[` and `]` keys) will take you to the first or last slice in the volume containing marker points

## Keyboard shortcuts
 * Number keys `1`, `2` etc. change the current marker label/colour
 * `L` toggles labels on or off
 * The delete key, when the mouse is hovering over a marker point, will delete that marker point

## Changing between marker sets
 * Click on a marker set to load that marker set. Only one set can be loaded at a time.
 * Changes are normally saved automatically
 * Right-click on a marker set to bring up a menu to delete, rename or duplicate a marker set

## Export marker points to an XML file
 * Use the `Export Markers` button to save the current marker set to an XML file. The coordinates will be Dicom coordinates for this image

## Accessing marker data using the API
 * You can call the `LoadMarkerSet` method on a `PTKDataset` object to get a structure containing the points data for the specified marker set
 * Markers are stored with dependency information, which means that plugins can depend on marker sets. If a plugin access marker set data, and the marker set is changed, the plugin will be re-run when necessary.

## Markers in the PTKViewer mini-viewer
 * The PTKViewer mini-viewer supports marker editing. To use this you need to programatically load the marker points into the `MarkerImageSource` within the MimViewerPanel. Marker mode is activated by the user clicking the `Mark` button on the PTKViewer

## Technical details

 * Each marker set is saved as a custom class in the `TDPulmonaryToolkit/Markers` directory, under a subdirectory for the dataset UID.
 * Saved marker set files are not guaranteed to be compatible between PTK versions. 
