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
    mex(fullfile('mex', filename));
end

disp('***********************************************************************');
disp(' Install complete. If the mex compilation produced errors, you may need to adjust your compiler configuration. For more information run ''doc mex''.');