classdef PTKAxisCache
    % PTKAxisCache. Contains axes information which can be used to restore axes to a
    % particular state
    %
    %     This class is used by PTKAxesUse this class when you trigger an event which needs to provide data
    %     to its listeners.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        XLim
        YLim
        XRange
        YRange
        ResetAxisData
        AxesAspectRatio
        DataAspectRatio
    end    
end