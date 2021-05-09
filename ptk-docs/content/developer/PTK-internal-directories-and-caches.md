# PTK internal directories and caches

PTK creates a number of directories and files to store imaging data and state. This may use a lot of disk space if you are working with large datasets. PTK is designed to allow you to delete the caches, knowing that the results can be regenerated. Of course, regenerating results will take some time (since the whole point of caches is to save time by storing intermediate results).

## How to clear the cache for a dataset ##
The safest way to clear the caches is to enable developer tools (click the "Developer Tools on" button). This will show the "Delete cache" button, which you can use to clear the cache for the currently loaded dataset.

Warning: If you delete a cache for a dataset, then the next time you generate any segmentations or results from that dataset, PTK will need to re-run all the algorithms necessary to generate the results. This could take some time. Furthermore, the data will be re-loaded from its original location, so you must ensure you have not moved the data.

## PTK internal files ##

PTK creates a folder called `TDPulmonaryToolkit` in your home directory. The location of this can be modified by changing `PTKConfig.m`. Within this folder are a number of files for storing internal state:
 * `PTKFrameworkCache.mat` - stores information about the mex files that have been compiled
 * `PTKImageDatabase.mat` - stores information about the datasets which have been imported into PTK
 * `PTKLinkingCache.xml` - stores information about any datasets which have been linked for registration purposes
 * `PTKSettings.mat` - settings related to the user interface

In general, you should NOT modify or delete this files. If you do need to delete one of these files (e.g. in response to an error) you must first close all PTK windows (`close all`) and then clear all classes and persistent variables (`clear all classes`). If you do not do this, the memory cache will get out of sync with the disk cache and this could cause problems that are hard to diagnose.

## PTK cache directories ##

Also in the `TDPulmonaryToolkit` folder are a number of folders:
 * `ResultsCache` contains the results of computations performed by Plugins
 * `Output` contains tables and graphs showing generated results
 * `EditedResults` contains manual corrections to results - do NOT delete items in this folder
 * `Markers` stores manually placed marker points
 * `ManualSegmentations` stores manually created segmentations

In general, it is safe to delete the files in `Output`.

Files under `ResultsCache` can be deleted, but you MUST first close all PTK windows (`close all`) and then clear all classes and persistent variables (`clear all classes`). If you do not do this, the memory cache will get out of sync with the disk cache and this could cause problems that are hard to diagnose.

You can delete files under `Markers` and `ManualSegmentations`, but you will lose all the work you put into creating these manual segmentations in the first place.

Do not delete files under `EditedResults` - if you need to delete a manual correction, do it via the PTK correction user interface.
