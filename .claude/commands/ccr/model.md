# CCR 模型切换

请按以下步骤帮我切换 Claude Code Router 的模型：

## 第一步：读取模型配置

运行以下命令获取当前可用模型列表：

```bash
cat ~/.claude-code-router/config.json
```

## 第二步：展示模型列表

解析 JSON 配置，提取所有 Providers 中的模型。对于每个模型：
- 如果有 `alias` 字段，优先展示别名（格式：`provider,alias`）
- 如果没有别名，展示原始 model ID（格式：`provider,modelId`）

将所有可用模型以编号列表的形式展示给我，例如：
```
可用模型列表：
1. claude,opus4.6      (ep-dknqnj-xxxx)
2. claude,sonnet4.6    (ep-h67tra-xxxx)
3. gemini,gemini2.5pro (ep-ghu5qx-xxxx)
4. gemini,gemini2.5flash (ep-iwcksm-xxxx)
```

同时标注当前 Router.default 使用的模型。

## 第三步：等待用户选择

询问我想切换到哪个模型（输入序号或模型名称）。

## 第四步：执行切换

用户选择后，使用 `/model` 命令切换到对应模型，格式为：

```
/model <provider>,<alias或modelId>
```

例如：`/model claude,opus4.6`

切换完成后，告知我当前已切换到的模型名称。

---

**注意**：如果用户提供了参数（$ARGUMENTS），直接将其作为目标模型名执行切换，跳过选择步骤：
`/model $ARGUMENTS`
