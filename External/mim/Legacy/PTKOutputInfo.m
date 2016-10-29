classdef PTKOutputInfo < MimOutputInfo
    % PTKOutputInfo. Legacy support class for backwards compatibility. Replaced by MimOutputInfo
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    methods
        function obj = PTKOutputInfo(varargin)
            obj = obj@MimOutputInfo(varargin{:});
        end
    end
end
