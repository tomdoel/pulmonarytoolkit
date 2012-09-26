function TDCompileMexFiles(framework_cache, force_recompile, reporting)
    % TDCompileMexFiles. Checks if mex files are up to date and re-compiles if
    % necessary
    %
    %     TDCompileMexFiles is an internal part of the Pulmonary Toolkit
    %     Framework and is called by TDPTK. In general should not be 
    %     called by your own code.
    %
    %     TDCompileMexFiles contains a list of mex files to be compiled by the
    %     Pulmonary Toolkit, with version numbers. The last compiled versions
    %     are cached in the Framework Cache. If the versions have changed, files
    %     are automatically recompiled. Recompilation also occurs if the output
    %     files are missing or the Framework Cache has been deleted.
    %
    %     TDCompileMexFiles checks for the presence of compilers and warns the
    %     user if no compiler has been detected. TDCompileMexFiles does not
    %     attempt to recompile a particular mex file again after a failed
    %     compile attempt. Recompilation can be achieved using the
    %     force_recompile flag or my deleting the Framework Cache.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    reporting.ShowProgress('Checking mex files');
    root_directory = TDSoftwareInfo.GetSourceDirectory;
    output_directory = fullfile(root_directory, 'bin');
    cached_mex_file_info = framework_cache.MexInfoMap;
    mex_files_to_compile = GetMexFilesToCompile(root_directory, reporting);
    framework_cache_was_missing = framework_cache.IsNewlyCreated;
    
    compiler = GetNameOfCppCompiler;
    if isempty(compiler)
        compiler = MexSetup;
    end
    if ~isempty(compiler)
        CheckMexFiles(mex_files_to_compile, cached_mex_file_info, output_directory, framework_cache_was_missing, reporting);
        Compile(mex_files_to_compile, cached_mex_file_info, output_directory, compiler, force_recompile, reporting);
    end
    framework_cache.MexInfoMap = mex_files_to_compile;
    framework_cache.IsNewlyCreated = false;
    framework_cache.SaveCache;
    reporting.CompleteProgress;
end

function compiler = MexSetup(reporting)
    cpp_compilers = mex.getCompilerConfigurations('C++', 'Installed');
    if isempty(cpp_compilers)
        compiler = [];
        reporting.ShowWarning('TDCompileMexFiles:NoCompiler', 'I cannot compile mex files because no C++ compiler has been found on this system. Some parts of the Toolkit will not function. Install a C++ compiler and run TDPTK.Recompile().', []);
    else
        disp('***********************************************************************');
        disp(' Pulmonary Toolkit - running MEX steup ');
        disp(' ');
        disp(' Follow the instructions below to select a C++ compiler. Normally the default options are good');
        disp(' ');        
        disp('***********************************************************************');
        mex -setup;
        compiler = GetNameOfCppCompiler;
        if isempty(compiler)
            reporting.ShowWarning('TDCompileMexFiles:NoCompiler', 'I cannot compile mex files because no C++ compiler has been selected. Run mex -setup to choose your C++ compiler. Then run TDPTK.Recompile().', []);
        end
    end
end

