function mask = PTKGetInteriorLungRegion(lung_roi, reporting)
    % PTKGetInteriorLungRegion. Finds a mask for a region of interest from a chest CT image which
    %     contains the lungs and airways
    %
    %     Inputs
    %     ------
    %
    %     lung_image - the full original lung volume stored as a PTKImage.
    %
    %     reporting (optional) - an object implementing the CoreReporting
    %         interface for reporting progress and warnings
    %
    %
    %     Outputs
    %     -------
    %
    %     lung_image - a PTKImage containing the mask of the relevant region
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    
    if ~isa(lung_roi, 'PTKImage')
        reporting.Error('PTKGetLungROIForCT:InputImageNotPTKImage', 'Requires a PTKImage as input');
    end

    if nargin < 2
        reporting = CoreReportingDefault;
    end
    
    reporting.ShowProgress('Applying threshold');
    
    reporting.ShowProgress('Finding region of interest');
    mask = PTKSegmentLungsWithoutClosing(lung_roi, false, false, true, reporting);
    mask.ResizeToMatch(lung_roi);
    
    reporting.CompleteProgress;
end
