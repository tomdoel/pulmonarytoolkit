classdef PTKReportingWarningsCache < handle
    %PTKReportingWarningsCache Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        PendingMessages
        PendingWarnings
        ReportingWithCache
    end
    
    methods
        function obj = PTKReportingWarningsCache(reporting_with_cache)
            obj.ReportingWithCache = reporting_with_cache;
            obj.PendingMessages = containers.Map;
            obj.PendingWarnings = containers.Map;
        end

        function AddPendingWarning(obj, warning_id, warning_text, supplementary_info)
            if obj.PendingWarnings.isKey(warning_id)
                warning = obj.PendingWarnings(warning_id);
                warning.Count = warning.Count + 1;
            else
                warning = [];
                warning.ID = warning_id;
                warning.Text = warning_text;
                warning.SupplementaryInfo = supplementary_info;
                warning.Count = 1;
                warning.Text = warning_text;
            end
            obj.PendingWarnings(warning_id) = warning;
        end
        
        function AddPendingMessages(obj, message_id, message_text)
            if obj.PendingWarnings.isKey(message_id)
                message = obj.Warnings(message_id);
                message.Count = warning_object.Count + 1;
                message.Text = message_text;
            else
                message = [];
                message.ID = message_id;
                message.Text = message_text;
                message.Count = 1;
            end
            obj.PendingMessages(message_id) = message;
        end

        function ShowAndClear(obj)
            for warning = obj.PendingWarnings.values
                warning_message = warning{1}.Text;
                if warning{1}.Count > 1
                    warning_message = ['(repeated ×' int2str(warning{1}.Count) ') ' warning_message];
                end
                obj.ReportingWithCache.ShowCachedWarning(warning{1}.ID, warning_message, warning{1}.SupplementaryInfo);
            end
            for message = obj.PendingMessages.values
                message_text = message{1}.Text;
                if message{1}.Count > 1
                    message_text = ['(repeated ×' int2str(message{1}.Count) ') ' message_text];
                end
                obj.ReportingWithCache.ShowCachedMessage(message{1}.ID, message_text);
            end
            obj.PendingWarnings = containers.Map;
            obj.PendingMessages = containers.Map;
        end
    end
end

