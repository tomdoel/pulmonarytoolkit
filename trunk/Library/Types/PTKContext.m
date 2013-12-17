classdef PTKContext
    % PTKContext. An enumeration used to specify a region of interest
    %
    %     Contexts are used in relation to PTKImageTemplate to request a template
    %     image for a particular region of interest.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    enumeration
        OriginalImage,  % The full image
        LungROI,        % A region containing the lung and airways
        LeftLungROI,    % A region containing the left lung
        RightLungROI,   % A region containing the right lung
        
        Lungs,          % Left and right lung masks after removal of airways

        LeftLung,       % Left lung mask
        RightLung,      % Right lung mask
        
        RightUpperLobe,
        RightMiddleLobe,
        RightLowerLobe,
        LeftUpperLobe,
        LeftLowerLobe
    end
    
end

