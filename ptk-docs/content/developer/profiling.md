# Profiling

:grey_exclamation: Advanced topic

PTK has built-in profiling capabilities for computing the execution time of plugins.
This don't provide the detailed line-by-line profiling that Matlab's profiler provides; however they have minimal effect on the execution time so they can be a reliable way of reporting timings for different plugin algorithms.

Be aware when using any kind of profiling that PTK's automated cacheing may significantly affect execution time of plugins - to properly measure a plugin's performance you need to ensure the cache is cleared.

To enable PTK profiling:
 * Make sure the property `TimeFunctions = true` is set in `External.mim/Framework/MimConfig`. If you changed this, you should restart Matlab or run `clear all classes` so that PTK picks up the change.
 * Before timing any plugins, ensure that there are no cached results stored. You can try setting plugin caching to memory only, or delete the resutls cache
 * Get the profile results by calling `GetResultWithCacheInfo` instead of `GetResult` on `PTKDataset` which returns the cache info object. This contains `SelfTime` and `ExecutionTime` in the attributes



## Using Matlab's built-in profiler

Matlab provides a much more detailed profiling service which provides line-by-line profiling.
This is particularly useful for profiling performance issues, to find which lines or loops in an algorithm are taking significant execution time.

Be aware that running Matlab's profiling significantly slows down the code. It is not therefore useful as a measure of overall execution time. Also note that Matlab's line-by-line timings can be unreliable below around 0.5s. This means that if a line of code is executed many times, and the execution time of that line is quite small, the overall reported execution of that time bay be significantly overestimated by the profiler.

To start profiling in Matlab, first perform any actions you want firest (eg launch PTK if using the GUI). Then when you are ready to start the thing to be timed, in the command window type:
```
profile on
```

Then run your PTK processing (either in the GUI or through your own code)

To finish profiling and launch the profile results window, type:
```
profile on
```

See Matlab's profiler documentation on how to interpret the results
