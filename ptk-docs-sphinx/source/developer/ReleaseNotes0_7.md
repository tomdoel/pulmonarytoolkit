# Release notes v0.7

Version 0.7 adds a number of significant features and bug fixes. Additionally, there is significant refactoring of the framework. The APIs have not changed so the framework changes should be invisible to most users; however if you have made any customisations you may need to be aware of changes.

## Upgrading
In most cases you can just upgrade the source code from a previous version to the new version and restart ptk.

If you experience problems, first try restarting Matlab, as a number of classes have changed disk location and this can make Matlab unhappy.

You can use the new `PTKUtils` class to fix some issues if you continue to encounter problems; see below.

## New features

### Support for new file formats

PTK can now import files from Dicom, MetaIO (mhd/mha/raw), Nifti, Analyze and a number of other formats. Some of this support is experimental and in some cases the orientations may be incorrect.

### 3D viewer

The 3D viewer is now integrated into the GUI rather than bringing up a separate window.

### Manual segmentations
See [Manual Segmentations page](../features/ManualSegmentations)


### Marker point sets

Previous versions of PTK included marker point creation and editing, but were limited to a single set of points per dataset and most functionality was only provided by keyboard shortcuts. Now PTK allows you to create any number of marker sets, and a new tab provides easier access to the marker tools. Click a marker set to load and edit it. You can add new marker sets using the + button in the list. You can rename, duplicate or delete marker sets by right clicking on the set.

### Easier managing of dataset UIDs from the API

Now when you call `CreateDatasetFromUid(uid)`, you only need to specify the first few characters of the `uid` and PTK will match the correct one.



## Internal, framework and API changes

### UIDS
UIDs for non-Dicom file types are now created by combining the filename with a hash of the full file and path name. When combined with the new auto matching feature of `CreateDatasetFromUid(uid)` above, the API use will not change. But this allows you to import multiple non-Dicom files with the same filename.

### Framework and library
Much of the framework has been rewritten as part of a new generalised imaging and modelling framework 'MIM'. As a result many classes have moved and changed name. If you were using a library file or class 'PTKxxxx' that is now missing, check the External/mim folder for a corresponding file called 'MIMxxxx'.

### Cache locations
Some of the framework cache locations have moved so they are separated from user-generated content. This makes it easier to clear auto-generated content while preserving any user-generated content.
