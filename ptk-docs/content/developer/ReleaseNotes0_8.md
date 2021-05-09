# Release notes v0.8

Version 0.8 adds a major new feature — support for parameters. In addition there are a number of critical bug fixes which address issues in several previous releases. The main change to the APIs is adding support for parameter values. Other APIs have not changed so the framework changes should be invisible to most users; however if you have made any customisations you may need to be aware of changes.

## Upgrading
In most cases you can just upgrade the source code from a previous version to the new version and restart ptk.

If you experience problems, first try restarting Matlab.

You can use the `PTKUtils` class to fix some issues if you continue to encounter problems.

## New features

### Parameters

Significant changes:

Plugins can now be called with one or more parameter values. This allows you to vary a parameter and run a plugin multiple times for each parameter value, while being able to cache results for each parameter if desired. Dependency management is handled correctly (i.e. dependencies depend on the specific parameter values provided).

### Export to Nitfi

Now supports exporting to Nifti format

### Analysis

Improved the analysis pane. Analysis plugins are now hidden when they are not applicable (when the modality is not supported or datasets have not been linked for multi-modal analysis).
