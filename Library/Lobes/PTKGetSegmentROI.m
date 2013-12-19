function mask = PTKGetSegmentROI(segment_mask, context, reporting)
    % PTKGetSegmentROI. Extracts a region of interest for one of the segments.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    mask = segment_mask.BlankCopy;
    
    if context == PTKContext.R_AP
        colormap_index = PTKPulmonarySegmentLabels.R_AP;
    elseif context == PTKContext.R_P
        colormap_index = PTKPulmonarySegmentLabels.R_P;
    elseif context == PTKContext.R_AN
        colormap_index = PTKPulmonarySegmentLabels.R_AN;
    elseif context == PTKContext.R_L
        colormap_index = PTKPulmonarySegmentLabels.R_L;
    elseif context == PTKContext.R_M
        colormap_index = PTKPulmonarySegmentLabels.R_M;
    elseif context == PTKContext.R_S
        colormap_index = PTKPulmonarySegmentLabels.R_S;
    elseif context == PTKContext.R_MB
        colormap_index = PTKPulmonarySegmentLabels.R_MB;
    elseif context == PTKContext.R_AB
        colormap_index = PTKPulmonarySegmentLabels.R_AB;
    elseif context == PTKContext.R_LB
        colormap_index = PTKPulmonarySegmentLabels.R_LB;
    elseif context == PTKContext.R_PB
        colormap_index = PTKPulmonarySegmentLabels.R_PB;
    elseif context == PTKContext.L_APP
        colormap_index = PTKPulmonarySegmentLabels.L_APP;
    elseif context == PTKContext.L_APP2
        colormap_index = PTKPulmonarySegmentLabels.L_APP2;
    elseif context == PTKContext.L_AN
        colormap_index = PTKPulmonarySegmentLabels.L_AN;
    elseif context == PTKContext.L_SL
        colormap_index = PTKPulmonarySegmentLabels.L_SL;
    elseif context == PTKContext.L_IL
        colormap_index = PTKPulmonarySegmentLabels.L_IL;
    elseif context == PTKContext.L_S
        colormap_index = PTKPulmonarySegmentLabels.L_S;
    elseif context == PTKContext.L_AMB
        colormap_index = PTKPulmonarySegmentLabels.L_AMB;
    elseif context == PTKContext.L_LB
        colormap_index = PTKPulmonarySegmentLabels.L_LB;
    elseif context == PTKContext.L_PB
        colormap_index = PTKPulmonarySegmentLabels.L_PB;
    else
        reporting.Error('PTKGetSegmentROI:UnknownContext', ['The context ' char(context) ' is unknown.']);
    end
    mask.ChangeRawImage(segment_mask.RawImage == colormap_index);
    mask.CropToFitWithBorder(5);
end

