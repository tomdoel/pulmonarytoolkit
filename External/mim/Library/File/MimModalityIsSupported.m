function is_supported = MimModalityIsSupported(modality, reporting)
    % Return true if MIM supports this modality
    %
    % Syntax:
    %     is_supported = MimModalityIsSupported(modality, reporting);
    %
    % Parameters:
    %     modality (char): DICOM modality string
    %     reporting (Optional[CoreReportingInterface]): object
    %         for reporting progress and warnings
    %
    % Returns:
    %     is_supported: true if MIM supports this modality
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    supported_modalities = {'CT', 'MR', 'US'};
    is_supported = ismember(modality, supported_modalities);
end
