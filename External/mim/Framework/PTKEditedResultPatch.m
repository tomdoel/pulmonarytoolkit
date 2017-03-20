classdef PTKEditedResultPatch < PTKPatch
% PTKPatch. Class for sharing image edits with other PTK clients 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    
    properties
        Schema = 1
        PatchType = 'EditedResult'
        SeriesUid
        PluginName
        EditedResult
    end
    
end

