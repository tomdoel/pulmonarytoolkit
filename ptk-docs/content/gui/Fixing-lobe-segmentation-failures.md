# Fixing lobe segmentation failures

_Added in PTK v0.6.6_

Normally, when the lobe segmentation runs automatically, you have the ability to correct the resulting segmentation using the Correct tab.

If the lobe segmentation is not able to run automatically on a particular dataset, you will now be given the option of creating a manual lobe segmentation.

If you choose to do this, PTK will generate a "best guess" lobe segmentation. You will need to review and correct this, since it could be inaccurate and might be missing lobes. As with normal lobe segmentations, you can then use the Correct tab to edit this using the correction tools, or using an external editor via the "export corrections"/"import corrections" buttons.

Once you are happy you can re-run the analysis and results will be generated using your new manual lobe segmentation.

This option is only available from the GUI, since it needs manual approval. However, once a manual lobe segmentation has been generated from the GUI, it will then be used automatically in future lobe analysis. Therefore, if you are using the PTK API in your own scripts or functions and encounter lobe segmentation errors, use the GUI to fix these and then re-run your code.
