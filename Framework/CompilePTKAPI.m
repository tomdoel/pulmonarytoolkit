function CompilePTKAPI
    PTKAddPaths;
    
    CoreDiskUtilities.CreateDirectoryIfNecessary(GetCompiledOutputPath);
    
    plugins = GetListOfPlugins;
    scripts = GetListOfScripts;
    gui_plugins= PTKDirectories.GetListOfGuiPlugins;
    
    dirs_to_include = {'bin', 'Contexts', 'External', 'Framework', 'Plugins', 'Scripts', 'SharedPlugins'};
    temp_compile_options_file = CreateTemporaryCompileOptionsFile(dirs_to_include);
        
    fileID = fopen(fullfile(GetCompiledOutputPath, 'plugin_dependencies.m'), 'w');
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
    mcc -B ./compiled_api/compileopts_gen
end

function temporary_file = CreateTemporaryCompileOptionsFile(dirs_to_include)
    file_entries = [];
    file_entries{end + 1} = ['-m ' fullfile(GetBasePath, 'PulmonaryToolkitAPI.m') ' '];
    file_entries{end + 1} = '-v ';
    file_entries{end + 1} = ['-d ' GetCompiledOutputPath ' '];
    file_entries{end + 1} = ['-a ' fullfile(GetCompiledOutputPath, 'plugin_dependencies') ' '];
    file_entries{end + 1} = ['-a ' fullfile(GetBasePath, 'PTKConfig.m') ' '];
    for next_dir = dirs_to_include
        file_entries{end + 1} = ['-a ' fullfile(GetBasePath, next_dir{1})];
    end
    for lib_function = CoreDiskUtilities.GetDirectoryFileList(fullfile(GetBasePath, 'Library'), '*.m')
        next_lib_fun = lib_function{1};
        file_entries{end + 1} = ['-a ' fullfile(GetBasePath, 'Library') '/' next_lib_fun];
    end
    for lib_dir = CoreDiskUtilities.GetRecursiveListOfDirectories(fullfile(GetBasePath, 'Library'))
        next_lib_dir = lib_dir{1}.First;
        if ~(strcmp(next_lib_dir(end-2:end), 'mex') || strcmp(next_lib_dir(end-6:end), 'Library'))
            file_entries{end + 1} = ['-a ' next_lib_dir];
        end
    end

    temporary_file = fopen(fullfile(GetCompiledOutputPath, 'compileopts_gen'), 'w');
    for entry = file_entries
        fprintf(temporary_file, '%s \n', entry{1});
    end
    fclose(temporary_file);
end

function mex_file_list = GetListOfMexFiles
    mex_file_list = CoreDiskUtilities.GetRecursiveListOfFiles(GetCompiledMexFilesPath, '*');
end

function plugin_name_list = GetListOfPlugins
    shared_plugins = GetListOfSharedPlugins;
    app_plugins = GetListOfAppPlugins;
    plugin_name_list = horzcat(shared_plugins, app_plugins);
end

function plugin_name_list = GetListOfScripts
    plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(GetListOfScriptsFolders);
end

function plugin_name_list = GetListOfScriptsFolders
    plugin_name_list = CoreDiskUtilities.GetRecursiveListOfDirectories(GetScriptsPath);
end

function plugin_name_list = GetListOfSharedPlugins
    plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(GetListOfSharedPluginFolders);
end

function plugin_folders = GetListOfSharedPluginFolders
    plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(GetSharedPluginsPath);
end

function plugin_name_list = GetListOfAppPlugins
    plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(GetListOfAppPluginFolders);
end

function plugin_folders = GetListOfAppPluginFolders
    plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(GetPluginsPath);
end

function base_path = GetBasePath(~)
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    base_path = fullfile(path_root, '..');
end

function plugins_path = GetCompiledOutputPath(~)
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    plugins_path = fullfile(path_root, '..', 'compiled_api');
end

function plugins_path = GetCompiledMexFilesPath(~)
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    plugins_path = fullfile(path_root, '..', 'bin');
end

function plugins_path = GetPluginsPath(~)
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    plugins_path = fullfile(path_root, '..', PTKSoftwareInfo.PluginDirectoryName);
end

function plugins_path = GetSharedPluginsPath(~)
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    plugins_path = fullfile(path_root, '..', PTKSoftwareInfo.SharedPluginDirectoryName);
end        

function plugins_path = GetScriptsPath(~)
    full_path = mfilename('fullpath');
    [path_root, ~, ~] = fileparts(full_path);
    plugins_path = fullfile(path_root, '..', PTKSoftwareInfo.ScriptsDirectoryName);
end        