function Compile(mex_files_to_compile, cached_mex_file_info, output_directory, compiler, force_recompile, reporting)
    progress_message_showing_compile = false;
    for mex_file_s = mex_files_to_compile.values
        mex_file = mex_file_s{1};
        
        if (~mex_file.NeedsRecompile) && (~force_recompile)
            reporting.Log([mex_file.Name ' is up to date']);
            if ~strcmp(mex_file.StatusID, 'TDCompileMexFiles:NoRecompileNeeded')
                reporting.Error('TDCompileMexFiles:WrongStatus', 'Program error: mex status should be OK if a recompile is not required'); 
            end
        else
            if strcmp(mex_file.StatusID, 'TDCompileMexFiles:VersionChanged')
                reporting.ShowMessage('TDCompileMexFiles:VersionChanged', [mex_file.Name ' is out of date']);
            elseif strcmp(mex_file.StatusID, 'TDCompileMexFiles:CompiledFileRemoved')
                reporting.ShowMessage('TDCompileMexFiles:CompiledFileRemoved', [mex_file.Name ': The compiled mex file was removed and must be recompiled.']);
            elseif strcmp(mex_file.StatusID, 'TDCompileMexFiles:FileAdded')
                reporting.ShowMessage('TDCompileMexFiles:FileAdded', ['A new mex file ' mex_file.Name ' has been found and requires compilation.']);
            elseif strcmp(mex_file.StatusID, 'TDCompileMexFiles:NoCachedInfoForMex')
                reporting.ShowMessage('TDCompileMexFiles:NoCachedInfoForMex', [mex_file.Name ' requires compilation.']);
            elseif strcmp(mex_file.StatusID, 'TDCompileMexFiles:CacheFileDeleted')
                reporting.ShowMessage('TDCompileMexFiles:CacheFileDeleted', [mex_file.Name ' requires recompilation because it appears the cache file ' TDSoftwareInfo.FrameworkCacheFileName ' was deleted.']);
            elseif strcmp(mex_file.StatusID, 'TDCompileMexFiles:CompiledFileNotFound')
                reporting.ShowMessage('TDCompileMexFiles:CompiledFileNotFound', [mex_file.Name ' requires compilation.']);


            elseif strcmp(mex_file.StatusID, 'TDCompileMexFiles:NoRecompileNeeded')
                if force_recompile
                    reporting.ShowMessage('TDCompileMexFiles:ForcingRecompile', ['Forcing recompile of ' mex_file.Name '.']);
                else
                    reporting.Error('TDCompileMexFiles:UnexpectedStatus', 'Program error: An unexpected status condiiton was found');
                end
            else
                reporting.Error('TDCompileMexFiles:UnexpectedStatus', 'Program error: An unexpected status condiiton was found'); 
            end
                
            if cached_mex_file_info.isKey(mex_file.Name)
                cached_mex_file = cached_mex_file_info(mex_file.Name);
                version_unchanged_since_last_compilation_attempt = isequal(cached_mex_file.LastAttemptedCompiledVersion, mex_file.CurrentVersion);
                compiler_unchanged_since_last_compilation_attempt = isequal(cached_mex_file.LastAttemptedCompiler, compiler);
                compiled_failed_last_time = cached_mex_file.LastCompileFailed;
                
                if compiled_failed_last_time && version_unchanged_since_last_compilation_attempt && compiler_unchanged_since_last_compilation_attempt;
                    try_compilation_again = false;
                else
                    try_compilation_again = true;
                end
            else
                try_compilation_again = true;
            end
            
            src_filename = [mex_file.Name '.' mex_file.Extension];
            src_fullfile = fullfile(mex_file.Path, src_filename);
            if ~(try_compilation_again || force_recompile)
                reporting.ShowWarning('TDCompileMexFiles:NotRecompiling', ['The mex source file ' src_fullfile ' needs recompilation, but the previous attempt to compile failed so I am not going to try again. You need to force a recompilation using TDPTK.Recompile().'], []);
            else
                if ~exist(src_fullfile, 'file')
                    reporting.ShowWarning('TDCompileMexFiles:SourceFileNotFound', ['The mex source file ' src_fullfile ' was not found. If this file has been removed it should also be removed from the list in TDCompileMexFiles.m'], []);
                else
                    if ~progress_message_showing_compile
                        progress_message_showing_compile = true;
                        reporting.UpdateProgressMessage('Compiling mex files');
                    end
                    mex_arguments = {'-outdir', output_directory};
                    mex_arguments = [mex_arguments, mex_file.CompilerOptions, src_fullfile, mex_file.OtherCompilerFiles];
                    mex_result = mex(mex_arguments{:});
                    mex_file.LastAttemptedCompiledVersion = mex_file.CurrentVersion;
                    mex_file.LastAttemptedCompiler = compiler;
                    if (mex_result == 0)
                        mex_file.LastCompileFailed = false;
                        mex_file.LastSuccessfulCompiledVersion = mex_file.CurrentVersion;
                        mex_file.LastSuccessfulCompiler = compiler;
                        reporting.ShowMessage('TDCompileMexFiles:MexCompilationSucceeded', [' - ' src_filename ' compiled successfully.']);
                    else
                        mex_file.LastCompileFailed = true;
                        reporting.ShowWarning('TDCompileMexFiles:MexCompilationFailed', [' - ' src_fullfile ' failed to compile.'], []);
                    end
                end
            end
        end
    end
end

