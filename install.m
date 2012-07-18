disp('***********************************************************************');
disp(' Pulmonary Toolkit - install script');
disp(' ');
disp(' Use this script when you have a C++ compiler installed.');
disp(' ');
disp(' This script will run Matlab''s mex setup, which will prompt you for information about the compiler - normally you can choose the default options.');
disp(' ');
disp('***********************************************************************');

disp('Running Matlab''s mex setup...');
mex -setup

disp('Compiling mex files');
file_list = dir(fullfile('mex', '*.cpp'));
for index = 1 : numel(file_list)
    filename = file_list(index).name;
    mex_result = mex(fullfile('mex', filename), '-outdir', 'bin');
end

mex_result = mex('-outdir', 'bin', '-IExternal', ['-I' fullfile('External', 'mba', 'include')], ...
    fullfile('External', 'gerardus', 'matlab', 'PointsToolbox', 'mba_surface_interpolation.cpp'), ...
    fullfile('External', 'mba', 'src', 'MBA.cpp'), fullfile('External', 'mba', 'src', 'UCBsplines.cpp'), ...
    fullfile('External', 'mba', 'src', 'UCBsplineSurface.cpp'), fullfile('External', 'mba', 'src', 'MBAdata.cpp'));





disp('***********************************************************************');
disp(' Install complete. If the mex compilation produced errors, you may need to adjust your compiler configuration. For more information run ''doc mex''.');