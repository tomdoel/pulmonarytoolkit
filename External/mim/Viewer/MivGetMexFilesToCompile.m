function mex_files_to_compile_map = MivGetMexFilesToCompile(reporting)
    % MivGetMexFilesToCompile. Returns a list of mex files used by PTK
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    % Populate list with known mex files
    mex_files_to_compile = CoreCompiledFileInfo.empty(0);
    
% Add mex files using the following template
%     mex_files_to_compile(end + 1) = CoreCompiledFileInfo(1, 'mex_file_name', 'cpp', 'mex_file_dir', [], []);
    
    % Transfer to a map
    mex_files_to_compile_map = containers.Map;
    for mex_file = mex_files_to_compile
        mex_files_to_compile_map(mex_file.Name) = mex_file;
    end
end