# Deleting data in PTK

Deleting data through the GUI or API is generally safe; it will remove data and cache files which can be regenerated, but it will preserve on disk data that required manual effort to produce, i.e. marker points, manual segmentations and manual corrections. Therefore if you re-import the data in the future, you would be able to continue using the marker points, manual segmentations and manual corrections you had previously created.


## To delete a series

* Use the backpsace key shortcut to delete the current series.
* Or click the `-` button above the series list to delete the current series.
* Or delete any series by right-clicking the name of the series you want to delete and choosing Delete Series.
* Or you can use the API as described below.

## To delete a subject

* Or click the `-` button above the series list to delete the current subject.
* Or delete any series by right-clicking the name of the subject you want to delete and choosing Delete Subject.
* Or you can use the API as described below.

## To delete multiple series

You can use the API to delete multiple series by deleting each series for each patient. The `DeleteDatasets()` call on a `PTKMain()` object takes in a cell array which are the series uids to delete. For example the following script will delete every patient and every series:
```
ptk_main = PTKMain();
series_uids_to_delete = ['uid1', 'uid2;, 'uid3'];
ptk_main.DeleteDatasets(series_uids_to_delete);
```

For example, to delete **all** series for **all** subjects
```
ptk_main = PTKMain();
% Delete all series for all subjects
all_uids = ptk_main.FrameworkAppDef.GetFrameworkDirectories().GetUidsOfAllDatasetsInCache();
ptk_main.DeleteDatasets(all_uids);
```


## Danger zone!

The following section is for more advanced users

### To completely erase all data for a dataset

As noted above, marker points, manual segmentations and manual corrections are preserved when you delete a dataset. The reason is that these generally require some manual effort to produce, so you don't want to lose this through accidental deletion.

If you want to **completely erase** a dataset and **erase all of its manually created marker points, manual segmentations and manual corrections**:
 * Determine the dataset's UID (For DICOM this is normally the Series Instance UID; for other formats it is derived from the filename)
 * Delete the dataset as described above
 * Close Matlab
 * Locate the `~/TDPulmonaryToolkit` folder
   * NOTE: on Windows you may need `%userprofile%\TDPulmonaryToolkit`
 * Delete the corresponding UID folders under `EditedResults`, `ManualSegmentations` and `Markers`
