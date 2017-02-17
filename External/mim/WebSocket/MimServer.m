classdef MimServer < handle
    
    properties (Access = public) % ToDo: make private
        WebSocketServer
        Mim
        Reporting
    end
    
    methods
        function obj = MimServer()
            obj.WebSocketServer = MimWebSocketServer(30000);
            framework_def = PTKFrameworkAppDef;
            obj.Reporting = MimReporting([], [], 'mimserver.log');
            obj.Mim = MimMain(framework_def, obj.Reporting);
        end
    end    
end
