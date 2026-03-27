---
name: ccr-model
description: 切换 Claude Code Router 的模型。当用户想查看 CCR 可用模型列表、切换当前模型时使用。
argumenthint: "[provider,modelAlias]"
allowed-tools: Bash
---

请按以下步骤帮我切换 Claude Code Router 的模型：

## 第一步：读取模型配置

使用 Bash 工具运行以下命令获取配置：

```bash
cat "$HOME/.claude-code-router/config.json"
```

## 第二步：展示模型列表

解析上面的 JSON 配置，提取所有 Providers 中的模型。对于每个模型：
- 如果有 `alias` 字段，优先展示别名（格式：`provider,alias`）
- 如果没有别名，展示原始 model ID（格式：`provider,modelId`）

将所有可用模型以编号列表的形式展示给用户，例如：
```
可用模型列表：
1. claude,opus4.6        (ep-dknqnj-xxxx)  ← 当前 default
2. claude,sonnet4.6      (ep-h67tra-xxxx)
3. gemini,gemini2.5pro   (ep-ghu5qx-xxxx)
4. gemini,gemini2.5flash (ep-iwcksm-xxxx)
```

同时标注当前 Router.default 使用的是哪个模型。

## 第三步：处理参数或等待选择

如果用户传入了参数（$ARGUMENTS），直接使用该参数作为目标模型，跳过选择步骤。

否则，询问用户想切换到哪个模型（输入序号或模型名称）。

## 第四步：执行切换

⚠️ **重要**：`/model` 是 Claude Code 的内置 slash command，**绝对不能通过 Bash 执行**（执行会报 "no such file or directory" 错误）。

正确做法：在你的回复中**直接输出**以下格式的 slash command，Claude Code 会自动识别并执行：

```
/model claude,opus4.6
```

例如用户选择切换到 `claude,sonnet4.6`，你的回复中直接写：

/model claude,sonnet4.6

Claude Code 会自动拦截并执行这个 slash command 完成模型切换。

切换完成后，告知用户已切换到的模型名称。
