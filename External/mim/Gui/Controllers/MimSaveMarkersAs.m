function path_name = MimSaveMarkersAs(markers_struct, path_name, reporting)
    % MimSaveMarkersAs. Prompts the user for a filename, and saves the markers object
    %
    %     Syntax
    %     ------
    %
    %         MimSaveMarkersAs(patch_object, path_name, reporting)
    %
    %             markers_struct    is a struct to be saved in XML
    %             path_name  specify the location to save the xml file.
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
    
    if ~isstruct(markers_struct)
        error('Requires a struct as input');
    end
    
    if nargin < 3
        reporting = CoreReportingDefault();
    end
    
    [filename, path_name, filter_index] = SaveMarkersDialogBox(path_name);
    if filter_index ~= 0
        SaveMarkers(markers_struct, filename, path_name, filter_index, reporting);
    end
end

function [filename, path_name, filter_index] = SaveMarkersDialogBox(path_name)
    filespec = {'*.xml', 'Markers'};

    if path_name == 0
        [filename, path_name, filter_index] = uiputfile(filespec, 'Save markers as');
    else
        [filename, path_name, filter_index] = uiputfile(filespec, 'Save markers as', fullfile(path_name, ''));
    end
end
    
function SaveMarkers(markers_struct, filename, pathname, filter_index, reporting)
    reporting.Log(['Saving markers ' filename]);

    if filter_index ~= 0 && ~isequal(filename,0) && ~isequal(pathname,0)
        reporting.Log(['Saving ' fullfile(pathname, filename)]);
        
        switch filter_index
            case 1
                alias_mapping = containers.Map();
                alias_mapping('MimMarkerPoint') = 'Marker';
                CoreSaveXmlSimplified(markers_struct, 'MimMarkerPoints', fullfile(pathname, filename), alias_mapping, reporting);
        end
    end
end
