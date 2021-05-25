PTK Developer SDK

# Edited Results for manual and semi-automated correction

:grey_exclamation: Advanced topic

PTK allows you to save manual corrections to the output of a plugin. When you do this, your corrections will override the normal plugin output for that dataset.

These corrections are called **Edited Results**. An Edited Result is specific to the output of a particular Plugin for a particular Dataset. After you save an Edited Result, PTK will store that result permanently, and use it to either replace or modify the result that is returned through API calls such as `GetResult()`.


## Using Edited Results with the PTK GUI

The GUI provides some tools for modifying Plugin outputs in 3D and saving the corrections as Edited Results. These provide the PTK GUI's "correction" functionality for segmentations; under the surface what these tools actually do is display the current plugin output, allow you to modify the segmentations in 3D, and then save the modifications as Edited Results.

These tools are only enabled for certain Plugins by default. This is deliberate, to encourage manual editing only at the appropriate points in the workflow. However, you can enable editing tools on the GUI for other Plugins, including your own. Just be aware that it's up to you to ensure the tools enabled are appropriate for the Plugins you enable them for.

The editing tools can be enabled for a Plugin by modifying the `EnableModes` and `SubMode` properties in the Plugin class.

For `PTKLeftAndRightLungs`, modification of the outer boundaries of the left and right lung regions is allowed by setting
```
EnableModes = MimModes.EditMode
SubMode = MimSubModes.EditBoundariesEditing
```

For `PTKLobes`, modification of the the inner boundaries between lobar regions is allowed by the following properties. Editing of the outer boundaries is prevented as these will already have been set by editing the lung boundaries.
```
EnableModes = MimModes.EditMode
SubMode = MimSubModes.FixedBoundariesEditing
```

Remapping of airway labelling (see _Special behaviour: Plugins may use Edited Results to modify automated results_ below) is enabled for the `PTKAirwaysLabelledByLobe` plugin.
  ```
  EnableModes = MimModes.EditMode
  SubMode = MimSubModes.ColourRemapEditing
  EditRequiresPluginResult = true
  ```


## Using Edited Results with the SDK

:grey_exclamation: Advanced topic

The `MimDataset` object has methods `SaveEditedResult()` and `DeleteEditedResult()` to save or delete an Edited Result.

As a developer, it's your responsibility to ensure the result you save is stored in the correct way for the Plugin you are saving it for. Once you save your Edited Result, most Plugins will simply return your Edited Result instead of the automated Plugin result, so if it's not in the right format, then Plugins which depend on it will fail.

In these cases, the Edited Result you save should match the type of whatever the Plugin would normally return. For example, the `PTKLeftAndRightLungs` Plugin returns a `PTKImage` object which contains a Uint8 segmentation mask with 1 for right lung, 2 for left lung, and 0 everywhere else. Since you often want to modify the existing result rather than create a new one from scratch, you can use `GetResult()` to return the current result, modify it as necessary, and then save the modified result as an Edited Result.

In some cases you can't call `GetResult()` because the plugin throws an exception (eg if the data are too poor to segment). Some Plugins (such as `PTKLobes`) provide a partial result in this case which you can use as a starting point for creating your Edited Result. This is returned by the method `MimDataset:GetDefaultEditedResult()`, but this will return `[]` if the Plugin does not provide this functionality.


### Special behaviour: Plugins may use Edited Results to modify automated results

As mentioned above, most Plugins simply to replace the computed Plugin result with the stored Edited Result. However, it is also possible for Plugins to adopt a smarter approach, where the output uses the Edited Result to modify the computed output. For example, the `PTKAirwaysLabelledByLobe` plugin returns an airway tree where branches have been labelled by lung lobes. The Edited Result does not store the airway tree structure, it stores a label map image which is used to label the airway tree structure returned by other plugins. This means that changes to the airway tree will be reflected in the output even if an Edited Result is remapping the output.

A Plugin implements this special behaviour by overriding the `MimPlugin::GetEditedResult()` method. What should be stored in the Edited Result is then determined by how this method is implemented. See the plugin `PTKAirwaysLabelledByLobe` for an example implementation which is designed to work the **Remap** tool in the PTK GUI.


## When to use Edited Results

Edited Results are best suited for making manual corrections to the output of a fully automated Plugin.
 * If you want to perform processing on manually-defined regions, you might be better off using PTK **Manual Segmentations**
 * If you want to try running a Plugin with different parameter values, you might be better off using PTK **Parameters**



## Saving Edited Results for Plugins that are used by other Plugins

Edited Results will automatically override all uses of that Plugin for the particular Dataset, including when that Plugin is called by another Plugin. For example, the lung segmentation Plugin `PTKLeftAndRightLungs` is used by the lobe segmentation Plugin `PTKLobes`. If you save an Edited Result for `PTKLeftAndRightLungs`, then `PTKLobes` will use the Edited Result in its lobe computations.


## Caching behaviour

The automated caching should do the right thing. Edited Results are part of the dependency tree for a Plugin result. If you add, modify or delete an Edited Result to a particular Plugin for a particular Dataset, then any Plugin Results which depend on it should have their cached results invalidated and should re-run as required.


## How Edited Results are stored

**Edited Results are stored permanently, not just for the current session**. They will be maintained even if you delete and re-import the dataset. You can delete them using the API.

The idea is that a lot of manual work may have gone into making the manual corrections. You don't want to lose this work, and also you want to maintain future reproducibility of results.

:grey_exclamation: Be careful if using Edited Results while you are developing algorithms — you might not see the effects of your changes because they are being overridden by your Edited Results! To warn you of this, the PTK Viewer usually displays the word "**(Edited)**" in the title of a Plugin output that includes an Edited Result.

Edited Result files are stored in the `~/TDPulmonaryToolkit/EditedResults` folder.
