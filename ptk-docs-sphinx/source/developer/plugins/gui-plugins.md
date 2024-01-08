# GUI Plugins

GUI Plugins are different from PTK Plugins.

GUI Plugins are Plugins specifically designed to run within the PTK GUI. A GUI Plugin represents a button or control on the PTK GUI interface. The GUI Plugin provides the code that is run when you click the button. Often there is a direct link to a PTK Plugin, in that the GUI Plugin tells PTK to run a specified Plugin on the current dataset and the visualise the results.

You don't normally need to write your own GUI Plugins, because the GUI automatically generates buttons to run your custom plugins. These are shown on the `Plugins` tab which is made visible when you click the `Show Dev Tools` button.

But you can develop GUI Plugins if want to develop a workflow that interacts with the GUI. Developing GUI Plugins is a more advanced topic but you can look at the existing GUI Plugins for examples.
