classdef PTKEditedResultPatch < PTKPatch
    % Class for sharing image edits with other PTK clients 
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    
    properties
        Schema = 1
        PatchType = 'EditedResult'
        SeriesUid
        PluginName
        EditedResult
    end
    
end

