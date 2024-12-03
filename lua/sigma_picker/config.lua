local M = {}

-- Default configuration
M.default_config = {
    sigma_rules = {
        elasticsearch = { "config1.yml", "config2.yml" },
        kibana = { "ecs-auditbeat-modules-enabled", "ecs-auditd", "ecs-cloudtrail", "ecs-dns" },
        splunk = { "elk-defaultindex", "elk-defaultindex-filebeat", "elk-defaultindex-logstash" },
        crowdstrike = { "crowdstrike", "elk-defaultindex", "elk-defaultindex-filebeat" },
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

