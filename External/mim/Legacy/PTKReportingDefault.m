classdef PTKReportingDefault < CoreReportingDefault
    % PTKReportingDefault. Legacy support class. Replaced by CoreReportingDefault.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    methods
        function obj = PTKReportingDefault(varargin)
            obj = obj@CoreReportingDefault(varargin{:});
        end
    end
end

