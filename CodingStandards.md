# Coding standards #

## Introduction ##

This page describes standards and conventions which should be followed by code in the project. These standards help to make the framework stable and consistent.



## Commenting ##

  * Code should aim to be self-commenting. In other words, choose variable, property and method names which are self-explanatory, rather than having to explain them using comments. If `r` is the radius of a circle in mm, rename it `radius_of_circle_in_mm`. If the function `Multiply` multiplies two vectors together, rename it `MultiplyTwoVectors`.
  * Descriptive comments should be added where this aids in the understanding of the code, but not where an operation is obvious from reading the code. Only add comments where self-commenting is insufficient to explain what is going on.
  * A brief summary should be included at the top of each file, in Matlab help format.
  * Academic references should be included where appropriate, e.g. if the function is implementing an algorithm described in a journal paper.
  * Website links should not be included, except to the Pulmonary Toolkit project.
  * Commented-out code should never be committed to the codebase. Commented-out code can and will be deleted at will without warning.


## Functions and Classes ##

  * Code within the framework and user interface should be in classes.
  * Data types and interfaces should be declared as classes in the Types folder.
  * General utility functions should be located in the Utilities folder. They can be single function files or grouped into static classes.
  * Image processing algorithms should be single function files and should be located in the Library folder.
  * All classes must inherit from handle
  * Class properties which contain handle objects must **never** be initialised in the Properties definition list of the class. This is due to the way Matlab initialises variables. If a handle class is instantiated in the properties list, a single instance will be created of that property object which will be applied to all instances of the class.

## Variables ##

### Naming ###

  * Local variables should be named in lower case with connecting underscores, e.g. `radius_of_circle_in_mm`.
  * Properties should be named in Java style like this: `PropertyName`
  * Variables should be given meaningful names, and should not be named `x`, `y`, `i`, etc. except for co-ordinates.
  * Co-ordinates should be named `i`, `j`, `k` instead of `x`, `y`, `z`. This is because Matlab stores matrices as `(y,x,z)` which causes confusion between the `x` and `y` co-ordinates. Always use `(i,j,k)` where `i` is the first coordinate. This avoids any ambiguity.
  * Index variables should not be named `i`, `x` etc. They should at least be called `index`, and better still something more descriptive e.g. `file_list_index`.

### Global variables ###

Global variables must not be used.

## Display of Messages, errors, warnings and progress ##

All display of messages, warnings, errors and progress  bars should be made through TDReporting objects. Code within the framework and plugins should not write to the command window or dialogs directly.


## Plugins ##

### Button text ###
  * When choosing text for the `ButtonText` property, note that this is used both for the GUI and also in the progress dialog. Choose text that makes sense when you see the phrase `Computing <button text>`. For example, `Airway Skeleton` is OK because `Computing Airway Skeleton` sounds fine, but `Show Airway Skeleton` is not good because Computing Show Airway Skeleton` makes no sense.