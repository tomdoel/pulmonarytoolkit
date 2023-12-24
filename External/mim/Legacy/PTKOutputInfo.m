classdef PTKOutputInfo < MimOutputInfo
    % Legacy support class for backwards compatibility. Replaced by MimOutputInfo
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    methods
        function obj = PTKOutputInfo(varargin)
            obj = obj@MimOutputInfo(varargin{:});
        end
    end
end
