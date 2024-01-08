# MEX files

If you want to add or update a mex file, you need to update PTKGetMexFilesToCompile.

To add a new entry, add a line of the form

    mex_files_to_compile(end + 1) = PTKMexInfo(1, 'PTKFastEigenvalues', 'cpp', mex_dir, [], []);

If you modify the mex file, update the first parameter to PTKMexInfo. This is the version number, and will force the mex file to recompile if necessary
