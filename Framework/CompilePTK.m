function CompilePTK
    Compile(true);  % Compile GUI
    Compile(false); % Compile API
end

function Compile(is_gui)
    if is_gui
        main_function_file = 'PulmonaryToolkit.m';
        compiled_output_subfolder = 'compiled';
    else
        main_function_file = 'PulmonaryToolkitAPI.m';
        compiled_output_subfolder = 'compiled_api';
    end
    compiled_output_path = GetCompiledOutputPath(compiled_output_subfolder);
    PTKAddPaths;
    
    % Create a PTKMain object to ensure mex files are compiled
    PTKMain(CoreReporting);
    
    CoreDiskUtilities.CreateDirectoryIfNecessary(compiled_output_path);

    plugins = GetListOfPlugins;
    scripts = GetListOfScripts;
    gui_plugins = GetListOfGuiPlugins;
    
    dirs_to_include = {'bin', 'External', 'Framework', 'Plugins', 'Scripts'};
    if is_gui
        dirs_to_include{end + 1} = 'Gui';
    end
    
    temp_compile_options_file = CreateTemporaryCompileOptionsFile(dirs_to_include, main_function_file, compiled_output_path);
        
    fileID = fopen(fullfile(compiled_output_path, 'plugin_dependencies.m'), 'w');
    fprintf(fileID, '%s\n', 'function plugin_dependencies');

    for plugin = plugins
        include_string = ['%#' plugin{1}.First];
        fprintf(fileID, '%s\n', include_string);
    end
    
    for script = scripts
        include_string = ['%#' script{1}.First];
        fprintf(fileID, '%s\n', include_string);
    end
    
    for gui_plugin = gui_plugins
        include_string = ['%#' gui_plugin{1}.First];
        fprintf(fileID, '%s\n', include_string);
    end
    
    mex_file_list = GetListOfMexFiles;
    for mex_file = mex_file_list
        [~, main_name, ~] = fileparts(mex_file{1});
        include_string = ['%#' main_name];
        fprintf(fileID, '%s\n', include_string);
    end
    
    fprintf(fileID, '%s\n', 'end');
    fclose(fileID);
    RenameMatlabFilesInMexFolder;
    mcc('-B', fullfile(compiled_output_path, 'compileopts_gen'));
    RestoreMatlabFilesInMexFolder;
end

function temporary_file = CreateTemporaryCompileOptionsFile(dirs_to_include, main_function_file, compiled_output_path)
    file_entries = [];
    file_entries{end + 1} = ['-m ' fullfile(GetBasePath, main_function_file) ' '];
    file_entries{end + 1} = '-v ';
    file_entries{end + 1} = ['-d ' compiled_output_path ' '];
    file_entries{end + 1} = ['-a ' fullfile(compiled_output_path, 'plugin_dependencies') ' '];
    file_entries{end + 1} = ['-a ' fullfile(GetBasePath, 'PTKConfig.m') ' '];
    for next_dir = dirs_to_include
        file_entries{end + 1} = ['-a ' fullfile(GetBasePath, next_dir{1})];
    end
    for lib_function = CoreDiskUtilities.GetDirectoryFileList(fullfile(GetBasePath, 'Library'), '*.m')
        next_lib_fun = lib_function{1};
        file_entries{end + 1} = ['-a ' fullfile(GetBasePath, 'Library', next_lib_fun)];
    end
    for lib_dir = CoreDiskUtilities.GetRecursiveListOfDirectories(fullfile(GetBasePath, 'Library'))
        next_lib_dir = lib_dir{1}.First;
        if ~(strcmp(next_lib_dir(end-2:end), 'mex') || strcmp(next_lib_dir(end-6:end), 'Library'))
            file_entries{end + 1} = ['-a ' next_lib_dir];
        end
    end

    temporary_file = fopen(fullfile(compiled_output_path, 'compileopts_gen'), 'w');
    for entry = file_entries
        fprintf(temporary_file, '%s \n', entry{1});
    end
    fclose(temporary_file);
end

function mex_file_list = GetListOfMexFiles
    mex_file_list = CoreDiskUtilities.GetRecursiveListOfFiles(GetCompiledMexFilesPath, '*');
end

function RenameMatlabFilesInMexFolder
    for mex_matlab_function = CoreDiskUtilities.GetDirectoryFileList(fullfile(GetBasePath, 'Library', 'mex'), '*.m')
        next_mat_fun = mex_matlab_function{1};
        filename = fullfile(GetBasePath, 'Library', 'mex', next_mat_fun);
        movefile(filename, [filename '.renamed']);
    end
end

function RestoreMatlabFilesInMexFolder
    for mex_matlab_function = CoreDiskUtilities.GetDirectoryFileList(fullfile(GetBasePath, 'Library', 'mex'), '*.renamed')
        next_mat_fun = mex_matlab_function{1};
        filename = fullfile(GetBasePath, 'Library', 'mex', next_mat_fun);
        movefile(filename, filename(1:end-8));
    end
end

function plugin_name_list = GetListOfPlugins(obj)
    % Obtains a list of all plugins available for this app
    app_def = PTKAppDef();
    plugin_name_list = {};
    plugins_folders = app_def.GetListOfPluginsFolders();
    for folder = plugins_folders
        plugin_names = CoreDiskUtilities.GetAllMatlabFilesInFolders(CoreDiskUtilities.GetRecursiveListOfDirectories(folder{1}));
        plugin_name_list = horzcat(plugin_name_list, plugin_names);
    end
end

function plugin_name_list = GetListOfGuiPlugins(obj)
    % Obtains a list of all Gui plugins available for this app

    app_def = PTKAppDef();
    plugin_name_list = {};
    plugins_folders = app_def.GetListOfGuiPluginsFolders();
    for folder = plugins_folders
        plugin_names = CoreDiskUtilities.GetAllMatlabFilesInFolders(CoreDiskUtilities.GetRecursiveListOfDirectories(folder{1}));
        plugin_name_list = horzcat(plugin_name_list, plugin_names);
    end
end

function plugin_name_list = GetListOfScripts
    plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(GetListOfScriptsFolders);
end

function plugin_name_list = GetListOfScriptsFolders
    plugin_name_list = CoreDiskUtilities.GetRecursiveListOfDirectories(GetScriptsPath);
end

function base_path = GetBasePath
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    base_path = fullfile(path_root, '..');
end

function plugins_path = GetCompiledOutputPath(compiled_output_subfolder)
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    plugins_path = fullfile(path_root, '..', compiled_output_subfolder);
end

function plugins_path = GetCompiledMexFilesPath
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    plugins_path = fullfile(path_root, '..', 'bin');
end

function plugins_path = GetScriptsPath
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    plugins_path = fullfile(path_root, '..', PTKSoftwareInfo.ScriptsDirectoryName);
end
