#!/bin/bash

# =============================================================================
#  Claude Code Router - macOS 一键安装配置脚本
#  GitHub: https://github.com/w13263569508-crypto/claude-code-router
# =============================================================================

set -e

# ---------------------------------------------------------------------------
# 颜色
# ---------------------------------------------------------------------------
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
BOLDCYAN="\033[1m\033[36m"
BOLDGREEN="\033[1m\033[32m"
DIM="\033[2m"

# ---------------------------------------------------------------------------
# 工具函数
# ---------------------------------------------------------------------------
info()    { echo -e "${CYAN}  ℹ  $*${RESET}"; }
success() { echo -e "${BOLDGREEN}  ✓  $*${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠  $*${RESET}"; }
error()   { echo -e "${RED}  ✗  $*${RESET}"; exit 1; }
title()   { echo -e "\n${BOLDCYAN}══════════════════════════════════════════════${RESET}"; \
            echo -e "${BOLDCYAN}  $*${RESET}"; \
            echo -e "${BOLDCYAN}══════════════════════════════════════════════${RESET}\n"; }
prompt()  { echo -e "${YELLOW}  → $*${RESET}"; }

# ---------------------------------------------------------------------------
# 欢迎
# ---------------------------------------------------------------------------
clear
echo -e "${BOLDCYAN}"
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║      Claude Code Router 一键安装脚本      ║"
echo "  ║      by wangjibin                         ║"
echo "  ╚═══════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "${DIM}  本脚本将自动完成以下步骤：${RESET}"
echo -e "${DIM}  1. 检测并安装运行环境（Node.js）${RESET}"
echo -e "${DIM}  2. 安装 Claude Code${RESET}"
echo -e "${DIM}  3. 安装 Claude Code Router${RESET}"
echo -e "${DIM}  4. 交互式配置模型与路由规则${RESET}"
echo -e "${DIM}  5. 启动服务并验证${RESET}"
echo ""

# ---------------------------------------------------------------------------
# 步骤 1：检测环境
# ---------------------------------------------------------------------------
title "步骤 1/5  检测运行环境"

# 检测 macOS
if [[ "$(uname)" != "Darwin" ]]; then
  error "本脚本仅支持 macOS，当前系统：$(uname)"
fi
success "操作系统：macOS $(sw_vers -productVersion)"

# 检测 Node.js
if ! command -v node &>/dev/null; then
  warn "未检测到 Node.js，尝试通过 Homebrew 安装..."
  if ! command -v brew &>/dev/null; then
    error "未找到 Homebrew。请先安装 Homebrew：https://brew.sh，或手动安装 Node.js >= 20"
  fi
  brew install node
fi

NODE_VER=$(node --version | sed 's/v//')
NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
if [[ "$NODE_MAJOR" -lt 20 ]]; then
  error "Node.js 版本需要 >= 20，当前版本：v${NODE_VER}。请升级后重试。"
fi
success "Node.js v${NODE_VER}"

# 检测 npm
if ! command -v npm &>/dev/null; then
  error "未找到 npm，请重新安装 Node.js"
fi
success "npm $(npm --version)"

# ---------------------------------------------------------------------------
# 步骤 2：安装 Claude Code
# ---------------------------------------------------------------------------
title "步骤 2/5  安装 Claude Code"

if command -v claude &>/dev/null; then
  success "Claude Code 已安装（$(claude --version 2>/dev/null || echo '已存在')），跳过"
else
  info "正在安装 @anthropic-ai/claude-code ..."
  npm install -g @anthropic-ai/claude-code
  success "Claude Code 安装完成"
fi

# ---------------------------------------------------------------------------
# 步骤 3：安装 Claude Code Router
# ---------------------------------------------------------------------------
title "步骤 3/5  安装 Claude Code Router"

if command -v ccr &>/dev/null; then
  success "Claude Code Router 已安装，跳过"
  info "如需更新，请运行：npm install -g @wangjibins/claude-code-router"
else
  info "正在安装 @wangjibins/claude-code-router ..."
  npm install -g @wangjibins/claude-code-router
  success "Claude Code Router 安装完成"
fi
success "ccr 命令就绪：$(which ccr)"

# ---------------------------------------------------------------------------
# 步骤 4：交互式配置
# ---------------------------------------------------------------------------
title "步骤 4/5  配置模型"

