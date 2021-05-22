# Contexts

Contexts are an important concept in the Pulmonary Toolkit. They describe the _particular image region_ upon which a Plugin is being run.

For example, the `Left Lung` and `Right Lung` are both Contexts.

When you run a Plugin, you can specify one or more Contexts over which the Plugin will run. PTK runs the Plugin individually for each Context. You can also specify a **Context Set**, which is a set of one or more related Contexts. For example, the `Single Lung` Context Set comprises of the `Left Lung` and `Right Lung` Contexts.

A powerful feature of PTK is that Contexts are arranged in a hierarchy. PTK can automatically split up and recombine the image inputs and outputs to move between different Contexts in the hierarchy. For example, let's say you have an analysis Plugin that is designed to run on a single lung Context. If you run it across the entire lung image, PTK will automatically split up the image into the Left and Right lung regions (Contexts), run the Plugin once for each Context, and then combine the output results into a single output image for the whole lung.





## Context Sets

Every Plugin operates on a Context, or a set of Contexts. For example, the airway segmentation algorithm needs to know where in the image to search for the airways, so it uses the Lung Region of Interest Context. It doesn't make sense for the airway segmentation to use any other Context. So this is an example of a Plugin that operates on a single specific Context.

Some Plugins can operate on more than one Context. For example, the lobe segmentation algorithm divides up a lung region into lobes. It operates on the left lung Context or the right lung Context. A `Context Set` is a set of Contexts over which a Plugin can operate. The Single Lung Context Set contains two Contexts, Left Lung and Right Lung. The Lobe Context Set contains five, one for each lobe. Whereas the Lung ROI Context Set only contains one Context, the Lung ROI Context.


## GetResult with a Context

When you get any result from the Pulmonary Toolkit (using the `GetResult()` method), you can specify a Context, e.g.

```
dataset.GetResult('MyPlugin', context);
```

where context is one (or a cell array) of the `PTKContext` enumerations. The Pulmonary Toolkit will fetch your result for that particular Context. If you don't specify a Context, then normally `LungROI` is assumed. The exception to this is where a Plugin itself specifies a single particular Context, such as `OriginalImage`.

What happens when you specify a Context depends on how the Plugin operates (see below). The Pulmonary Toolkit will if necessary combine or reduce the results in order to fit the Context you have specified. For example, if a Plugin is set to operate on a single lung (the right or left lung), but you requires a LungROI context, then the Plugin will be run twice, once for each lung, and the images combined.


## Context hierarchy

The hierarchy defines how Contexts and Context Sets related to each other. Generally this is through defining a mask for each Context. Each mask is produced by the output of a Plugin, so for example the Left Lung and Right Lung contexts are defined by the masks produced by the left and right lung segmentation Plugin.

When PTK runs a Plugin it looks at the Context that has been requested and the Contexts that the Plugin supports. If they match, it runs the Plugin directly and returns the result. If they do not match, PTK steps up or down through the context hierarchy as required to find a matching set of Contexts that the Plugin does support. When the Plugin runs, its inputs and outputs will be converted automatically between the Contexts.

For example, if you run a Plugin on the full `Lung` Context, but the Plugin only supports the `Lobe` Context Set, PTK will split the image up into the Contexts for each `Lobe`, run the plugin on each Lobe Context, and then combine the output images and return a single combined image back in the `Lung` context set.


## Non-lung context hierarchies

PTK defines its own context hierarchy for lung Contexts, though you could design your own for other types of image hierarchies.


## Specifying Plugin Contexts

A Plugin's Context property specifies the Context Set it uses. The possible values are the numerations of PTKContextSet. If you don't specify a Context property, then PTKContextSet.LungROI is assumed. The ContextSet you specify is the range of Contexts for which you permit this Plugin to be called. The Pulmonary Toolkit will only call the Plugin for the Contexts within this ContextSet


## 'Any' Context Set

Now think of an algorithm for computing the volume of a lung region, or for computing the percentage of emphysema in a region. These algorithms could run on any desired region inside the lung. In this case, you can set the Context Set to `PTKContextSet.Any`, and Plugin can run over any set of Contexts you specify.


## User-generated Contexts

You can use the Manual Segmentation feature (PTK version 0.7 and later) to manually create segmentations. These segmentations can have multiple labels (colours). You can use each individual labelled segmentation as a context, or you can use all the labels together as a single context.

* If you create a manual segmentation called `MySeg`, then specifying `MySeg` as a context for a plugin will run the plugin for a single context which is a mask comprising all the non-zero labels in MySeg.
* You can also specify individual labels as contexts using `MySeg.1` for label 1, `MySeg.2` for label 2, etc.
* You can use the `GetAllContextsForManualSegmentations()` method on the PTKDataset/MimDataset class to return a cell array  of all the contexts that arise from all your labels in all your manual segmentations for this dataset. You can pass this cell array into a `GetResult()` call to run your plugin across all contexts defined by all your manual segmentations.
