# Recovering disk space

PTK caches some data and results, and over time this may consume your disk space, especially if you are running PTK over many datasets.

You can free up most of this space deleting the `ResultsCache` as follows. This will free up most of the used disk space, but it will leave intact your markers, manual segmentations and manual corrections.

WARNING:
 * after cleaning the cache, PTK may need to reimport data from the original locations. If you try to load data which you have moved since importing it into PTK, you will likely experience issues. You can usually fix this by re-importing the data.
 * After deleting the `ResultsCache` this, processing for each dataset will initially take longer because plugins need to be re-run.

## To free up disk space:
* Close Matlab
* Locate your `~/TDPulmonaryToolkit/ResultsCache` folder.
  * NOTE: on Windows you may need to use `%userprofile%\TDPulmonaryToolkit\ResultsCache`, depending on which Windows tools you are using.
* Delete the `~/TDPulmonaryToolkit/ResultsCache` folder but keep other folders intact
* After you have checked that PTK is working OK, you may need to empty your recycle bin to completely free up the deleted space.
