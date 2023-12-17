classdef PTKContext
    % PTKContext. An enumeration used to specify a region of interest
    %
    %     Contexts are used in relation to PTKImageTemplate to request a template
    %     image for a particular region of interest.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    properties (Constant)
        OriginalImage = 'OriginalImage'  % The full image
        LungROI = 'LungROI'        % A region containing the lung and airways
        LeftLungROI = 'LeftLungROI'    % A region containing the left lung
        RightLungROI = 'RightLungROI'   % A region containing the right lung

        Lungs = 'Lungs'          % Left and right lung masks after removal of airways

        LeftLung = 'LeftLung'       % Left lung mask
        RightLung = 'RightLung'      % Right lung mask

        RightUpperLobe = 'RightUpperLobe'
        RightMiddleLobe = 'RightMiddleLobe'
        RightLowerLobe = 'RightLowerLobe'
        LeftUpperLobe = 'LeftUpperLobe'
        LeftLowerLobe = 'LeftLowerLobe'

        % Right lung segments
        R_AP = 'R_AP'
        R_P = 'R_P'
        R_AN = 'R_AN'
        R_L = 'R_L'
        R_M = 'R_M'
        R_S = 'R_S'
        R_MB = 'R_MB'
        R_AB = 'R_AB'
        R_LB = 'R_LB'
        R_PB = 'R_PB'

        % Left lung segments
        L_APP = 'L_APP'
        L_APP2 = 'L_APP2'
        L_AN = 'L_AN'
        L_SL = 'L_SL'
        L_IL = 'L_IL'
        L_S = 'L_S'
        L_AMB = 'L_AMB'
        L_LB = 'L_LB'
        L_P = 'L_P'

    end

end

