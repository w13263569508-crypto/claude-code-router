---
name: ccr-model
description: 切换 Claude Code Router 的模型。当用户想查看 CCR 可用模型列表、切换当前模型时使用。
argumenthint: "[provider,modelAlias] 或留空显示列表"
allowed-tools: Bash
---

请按以下步骤帮我查看和切换 Claude Code Router 的可用模型。

## 第一步：读取当前配置

```bash
echo "=== CCR 配置 ===" && cat "$HOME/.claude-code-router/config.json" && echo "" && echo "=== 当前会话模型 ===" && cat "$HOME/.claude/settings.json"
```

## 第二步：解析并展示模型列表

从 CCR 的 `config.json` 中解析 `Providers` 数组，按以下规则展示：
- 优先展示 `alias` 别名（用户友好名称），格式：`provider,alias`
- 没有别名的模型展示原始 model ID，格式：`provider,modelId`
- 对照 `~/.claude/settings.json` 的 `model` 字段，标注当前正在使用的模型

展示格式示例：
```
📋 CCR 可用模型列表
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. claude,opus4.6        (ep-dknqnj-xxxx)
  2. claude,sonnet4.6      (ep-h67tra-xxxx)  ← 当前使用
  3. gemini,gemini2.5pro   (gemini-2.5-pro-preview)
  4. gemini,gemini2.5flash (gemini-2.5-flash-preview)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
当前模型: claude,sonnet4.6
```

## 第三步：处理参数或等待选择

**如果用户传入了参数（`$ARGUMENTS` 非空）**：
- 直接将 `$ARGUMENTS` 作为目标模型，跳到第四步。

**如果没有参数**：
- 询问用户："请输入序号或模型名称来切换，或输入 'q' 取消："
- 支持输入序号（如 `2`）或完整模型名（如 `claude,sonnet4.6`）

## 第四步：告知用户如何切换

**重要原理**：
- `/model` 命令会直接更新 Claude Code 进程的内存状态，**当前会话立即生效**
- 通过 Bash 写文件的方式只能影响下一次会话，无法更新进程内存

因此，直接在对话框输入以下命令来完成切换（**当前对话立即生效，上下文完整保留**）：

```
/model <用户选择的模型>
```

例如用户选择切换到 `claude,opus4.6`，告知用户：

> 请直接在输入框中执行：
> ```
> /model claude,opus4.6
> ```
> 这会立即切换当前会话的模型，上下文完整保留，无需重启。

## 第五步：补充说明

向用户说明：
1. 🔄 `/model` 命令会更新进程内存，**当前对话后续消息立即使用新模型**
2. 💾 同时自动写入 `~/.claude/settings.json`，下次启动 Claude Code 默认使用该模型
3. 🔧 CCR 路由器会自动将 `provider,alias` 解析为真实的模型 ID 进行转发，无需关心底层 endpoint
