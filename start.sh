#!/bin/bash
#
# 电影院售票系统 — 一键启动脚本
# 用法: bash start.sh
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/cinema-backend"
ADMIN_DIR="$PROJECT_DIR/admin"
USER_DIR="$PROJECT_DIR/user"

PID_BACKEND=""
PID_ADMIN=""
PID_USER=""

###############################################################################
# 清理函数：Ctrl+C 时关闭所有服务
###############################################################################
cleanup() {
    echo ""
    echo -e "${YELLOW}正在关闭所有服务...${NC}"
    [ -n "$PID_BACKEND" ] && kill $PID_BACKEND 2>/dev/null
    [ -n "$PID_ADMIN"   ] && kill $PID_ADMIN   2>/dev/null
    [ -n "$PID_USER"    ] && kill $PID_USER    2>/dev/null
    wait 2>/dev/null
    echo -e "${GREEN}所有服务已关闭${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

###############################################################################
# 环境检查
###############################################################################
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   电影院售票系统 — 一键启动${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

check_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${RED}[错误] 未找到 $1，请先安装${NC}"
        exit 1
    fi
}

echo -e "${GREEN}[1/5] 检查环境...${NC}"
check_cmd java
check_cmd mvn
check_cmd node
check_cmd npm
echo "  Java   : $(java -version 2>&1 | head -1)"
echo "  Maven  : $(mvn --version 2>&1 | head -1)"
echo "  Node   : $(node --version)"
echo "  npm    : $(npm --version)"

###############################################################################
# 数据库检查
###############################################################################
echo ""
echo -e "${GREEN}[2/5] 检查数据库...${NC}"
if command -v mysql &>/dev/null; then
    if mysql -u root -p675785214 -e "SELECT 1" &>/dev/null 2>&1; then
        echo "  MySQL 连接正常"
    else
        echo -e "${YELLOW}  MySQL 连接失败，尝试继续...${NC}"
    fi
else
    echo -e "${YELLOW}  未找到 mysql 命令，跳过数据库检查${NC}"
fi

###############################################################################
# 后端编译启动
###############################################################################
echo ""
echo -e "${GREEN}[3/5] 编译并启动后端 (端口 9231)...${NC}"
cd "$BACKEND_DIR"

echo "  正在编译..."
mvn clean compile -DskipTests -q 2>&1
echo "  编译完成，正在启动 Spring Boot..."

mvn spring-boot:run -q &
PID_BACKEND=$!

# 等待后端就绪
echo "  等待后端就绪..."
for i in {1..30}; do
    if curl -s http://localhost:9231/captcha > /dev/null 2>&1; then
        echo -e "  ${GREEN}后端启动成功 ✓${NC}"
        break
    fi
    sleep 2
done

###############################################################################
# 用户前端
###############################################################################
echo ""
echo -e "${GREEN}[4/5] 启动用户前端 (端口 9232)...${NC}"
cd "$USER_DIR"
npm run serve &
PID_USER=$!
sleep 3
echo "  用户前端: http://localhost:9232"

###############################################################################
# 管理后台
###############################################################################
echo ""
echo -e "${GREEN}[5/5] 启动管理后台 (端口 9233)...${NC}"
cd "$ADMIN_DIR"
npm run serve &
PID_ADMIN=$!
sleep 3
echo "  管理后台: http://localhost:9233"

###############################################################################
# 启动完成
###############################################################################
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   全部启动完成！${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "  ${GREEN}后端 API   ${NC}: http://localhost:9231"
echo -e "  ${GREEN}用户前台   ${NC}: http://localhost:9232"
echo -e "  ${GREEN}管理后台   ${NC}: http://localhost:9233"
echo ""
echo -e "  ${YELLOW}按 Ctrl+C 停止所有服务${NC}"
echo ""

# 等待所有后台进程
wait
