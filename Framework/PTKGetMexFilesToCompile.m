function mex_files_to_compile_map = PTKGetMexFilesToCompile(reporting)
    % PTKGetMexFilesToCompile. Returns a list of mex files used by PTK
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    root_dir = PTKDirectories.GetSourceDirectory;
    mex_dir = PTKDirectories.GetMexSourceDirectory;

    % Populate list with known mex files
    mex_files_to_compile = PTKMexInfo.empty(0);
    mex_files_to_compile(end + 1) = PTKMexInfo(1, 'PTKFastEigenvalues', 'cpp', mex_dir, [], []);
    mex_files_to_compile(end + 1) = PTKMexInfo(1, 'PTKFastIsSimplePoint', 'cpp', mex_dir, [], []);
    mex_files_to_compile(end + 1) = PTKMexInfo(2, 'PTKWatershedFromStartingPoints', 'cpp', mex_dir, [], []);
    mex_files_to_compile(end + 1) = PTKMexInfo(3, 'PTKWatershedMeyerFromStartingPoints', 'cpp', mex_dir, [], []);
    mex_files_to_compile(end + 1) = PTKMexInfo(2, 'PTKSmoothedRegionGrowingFromBorderedImage', 'cpp', mex_dir, [], []);
    
    mex_files_to_compile(end + 1) = PTKMexInfo(3, 'mba_surface_interpolation', 'cpp', fullfile(root_dir, 'External', 'gerardus', 'matlab', 'PointsToolbox'), ...
        {['-I' fullfile(root_dir, 'External')], ['-I' fullfile(root_dir, 'External', 'mba', 'include')]}, ...
        {fullfile(root_dir, 'External', 'mba', 'src', 'MBA.cpp'), fullfile(root_dir, 'External', 'mba', 'src', 'UCBsplines.cpp'), ...
        fullfile(root_dir, 'External', 'mba', 'src', 'UCBsplineSurface.cpp'), fullfile(root_dir, 'External', 'mba', 'src', 'MBAdata.cpp')});
    
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
            mex_files_to_compile_map(name_part) = PTKMexInfo(0, name_part, 'cpp', mex_dir, [], []);
            reporting.ShowWarning('PTKGetMexFilesToCompile:MexFileNotInList', ['The file ' filename ' was found in the mex folder but has not been added to PTKGetMexFilesToCompile.m. Mex files should be added to PTKGetMexFilesToCompile.m so they are correctly versioned.'], []);
        else
        end
    end
    
end