CONFIG_DIR="$HOME/.claude-code-router"
CONFIG_FILE="$CONFIG_DIR/config.json"
mkdir -p "$CONFIG_DIR"

# 固定的 API 地址和 Transformer
API_BASE_URL="https://wanqing-api.corp.kuaishou.com/api/gateway/v1/endpoints/chat/completions"

echo -e "${DIM}  API 地址已固定为内部网关，Transformer 使用 openai 协议。${RESET}\n"

# ---- 4.1 Provider 名称 ----
prompt "请输入 Provider 名称（默认: wanqing，直接回车使用默认值）："
read -r PROVIDER_NAME
PROVIDER_NAME="${PROVIDER_NAME:-wanqing}"
success "Provider 名称：$PROVIDER_NAME"

# ---- 4.2 API Key ----
echo ""
prompt "请输入 API Key（必填）："
while true; do
  read -rs API_KEY
  echo ""
  if [[ -n "$API_KEY" ]]; then
    break
  fi
  warn "API Key 不能为空，请重新输入："
done
success "API Key 已设置（已隐藏）"

# ---- 4.3 配置模型列表 ----
echo ""
echo -e "${BOLDCYAN}  配置模型列表${RESET}"
echo -e "${DIM}  每次输入一个模型 ID，输入完成后直接回车（空行）结束。${RESET}"
echo -e "${DIM}  示例：ep-dknqnj-1774531541496556905${RESET}\n"

MODELS_JSON="["
ALIAS_JSON="["
MODEL_DISPLAY=()
MODEL_COUNT=0

while true; do
  prompt "模型 ID（第 $((MODEL_COUNT+1)) 个，留空结束）："
  read -r MODEL_ID
  
  if [[ -z "$MODEL_ID" ]]; then
    if [[ $MODEL_COUNT -eq 0 ]]; then
      warn "至少需要添加一个模型！"
      continue
    fi
    break
  fi

  # 询问别名
  prompt "  为 \"$MODEL_ID\" 设置别名（可选，如 opus4.6，留空跳过）："
  read -r MODEL_ALIAS

  if [[ $MODEL_COUNT -gt 0 ]]; then
    MODELS_JSON+=","
  fi
  MODELS_JSON+="\"$MODEL_ID\""

  if [[ -n "$MODEL_ALIAS" ]]; then
    if [[ "$ALIAS_JSON" != "[" ]]; then
      ALIAS_JSON+=","
    fi
    ALIAS_JSON+="{\"modelId\":\"$MODEL_ID\",\"alias\":\"$MODEL_ALIAS\"}"
    MODEL_DISPLAY+=("$MODEL_ALIAS ($MODEL_ID)")
    success "  已添加：$MODEL_ALIAS → $MODEL_ID"
  else
    MODEL_DISPLAY+=("$MODEL_ID")
    success "  已添加：$MODEL_ID"
  fi

  MODEL_COUNT=$((MODEL_COUNT + 1))
done

MODELS_JSON+="]"
ALIAS_JSON+="]"

echo ""
echo -e "${BOLDCYAN}  已配置 ${MODEL_COUNT} 个模型：${RESET}"
for m in "${MODEL_DISPLAY[@]}"; do
  echo -e "  ${DIM}• $m${RESET}"
done

# ---- 4.4 选择路由模型 ----
echo ""
echo -e "${BOLDCYAN}  配置路由规则${RESET}"
echo -e "${DIM}  请为以下三个路由场景选择对应的模型：${RESET}\n"

# 构建选择菜单
echo -e "  ${DIM}可用模型列表（输入序号选择）：${RESET}"
for i in "${!MODEL_DISPLAY[@]}"; do
  echo -e "    ${CYAN}[$((i+1))]${RESET} ${MODEL_DISPLAY[$i]}"
done
echo ""

