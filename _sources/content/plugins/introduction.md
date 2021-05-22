# Introduction to PTK Plugins

Processing in PTK is done through Plugins.

In PTK, a **Plugin** is the code which runs part of your computational pipeline. Instead of writing a huge function which attempts to do everything, you can split up your processing into modular Plugins, each of which handles one stage of the processing. For example, some of PTK's provided plugins include airway segmentation, lung segmentation, lobe segmentation, registration and airway model generation. Each of these plugins typically consist of many more Plugins, which break down the computation into small modular elements.

There are many advantages to PTK's Plugin approach, including:

 - Plugins makes it easier to test and debug each stage of your pipeline. You can visualise the output of each Plugin directly in the viewer. If you modify the Plugin codep (for example, to tweak a parameter), you can re-run just that Plugin without having to re-run your whole pipeline
 - Plugins provide automatic disk and memory caching which can hugely speed up your processing if stages are re-used. For example, airway segmentations might be used by both a lung segmentation plugin and a lobe segmentation plugin. Because the airway segmentation result is cached, it is only run once no matter how many times it is used in other pipelines.
 - Plugins incorporate a robust dependency mechanism. If you modify a Plugin's code, PTK knows which cached Plugin results need to be regenerated.


## Plugin architecture

In PTK, Plugins are classes which inherit from `PTKPlugin`.
 - _Technical note: PTKPlugin inherits from `MimPlugin` which is the base class for Plugins in the MIM (Medical Imaging and Modelling) framework, which is the more general architecture upon which PTK is built._

Plugin classes set properties which tell PTK how the Plugin can be used, and methods which allow PTK to run and interact with the Plugin. The most important is the `RunPlugin()` method which is what PTK executes when it runs the Plugin.

Plugins can contain any code. However, as described below, Plugins often delegate the actually processing to external functions in the [PTK Library](../ptk-library/introduction). Therefore Plugins can often be thought of as integration wrappers, or the "glue" which links the PTK architecture to processing functions. A common pattern is for a Plugin to fetch the required inputs from the PTK API (often by calling other Plugins using `GetResult()`), feed these inputs into one or more eternal functions, and then assemble the outputs into a result which is returned to PTK.


### Running PTK algorithms directly without using the API: the PTK Library

You don't call Plugins directly; you invoke them using the PTK API. This is because PTK needs to provide the Plugin with callback functions which allow the Plugin to get its required inputs.

While Plugins can contain any code, in many cases the bulk of the processing is done by calling out to functions in the PTK Library. This means that if the PTK API and Plugin architecture is not suitable for your purposes, you can still use the bulk of PTK's processing algorithms in your own code b directly calling the PTK Library functions, without having to go through the API. See the [PTK Library](../ptk-library/introduction) pages for more details.
