classdef PTKPulmonarySegmentLabels < uint8
    % PTKPulmonarySegmentLabels. An enumeration used to label the pulmonary
    % segments
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    enumeration
        % Right lung
        R_AP  (1)
        R_P   (2)
        R_AN  (3)
        R_L   (4)
        R_M   (5)
        R_S   (6)
        R_MB  (7)
        R_AB  (8)
        R_LB  (9)
        R_PB  (10)
        
        % Left lung
        L_APP (11)
        L_APP2 (12)
        L_AN  (13)
        L_SL  (14)
        L_IL  (15)
        L_S   (16)
        L_AMB (18)
        L_LB  (19)
        L_PB  (20)
    end
end