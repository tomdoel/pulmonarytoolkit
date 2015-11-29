classdef GemAxisCache
    % GemAxisCache. Contains axes information which can be used to restore axes to a
    % particular state
    %
    %     This class is used by GemAxesUse this class when you trigger an event which needs to provide data
    %     to its listeners.
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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