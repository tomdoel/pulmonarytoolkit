# Running plugins

You can run Plugins from the GUI for using the PTK API.


## Running Plugins from the GUI

Plugins are hidden in the GUI by default but can be displayed by clicking the `Show Dev Tools` button, which will enable the `Plugins` tab.

Clicking a Plugin button will execute the plugin. If it produces an output image, that will be shown as an overlay once the Plugin completes.

Plugins should not be confused with [Gui Plugins](../plugins/gui-plugins)

## Running Plugins from the API

If you are using the PTK API from within your own code, you call `GetResult()` on your `PTKDataset` object to run a plugin and return the result. You will need to get a different `PTKDataset` for each series you wish to process. `PTKDataset` objects are returned by calling the appropriate methods on the `PTKMain` singleton object which you should create once at the start of your program.