function mex_files_to_compile_map = GetMexFilesToCompile(root_dir, reporting)
    mex_dir = fullfile(root_dir, 'mex');

    % Populate list with known mex files
    mex_files_to_compile = TDMexInfo.empty(0);
    mex_files_to_compile(end + 1) = TDMexInfo(1, 'TDFastEigenvalues', 'cpp', mex_dir, [], []);
    mex_files_to_compile(end + 1) = TDMexInfo(1, 'TDFastIsSimplePoint', 'cpp', mex_dir, [], []);
    mex_files_to_compile(end + 1) = TDMexInfo(1, 'TDWatershedFromStartingPoints', 'cpp', mex_dir, [], []);
    mex_files_to_compile(end + 1) = TDMexInfo(2, 'TDWatershedMeyerFromStartingPoints', 'cpp', mex_dir, [], []);
    
    mex_files_to_compile(end + 1) = TDMexInfo(1, 'mba_surface_interpolation', 'cpp', fullfile(root_dir, 'External', 'gerardus', 'matlab', 'PointsToolbox'), ...
        {'-IExternal', ['-I' fullfile('External', 'mba', 'include')]}, ...
        {fullfile('External', 'mba', 'src', 'MBA.cpp'), fullfile('External', 'mba', 'src', 'UCBsplines.cpp'), ...
        fullfile('External', 'mba', 'src', 'UCBsplineSurface.cpp'), fullfile('External', 'mba', 'src', 'MBAdata.cpp')});
    
    % Transfer to a map
    mex_files_to_compile_map = containers.Map;
    for mex_file = mex_files_to_compile
        mex_files_to_compile_map(mex_file.Name) = mex_file;
    end
    
    % Now add unknown .cpp files
    file_list = dir(fullfile(mex_dir, '*.cpp'));
    for index = 1 : numel(file_list)
        filename = file_list(index).name;
        [~, name_part, ~] = fileparts(filename);
        if ~mex_files_to_compile_map.isKey(name_part)
            mex_files_to_compile_map(name_part) = TDMexInfo(0, name_part, 'cpp', mex_dir, [], []);
            reporting.ShowWarning('TDCompileMexFiles:MexFileNotInList', ['The file ' filename ' was found in the mex folder but has not been added to TDCompileMexFiles.m. Mex files should be added to TDCompileMexFiles.m so they are correctly versioned.'], []);
        else
        end
    end
    
end


function CheckMexFiles(mex_files_to_compile, cached_mex_file_info, output_directory, framework_cache_was_missing, reporting)
    mex_extension = mexext;
    if ~isempty(mex_extension)
        mex_extension = ['.' mex_extension];
    end
    
    % Iterate through all the mex files to compile
    for mex_file_s = mex_files_to_compile.values
        mex_file = mex_file_s{1};
        
        mex_file.NeedsRecompile = false;
        
        % Check whether the currently compiled file is up to date
        if cached_mex_file_info.isKey(mex_file.Name)
            cached_mex_file = cached_mex_file_info(mex_file.Name);
            
            % Copy across the cached values
            mex_file.LastSuccessfulCompiledVersion = cached_mex_file.LastSuccessfulCompiledVersion;
            mex_file.LastSuccessfulCompiler = cached_mex_file.LastSuccessfulCompiler;
            mex_file.LastAttemptedCompiledVersion = cached_mex_file.LastAttemptedCompiledVersion;
            mex_file.LastAttemptedCompiler = cached_mex_file.LastAttemptedCompiler;
            mex_file.LastCompileFailed = cached_mex_file.LastCompileFailed;
            
            if ~isequal(cached_mex_file.LastSuccessfulCompiledVersion, mex_file.CurrentVersion)
                mex_file.StatusID = 'TDCompileMexFiles:VersionChanged';
                mex_file.NeedsRecompile = true;
            else
                mex_file.StatusID = 'TDCompileMexFiles:NoRecompileNeeded';
            end

            % Check whether compiled file exists. We only need to do this if the
            % cache was found, because otherwise we will be recompiling anyway
            dst_fullfile = fullfile(output_directory, [mex_file.Name, mex_extension]);
            if ~exist(dst_fullfile, 'file')
                mex_file.NeedsRecompile = true;
                
                % Only display a warning message here if there is a record of a
                % previous compilation
                if (~isempty(mex_file.LastSuccessfulCompiledVersion)) && (~mex_file.LastCompileFailed)
                    mex_file.StatusID = 'TDCompileMexFiles:CompiledFileRemoved';
                else
                    mex_file.StatusID = 'TDCompileMexFiles:CompiledFileNotFound';
                end
            end
            
        else
            % No cached file was found. No need to check for existance of
            % outuput file as we will try to recompile anyway
            if framework_cache_was_missing
                dst_fullfile = fullfile(output_directory, [mex_file.Name, mex_extension]);
                if exist(dst_fullfile, 'file')
                    mex_file.StatusID = 'TDCompileMexFiles:CacheFileDeleted';
                else
                    mex_file.StatusID = 'TDCompileMexFiles:NoCachedInfoForMex';
                end
            else
                mex_file.StatusID = 'TDCompileMexFiles:FileAdded';
            end
            mex_file.NeedsRecompile = true;
        end
        
    end
end

function name = GetNameOfCppCompiler
    cc = mex.getCompilerConfigurations('C++', 'Selected');
    if isempty(cc)
        name = [];
    else
        name = cc(1).Name;
    end
end