# 获取对应的 provider,model 或 provider,alias 字符串
get_router_value() {
  local IDX=$((${1:-1} - 1))
  if [[ $IDX -lt 0 ]] || [[ $IDX -ge ${#MODEL_DISPLAY[@]} ]]; then
    IDX=0
  fi
  
  # 判断是否有别名
  local DISPLAY="${MODEL_DISPLAY[$IDX]}"
  if [[ "$DISPLAY" == *"("* ]]; then
    # 有别名，格式：alias (modelId)
    local ALIAS_PART="${DISPLAY%% (*}"
    echo "${PROVIDER_NAME},${ALIAS_PART}"
  else
    echo "${PROVIDER_NAME},${DISPLAY}"
  fi
}

select_model_for_route() {
  local ROUTE_NAME="$1"
  local DEFAULT_IDX="$2"
  
  prompt "${ROUTE_NAME}（输入序号，默认 ${DEFAULT_IDX}）："
  read -r IDX
  IDX="${IDX:-$DEFAULT_IDX}"
  
  # 数字验证
  if ! [[ "$IDX" =~ ^[0-9]+$ ]] || [[ $IDX -lt 1 ]] || [[ $IDX -gt $MODEL_COUNT ]]; then
    warn "无效序号，使用默认值 ${DEFAULT_IDX}"
    IDX="$DEFAULT_IDX"
  fi
  
  get_router_value "$IDX"
}

ROUTER_DEFAULT=$(select_model_for_route "Default（默认模型）" "1")
success "Default: $ROUTER_DEFAULT"

ROUTER_LONG_CONTEXT=$(select_model_for_route "LongContext（长上下文模型，> 60K tokens）" "1")
success "LongContext: $ROUTER_LONG_CONTEXT"

ROUTER_WEB_SEARCH=$(select_model_for_route "WebSearch（联网搜索模型）" "1")
success "WebSearch: $ROUTER_WEB_SEARCH"

# ---- 4.5 生成 config.json ----
echo ""
info "正在生成配置文件..."

# 构建 alias 字段
if [[ "$ALIAS_JSON" == "[]" ]]; then
  ALIAS_FIELD=""
else
  ALIAS_FIELD="
      \"alias\": $ALIAS_JSON,"
fi

cat > "$CONFIG_FILE" <<EOF
{
  "LOG": true,
  "LOG_LEVEL": "debug",
  "API_TIMEOUT_MS": 600000,
  "Providers": [
    {
      "name": "$PROVIDER_NAME",
      "api_base_url": "$API_BASE_URL",
      "api_key": "$API_KEY",
      "models": $MODELS_JSON,$ALIAS_FIELD
      "transformer": {
        "use": ["openai"]
      }
    }
  ],
  "Router": {
    "default": "$ROUTER_DEFAULT",
    "longContext": "$ROUTER_LONG_CONTEXT",
    "webSearch": "$ROUTER_WEB_SEARCH"
  }
}
EOF

success "配置文件已写入：$CONFIG_FILE"

# ---------------------------------------------------------------------------
# 步骤 5：启动服务
# ---------------------------------------------------------------------------
title "步骤 5/5  启动服务"

# 如果已在运行，先重启
if ccr status 2>/dev/null | grep -q "Running"; then
  info "检测到服务已在运行，正在重启以加载新配置..."
  ccr restart
else
  info "启动 Claude Code Router 服务..."
  ccr start
fi

sleep 2

echo ""
ccr status

# ---------------------------------------------------------------------------
# 完成
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLDGREEN}══════════════════════════════════════════════${RESET}"
echo -e "${BOLDGREEN}  🎉  安装配置完成！${RESET}"
echo -e "${BOLDGREEN}══════════════════════════════════════════════${RESET}"
echo ""
echo -e "${BOLD}使用方法：${RESET}"
echo -e "  ${CYAN}ccr code${RESET}           启动 Claude Code（通过路由器）"
echo -e "  ${CYAN}ccr ui${RESET}             打开 Web UI 配置界面"
echo -e "  ${CYAN}ccr model${RESET}          交互式切换模型"
echo -e "  ${CYAN}ccr status${RESET}         查看服务状态"
echo -e "  ${CYAN}ccr restart${RESET}        重启服务"
echo ""
echo -e "${BOLD}在 Claude Code 中切换模型：${RESET}"
echo -e "  ${DIM}/model ${PROVIDER_NAME},<别名或模型ID>${RESET}"
for m in "${MODEL_DISPLAY[@]}"; do
  if [[ "$m" == *"("* ]]; then
    ALIAS_PART="${m%% (*}"
    echo -e "  ${DIM}示例：/model ${PROVIDER_NAME},${ALIAS_PART}${RESET}"
  fi
done
echo ""
echo -e "${DIM}  配置文件位置：$CONFIG_FILE${RESET}"
echo -e "${DIM}  如需修改配置，运行：ccr ui${RESET}"
echo ""
