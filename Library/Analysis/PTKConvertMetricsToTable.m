function results_table = PTKConvertMetricsToTable(results, patient_name, patient_id, reporting, varargin)
    % PTKConvertMetricsToTable. Calls MimConvertMetricsToTable with a default mapping of PTK context names
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
   
    results_table = MimConvertMetricsToTable(results, patient_name, patient_id, reporting, @PTKGetUserVisibleNameForContext, varargin{:});
end