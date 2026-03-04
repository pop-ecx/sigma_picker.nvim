local sigma = require("sigma_picker.targets")

describe("sigma_picker", function()
  it("should correctly parse sigma targets from table output", function()
    local mock_output = [[
+------------+--------------------------+
| Identifier | Target Query Language    |
+------------+--------------------------+
| lucene     | Elasticsearch Lucene     |
| eql        | Elasticsearch EQL        |
+------------+--------------------------+]]

    local old_system = vim.fn.system
    vim.fn.system = function(_) return mock_output end

    local results = sigma.list_targets()
    assert.are.same({"lucene", "eql"}, results)

    vim.fn.system = old_system
  end)
  it("should return empty table on empty output", function()
    vim.fn.system = function(_) return "" end
    local old_system = vim.fn.system

    local results = sigma.list_targets()

    assert.are.same({}, results)
    vim.fn.system = old_system
  end)
end)
