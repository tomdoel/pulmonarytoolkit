function CoreCompileMexFiles(mex_cache, output_directory, mex_files_to_compile, force_recompile, retry_instructions, reporting)
    % CoreCompileMexFiles. Checks if mex files are up to date and re-compiles if
    % necessary
    %
    %     CoreCompileMexFiles takes in a list of mex files to be compiled,
    %     with version numbers. The last compiled versions
    %     are cached using the supplied mex_cache. If the versions have changed, files
    %     are automatically recompiled. Recompilation also occurs if the output
    %     files are missing or the mex_cache file has been deleted.
    %
    %     CoreCompileMexFiles checks for the presence of compilers and warns the
    %     user if no compiler has been detected. CoreCompileMexFiles does not
    %     attempt to recompile a particular mex file again after a failed
    %     compile attempt. Recompilation can be achieved using the
    %     force_recompile flag or by deleting the mex_cache file.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    reporting.ShowProgress('Checking mex files');
    cached_mex_file_info = mex_cache.MexInfoMap;
    framework_cache_was_missing = mex_cache.IsNewlyCreated;
    
    compiler = GetNameOfCppCompiler;
    if isempty(compiler)
        compiler = MexSetup(retry_instructions, reporting);
    end
    if ~isempty(compiler)
        CheckMexFiles(mex_files_to_compile, cached_mex_file_info, output_directory, framework_cache_was_missing, reporting);
        Compile(mex_files_to_compile, mex_cache, cached_mex_file_info, output_directory, compiler, force_recompile, reporting);
    end
    mex_cache.MexInfoMap = mex_files_to_compile;
    mex_cache.IsNewlyCreated = false;
    mex_cache.SaveCache(reporting);
    reporting.CompleteProgress;
end

function compiler = MexSetup(retry_instructions, reporting)
    cpp_compilers = mex.getCompilerConfigurations('C++', 'Installed');
    if isempty(cpp_compilers)
        compiler = [];
        reporting.ShowWarning('CoreCompileMexFiles:NoCompiler', ['I cannot compile mex files because no C++ compiler has been found on this system. Some parts of the Toolkit will not function. Install a C++ compiler.' retry_instructions], []);
    else
        disp('***********************************************************************');
        disp(' CoreMat - running MEX steup ');
        disp(' ');
        disp(' Follow the instructions below to select a C++ compiler. Normally the default options are good');
        disp(' ');        
        disp('***********************************************************************');
        mex -setup;
        compiler = GetNameOfCppCompiler;
        if isempty(compiler)
            reporting.ShowWarning('CoreCompileMexFiles:NoCompiler', ['I cannot compile mex files because no C++ compiler has been selected. Run mex -setup to choose your C++ compiler.' retry_instructions], []);
        end
    end
end

