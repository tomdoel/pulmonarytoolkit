# How to develop your own Plugins

To develop a Plugin you need to create a class inheriting from `PTKPlugin`, set the appropriate property values and write the implementation in the `RunPlugin()` method. You should look to existing Plugins for examples.


## Plugin naming

It is recommended not to use the prefix `PTK` for your own class names, so that you can clearly distinguish between core Plugins provided by PTK and those you have developed yourself.


## Modifying paths and auto-detecting new Plugins

If you add a Plugin, it needs to be in one of the existing Plugin directories, or else you need to modify the `PTKAddPaths.m` function to include your additional paths.

If you modify `PTKAddPaths.m` during a Matlab session, you may need to run `PTKAddPaths force` to force it to detect the new paths (restarting Matlab will always pick up the new paths).

When running Plugins using the API, PTK will find them if they are on the current path set by `PTKAddPaths`.

The GUI will only display Plugins that were found in the `Plugin` directories during the first run in a Matlab session. To force it to search again, close all Matlab windows then run `clear all classes` to clear the memory caches.


## Implement the `RunPlugin()` method

Assuming you have set the property `PTKVersion = '2'` (see below), then you need to implement the following `RunPlugin()` method:


```
  methods (Static)
      function results_image = RunPlugin(dataset, context, reporting)
          ... do some processing and set results_image
      end
  end
```

The following three parameters are passed to your Plugin when it is run by PTK:

| Parameter | Description |
|---------------|-------------|
| dataset | A `MimDatasetCallback` object which provides access to the dataset similar to how you use it from the API. In particular, you can fetch other Plugin results using `GetResult()` and [parameters](../features/parameters) using `GetParameter()` |
| context | The current [context](../datatypes/Contexts) which PTK is asking you to process. If your Plugin supports processing over different Contexts then you may need to use this value to fetch the appropriate Context results from other Plugins |
| reporting | A [PTKReporting](../developer/ErrorAndProgressReporting) object for progress and error reporting |


## Plugin properties

### Properties determining how the Plugin is run

| Property name | Recommended value | Description |
|---------------|-------------|---|
| AllowResultsToBeCached | `true` | If `true`, enables caching of results. This speeds up processing but uses additional disk storage |
| AlwaysRunPlugin | `true` during development, `false` in production | If `true`, force the Plugin to run even if a result is in the cache. Set to `true` during development, otherwise changes to your Plugin changes may not be executed if a cached result is found |
| PluginType | `'ReplaceOverlay'` or `'DoNothing'` | Tells the GUI what to do with the result of the plugin after it has been run. `ReplaceOverlay` means the Plugin is expected to return a segmentation image which should be displayed as a colour overlay. `ReplaceImage` means the underlying image should be changed (normally only for context changes) |
| HidePluginInDisplay | `false` | If `true`, the GUI will never to show a button for this Plugin. Typically for Plugins which it does not make sense to run directly from the GUI |
| FlattenPreviewImage | `true` | Controls how the preview image displayed on the Plugin button is shown.  If true then it superimposes all slices of the result to generate a preview. |
| PTKVersion | `'2'` | Determines the Plugin interface version which your Plugin implements. This determines the parameters passed into the `RunPlugin()` method. At time of writing this is `2` so you should set this parameter to `'2'` and implement your Plugin to expect the corresponding inputs. The value `'1'` can be specified to allow older Plugins to be run without modification |
| Context | `'PTKContextSet.LungROI' | Advanced property. The [Context or ContextSet](../datatypes/Contexts.md) over which the Plugin will be run. When running the Plugin, PTK will convert the Context to what the Plugin is expecting. For lung analysis, most plugins run on the `LungROI` context set which means they receive the lung image cropped to the ROI. It is also possible to specify `'PTKContextSet.OriginalImage'` to receive the full-size original image, or to receive Lung or Lobe regions. Or, if your Plugin can operate on an arbitrary region (such as specified by a manual segmentation), then set to `'PTKContextSet.Any'` to allow any Context. See `PTKCTDensityAnalysis.m` for an example of how to use the Any context. |

### Properties determining how the Plugin button is shown in the GUI

| Property name | Recommended value | Description |
|---------------|-------------|---|
| ButtonText    | Your plugin name | Text that appears on the Plugin's button in the GUI Plugins tab |
| ToolTip       | Your plugin description | Mouse hover-over text for Plugin's button in the GUI Plugins tab |
| Category      | Group name for your Plugin | Which button group the Plugin button will appear in on the GUI |
| ButtonWidth   | `'6'` | Relative width of the Plugin's button on the GUI |
| ButtonHeight  | `'2'` | Relative height of the Plugin's button on the GUI |
| Visibility    | `'Developer'` | Set to `Developer` for the Plugin button to be visible in Developer mode, `Always` for always visible, or `Dataset` for always visible when any dataset is loaded |
| GeneratePreview | `true` | Determines if the Plugin will generate a preview image for the GUI |
