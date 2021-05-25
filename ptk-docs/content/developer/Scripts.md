# Scripts

_Added in PTK v0.6.4_
_Base class PTKScript renamed to MimScript in PTK v0.7.3_

Scripts are functions you can run to script analysis across a range of datasets. The function is encapsulated in a class that inherits from `MimScript`. You call a `MimScript` using the `RunScript` method of a `PTKMain` object:

    ptk_main.RunScript(script_name, script_arguments);

For example, the `PTKImportAndAnalyse` script takes two input arguments, `import_dir` and `log_file_name`. This script will import all datasets from the  `import_dir` folder and perform lobe analysis and metrics for each dataset:

    ptk_main = PTKMain;
    ptk_main.RunScript('PTKImportAndAnalyse', import_dir, log_file_name);

You can write your own `PTKScript` by creating a class that implements `MimScript` and placing it in the `Scripts` folder. The `RunScript` method takes in the following arguments:

    function output = RunScript(ptk_obj, reporting, varargin)

`ptk_obj` is the `PTKMain` object that was used to run the script. `Reporting` is the `PTKReporting` object you can use to reports errors, warnings and progress. You can have multiple custom input arguments in `varargin`.

Coding a `Script` is similar to using the API directly; however, you may find it easier to share scripts with others using a `Script`. They are also compatible with the PTK Compiler, so you can create standalone applications for other to run your script without the user having to install or run Matlab.
