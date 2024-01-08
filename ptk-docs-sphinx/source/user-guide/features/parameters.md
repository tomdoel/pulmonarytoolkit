# Parameters

Parameters allow you to specify additional variables to be used when running Plugins.

This allows you to run Plugins multiple times with different parameter values. This is useful if you want to compare an algorithm's output with different parameter values, or even if you want to
graph the output over a range of parameter values.

Parameters should be used instead of varying hard-coding values in your Plugins or functions. Parameters use PTK's dependency framework which ensures that Plugins are re-run as required when the parameters change.


## Specifying parameters

Parameters are specified through the API by creating a MimParameters object and passing it as an additional argument to your `GetResult()` call.


## Getting parameter values

Plugins request parameter values using the GetParameter() function in the `MimDatasetResults` callback object
