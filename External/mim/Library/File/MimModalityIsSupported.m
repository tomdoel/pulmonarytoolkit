function is_supported = MimModalityIsSupported(modality, reporting)
    % MimModalityIsSupported. Returns true if MIM supports this modality
    %
    %     Syntax
    %     ------
    %
    %         is_supportred = MimModalityIsSupported(modality, reporting)
    %
    %             modality        DICOM modality string
    %             reporting (optional) - an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        

    supported_modalities = {'CT', 'MR', 'US'};
    is_supported = ismember(modality, supported_modalities);
end