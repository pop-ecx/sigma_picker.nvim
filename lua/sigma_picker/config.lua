local M = {}

-- Default configuration
-- kibana-ndjson has issues...working on it
M.default_config = {
    sigma_rules = {
        kibana = { "ecs-auditbeat-modules-enabled", "ecs-auditd","ecs-cloudtrail","ecs-dns","ecs-filebeat","ecs-okta","ecs-proxy","ecs-suricata","ecs-zeek-corelight","ecs-zeek-elastic-beats-implementation","elk-defaultindex","elk-defaultindex-filebeat","elk-defaultindex-logstash","elk-linux","elk-windows","elk-winlogbeat","elk-winlogbeat-sp","filebeat-defaultindex","helk","logstash-defaultindex","logstash-linux","logstash-windows","logstash-zeek-default-json","powershell","sysmon","windows-audit","windows-services","winlogbeat","winlogbeat-modules-enabled", "winlogbeat-old" },
        devo = { "devo-network", "devo-web","devo-windows", "elk-defaultindex","elk-defaultindex-filebeat","elk-defaultindex-logstash","elk-linux","elk-windows","elk-winlogbeat","elk-winlogbeat-sp","powershell","sysmon","windows-audit","windows-services" },
        splunk = { "elk-defaultindex", "elk-defaultindex-filebeat", "elk-defaultindex-logstash", "elk-linux","elk-windows", "elk-winlogbeat", "elk-winlogbeat-sp", "powershell", "splunk-windows", "splunk-windows-index", "splunk-zeek", "sysmon", "windows-audit", "windows-services" },
        elastalert = { "ecs-auditbeat-modules-enabled", "ecs-auditd","ecs-cloudtrail","ecs-dns","ecs-filebeat","ecs-okta","ecs-proxy", "ecs-suricata", "ecs-zeek-corelight","ecs-zeek-elastic-beats-implementation","elk-defaultindex","elk-defaultindex-filebeat","elk-defaultindex-logstash","elk-linux","elk-windows","elk-winlogbeat","elk-winlogbeat-sp","filebeat-defaultindex","helk","logstash-defaultindex","logstash-linux","logstash-windows","logstash-zeek-default-json","powershell","sysmon","windows-audit","windows-services","winlogbeat","winlogbeat-modules-enabled", "winlogbeat-old" },
        arcsight = { "arcsight","arcsight-zeek", "elk-defaultindex", "elk-defaultindex-logstash", "elk-defaultindex-filebeat", "elk-linux", "elk-windows", "elk-winlogbeat", "elk-winlogbeat-sp", "powershell", "sysmon", "windows-audit", "windows-services" },
        athena = { "athena", "elk-defaultindex", "elk-defaultindex-logstash", "elk-defaultindex-filebeat", "elk-linux", "elk-windows", "elk-winlogbeat", "elk-winlogbeat-sp", "powershell", "sysmon", "windows-audit", "windows-services" },
    },
    backend_command = function(backend, config, file)
        return "sigmac -t " .. backend .. " -c " .. config .. " " .. file
    end,
}

-- User-provided configuration
M.user_config = vim.tbl_deep_extend("force", {}, M.default_config)

-- Setup function for user configuration
M.setup = function(config)
    M.user_config = vim.tbl_deep_extend("force", M.user_config, config or {})
end

return M

