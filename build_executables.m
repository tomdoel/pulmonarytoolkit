% Reset path in case it contains folders that will be removed
path(pathdef);
create_empty_dir('./dist');
create_empty_dir('./build');

% Add paths
PTKAddPaths();

% On OSX this variable can cause problems so clear it
setenv('DYLD_LIBRARY_PATH');

% Compile GUI and API into executables
CompilePTK();

% Archive into zip or .tar.gz files according to platform
cd compiled
make_archive('ptk_gui');
cd ../compiled_api
make_archive('ptk_api');
cd ..

function create_empty_dir(dir_name)
    if exist(dir_name, 'dir') == 7
        rmdir(dir_name, 's');
    end
    mkdir(dir_name);
end

function make_archive(output_prefix)
    if ispc
        system(['zip -r ..\dist\' output_prefix '_win.zip . -x "plugin_dependencies.m" -x "compileopts_gen"'])
    elseif ismac
        system(['tar --exclude=plugin_dependencies.m --exclude=compileopts_gen -czf ../dist/' output_prefix '_macos.tar.gz .']);
    else
        system(['tar --exclude=plugin_dependencies.m --exclude=compileopts_gen -czf ../dist/' output_prefix '_linux.tar.gz .']);
    end
end
