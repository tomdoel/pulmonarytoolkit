function path_name = MimSavePatchAs(patch_object, path_name, reporting)
    % MimSavePatchAs. Prompts the user for a filename, and saves the patch object
    %
    %     Syntax
    %     ------
    %
    %         MimSavePatchAs(patch_object, path_name, reporting)
    %
    %             patch_object    is a PTKPatch object to be saved
    %             path, filename  specify the location to save the patch pbject.
    %             reporting       an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %  
    
    if ~isa(patch_object, 'PTKPatch')
        error('Requires a PTKPatch as input');
    end
    
    if nargin < 3
        reporting = CoreReportingDefault;
    end
    
    [filename, path_name, filter_index] = SavePatchDialogBox(path_name);
    if filter_index ~= 0
        SavePatch(patch_object, filename, path_name, filter_index, reporting);
    end
end

function [filename, path_name, filter_index] = SavePatchDialogBox(path_name)
    filespec = {'*.ptk', 'PTK Patch'};

    if path_name == 0
        [filename, path_name, filter_index] = uiputfile(filespec, 'Save patch as');
    else
        [filename, path_name, filter_index] = uiputfile(filespec, 'Save patch as', fullfile(path_name, ''));
    end
end
    
function SavePatch(patch_data, filename, pathname, filter_index, reporting)
    reporting.Log(['Saving patch ' filename]);

    if filter_index ~= 0 && ~isequal(filename,0) && ~isequal(pathname,0)
        reporting.Log(['Saving ' fullfile(pathname, filename)]);
        
        switch filter_index
            case 1
                MimDiskUtilities.SavePatchFile(patch_data, fullfile(pathname, filename), reporting);
        end
    end
end
