classdef PTKEditedResultPatch < PTKPatch
% PTKPatch. Class for sharing image edits with other PTK clients 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    
    properties
        Schema = 1
        PatchType = 'EditedResult'
        SeriesUid
        PluginName
        EditedResult
    end
    
end

