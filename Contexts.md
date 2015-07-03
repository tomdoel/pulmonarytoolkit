# Introduction #

Contexts are a powerful and important feature of the Pulmonary Toolkit.

If you are doing any kind of programming with the Pulmonary Toolkit, you need to understand how Contexts work.

## What is a context ##

A Context is a region within the lung (or, more generally, a region of the image you are working with). For example, the left lung is a Context, and the right lung is different Context. Each lobe and each segment is also a Context. The entire image is also a Context, the the "lung region of interest" (the cropped image you normally see when you use the GUI) is another Context.

Contexts allow you to control the regions over which your algorithms operate. But most importantly, the Toolkit allows you to automatically run algorithms for multiple Contexts, and combine or split results if required. Let's say you create a algorithm which computes mean tissue density for a lung. Because of Contexts, your algorithm will automatically work for either lung, or for any of the 5 lobes, or any of the segments, or across both lungs - no additional work is required. It is all inherently supported by the Toolkit because of how Contexts work. And the Toolkit can combine together all your results into a single image. Conversely, if you define an algorithm that operates over the whole lung (such as a filtering operation), the Toolkit can automatically extract out a lobe or segmental region from this.

## Context Sets ##

Every Plugin operates on a Context, or a set of Contexts. For example, the airway segmentation algorithm needs to know where in the image to search for the airways, so it uses the Lung Region of Interest Context. It doesn't make sense for the airway segmentation to use any other Context. So this is an example of a Plugin that operates on a single specific Context.

Some Plugins can operate on more than one Context. For example, the lobe segmentation algorithm divides up a lung region into lobes. It operates on the left lung Context or the right lung Context. A `Context Set` is a set of Contexts over which a Plugin can operate. The Single Lung Context Set contains two Contexts, Left Lung and Right Lung. The Lobe Context Set contains five, one for each lobe. Whereas the Lung ROI Context Set only contains one Context, the Lung ROI Context.

## GetResult with a Context ##

When you get any result from the Pulmonary Toolkit (using the `GetResult()` method), you can specify a Context, e.g.

```
dataset.GetResult('MyPlugin', context);
```

where context is one (or a cell array) of the `PTKContext` enumerations. The Pulmonary Toolkit will fetch your result for that particular Context. If you don't specify a Context, then normally `LungROI` is assumed. The exception to this is where a Plugin itself specifies a single particular Context, such as `OriginalImage`.

What happens when you specify a Context depends on how the Plugin operates (see below). The Pulmonary Toolkit will if necessary combine or reduce the results in order to fit the Context you have specified. For example, if a Plugin is set to operate on a single lung (the right or left lung), but you requires a LungROI context, then the Plugin will be run twice, once for each lung, and the images combined.

## Specifying Plugin Contexts ##

A Plugin's Context property specifies the Context Set it uses. The possible values are the numerations of PTKContextSet. If you don't specify a Context property, then PTKContextSet.LungROI is assumed. The ContextSet you specify is the range of Contexts for which you permit this Plugin to be called. The Pulmonary Toolkit will only call the Plugin for the Contexts within this ContextSet

## 'Any' Context Set ##

Now think of an algorithm for computing the volume of a lung region, or for computing the percentage of emphysema in a region. These algorithms could run on any desired region inside the lung. In this case, you can set the Context Set to `PTKContextSet.Any`, and Plugin can run over any set of Contexts you specify.