# Error and Progress Reporting #

## Philosophy ##

The Pulmonary Toolkit can be run in a number of different ways. It may be run from the graphical user interface, as part of a batch script computing results for multiple datasets, or integrated seamlessly within other software.

Often, it is useful or necessary for algorithms to provide feedback, such as error or warning messages, other information or details of algorithm progress. The way in which this information is processed or displayed to the user depends very much on the way in which the Toolkit is being used. For example, when interacting with the GUI, the user will want to know immediately if an error occurred so they can attempt to fix it. Whereas when running batch operations, it may be better to store error messages so they can be reviewed later after all computations have completed.

For this reason, the Toolkit provides a single, unified framework for providing feedback to the user. This includes error and warning messages, progress information (typically shown as a progress bar) and other information messages such as the location of cache files.


## PTKReportingInterface ##

The Toolkit uses a 'callback' mechanism. A 'reporting' object is provided to plugins and other functions, which they should use to provide all such error, warning and progress feedback. This reporting object implements the `PTKReportingInterface` interface, which provides a standard set of methods for reporting errors, warnings, messages and progress.

## Coding standards ##

The coding standard requires all feedback to the user (including errors, warnings and progress) should be provided via the `PTKReportingInterface`, so that the Toolkit is capable of running silently.

Therefore, the following are not permitted by the coding standard
  * output to the command line e.g. `disp`, `sprint`, `pause` etc.
  * progress bars e.g. `waitbar`
  * errors and warnings e.g. `error`, `warning`


## Implementing errors, warning etc. ##

See `PTKReportingInterface.m` for more information on how to use this interface, and see other Toolkit classes for how they use this to handle error and warning messages.

Examples:
```
    % Report a warning
    reporting.Warning('PTKClassName:ErrorName', 'A warning to the user', []);

    % Report an error
    reporting.Error('PTKClassName:ErrorName', 'This error occurred. Here;s a suggestion on how to fix it.');
```

Note the `PTKClassName:ErrorName` follows Matlab's standards for error and warning labels. See `doc error` or `doc warning` for more information.


## How to provide a PTKReportingInterface when using the Toolkit ##

When you use the Toolkit in your own code, the Toolkit by default uses a standard reporting implementation `PTKReportingDefault`. This displays a progress bar and writes error and warning messages to Matlab's command window.
```
    % With no reporting; object specified, the Toolkit will create a PTKReportingDefault object 
    ptk = PTKMain();
```

You can instead choose to provide your own implementation of PTKReportingInterface.
This allows you as a programmer to decide how error and  warning messages etc. are dealt with- e.g. whether you want to terminate the program or reporting a warning message and continue.

To do this, implement the `PTKReportingInterface` in a class called `MyReportingObject` You provide a reporting object to the `PTKMain` constructor:
```
    reporting = MyReportingObject();
    ptk = PTKMain(reporting);
```