function Compile(mex_files_to_compile, framework_cache, cached_mex_file_info, output_directory, compiler, force_recompile, reporting)
    progress_message_showing_compile = false;
    for mex_file_s = mex_files_to_compile.values
        mex_file = mex_file_s{1};
        
        if (~mex_file.NeedsRecompile) && (~force_recompile)
            reporting.Log([mex_file.Name ' is up to date']);
            if ~strcmp(mex_file.StatusID, 'CoreCompileMexFiles:NoRecompileNeeded')
                reporting.Error('CoreCompileMexFiles:WrongStatus', 'Program error: mex status should be OK if a recompile is not required'); 
            end
        else
            if strcmp(mex_file.StatusID, 'CoreCompileMexFiles:VersionChanged')
                reporting.ShowMessage('CoreCompileMexFiles:VersionChanged', [mex_file.Name ' is out of date']);
            elseif strcmp(mex_file.StatusID, 'CoreCompileMexFiles:CompiledFileRemoved')
                reporting.ShowMessage('CoreCompileMexFiles:CompiledFileRemoved', [mex_file.Name ': The compiled mex file was removed and must be recompiled.']);
            elseif strcmp(mex_file.StatusID, 'CoreCompileMexFiles:FileAdded')
                reporting.ShowMessage('CoreCompileMexFiles:FileAdded', ['A new mex file ' mex_file.Name ' has been found and requires compilation.']);
            elseif strcmp(mex_file.StatusID, 'CoreCompileMexFiles:NoCachedInfoForMex')
                reporting.ShowMessage('CoreCompileMexFiles:NoCachedInfoForMex', [mex_file.Name ' requires compilation.']);
            elseif strcmp(mex_file.StatusID, 'CoreCompileMexFiles:CacheFileDeleted')
                reporting.ShowMessage('CoreCompileMexFiles:CacheFileDeleted', [mex_file.Name ' requires recompilation because it appears the cache file ' framework_cache.GetCacheFilename ' was deleted.']);
            elseif strcmp(mex_file.StatusID, 'CoreCompileMexFiles:CompiledFileNotFound')
                reporting.ShowMessage('CoreCompileMexFiles:CompiledFileNotFound', [mex_file.Name ' requires compilation.']);


            elseif strcmp(mex_file.StatusID, 'CoreCompileMexFiles:NoRecompileNeeded')
                if force_recompile
                    reporting.ShowMessage('CoreCompileMexFiles:ForcingRecompile', ['Forcing recompile of ' mex_file.Name '.']);
                else
                    reporting.Error('CoreCompileMexFiles:UnexpectedStatus', 'Program error: An unexpected status condiiton was found');
                end
            else
                reporting.Error('CoreCompileMexFiles:UnexpectedStatus', 'Program error: An unexpected status condiiton was found'); 
            end
                
            if cached_mex_file_info.isKey(mex_file.Name)
                cached_mex_file = cached_mex_file_info(mex_file.Name);
                version_unchanged_since_last_compilation_attempt = isequal(cached_mex_file.LastAttemptedCompiledVersion, mex_file.CurrentVersion);
                compiler_unchanged_since_last_compilation_attempt = isequal(cached_mex_file.LastAttemptedCompiler, compiler);
                compiled_failed_last_time = cached_mex_file.LastCompileFailed;
                if isempty(compiled_failed_last_time)
                    compiled_failed_last_time = false;
                end
                
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
                reporting.ShowWarning('CoreCompileMexFiles:NotRecompiling', ['The mex source file ' src_fullfile ' needs recompilation, but the previous attempt to compile failed so I am not going to try again. You need to force a recompilation.' retry_instructions], []);
            else
                if ~exist(src_fullfile, 'file')
                    reporting.ShowWarning('CoreCompileMexFiles:SourceFileNotFound', ['The mex source file ' src_fullfile ' was not found. If this file has been removed it should also be removed from the list of mex files'], []);
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
                        reporting.ShowMessage('CoreCompileMexFiles:MexCompilationSucceeded', [' - ' src_filename ' compiled successfully.']);
                    else
                        mex_file.LastCompileFailed = true;
                        reporting.ShowWarning('CoreCompileMexFiles:MexCompilationFailed', [' - ' src_fullfile ' failed to compile.'], []);
                    end
                end
            end
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
                mex_file.StatusID = 'CoreCompileMexFiles:VersionChanged';
                mex_file.NeedsRecompile = true;
            else
                mex_file.StatusID = 'CoreCompileMexFiles:NoRecompileNeeded';
            end

            % Check whether compiled file exists. We only need to do this if the
            % cache was found, because otherwise we will be recompiling anyway
            dst_fullfile = fullfile(output_directory, [mex_file.Name, mex_extension]);
            if ~exist(dst_fullfile, 'file')
                mex_file.NeedsRecompile = true;
                
                % Only display a warning message here if there is a record of a
                % previous compilation
                if (~isempty(mex_file.LastSuccessfulCompiledVersion)) && (~mex_file.LastCompileFailed)
                    mex_file.StatusID = 'CoreCompileMexFiles:CompiledFileRemoved';
                else
                    mex_file.StatusID = 'CoreCompileMexFiles:CompiledFileNotFound';
                end
            end
            
        else
            % No cached file was found. No need to check for existance of
            % output file as we will try to recompile anyway
            if framework_cache_was_missing
                dst_fullfile = fullfile(output_directory, [mex_file.Name, mex_extension]);
                if exist(dst_fullfile, 'file')
                    mex_file.StatusID = 'CoreCompileMexFiles:CacheFileDeleted';
                else
                    mex_file.StatusID = 'CoreCompileMexFiles:NoCachedInfoForMex';
                end
            else
                mex_file.StatusID = 'CoreCompileMexFiles:FileAdded';
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