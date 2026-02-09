#!/bin/bash

# ============================================================================
# logcat日志合并脚本
# 功能：遍历指定文件夹中的logcat轮转日志文件，按时间顺序合并成一个完整文件
# 使用方法：./merge_logcat.sh <文件夹路径>
# 输出：在指定文件夹中生成 logcat_all.log 文件
# 兼容性：支持Git Bash (Windows)、Linux、macOS
# ============================================================================

# 设置脚本在遇到错误时退出（注释掉，避免某些非关键命令失败导致脚本退出）
# set -e

# 颜色定义（用于输出日志）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志输出函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查参数
if [ $# -eq 0 ]; then
    log_error "请提供文件夹路径作为参数"
    echo "使用方法: $0 <文件夹路径>"
    exit 1
fi

# 获取输入的文件夹路径
TARGET_DIR="$1"

# 检查文件夹是否存在
if [ ! -d "$TARGET_DIR" ]; then
    log_error "文件夹不存在: $TARGET_DIR"
    exit 1
fi

log_info "开始处理文件夹: $TARGET_DIR"

# 切换到目标文件夹
cd "$TARGET_DIR" || {
    log_error "无法切换到文件夹: $TARGET_DIR"
    exit 1
}

# 输出文件路径
OUTPUT_FILE="logcat_all.log"

# 检查输出文件是否已存在，如果存在则备份
if [ -f "$OUTPUT_FILE" ]; then
    BACKUP_FILE="${OUTPUT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    log_warning "输出文件已存在，备份为: $BACKUP_FILE"
    mv "$OUTPUT_FILE" "$BACKUP_FILE"
fi

log_info "正在查找logcat日志文件..."

# 创建临时文件列表，用于存储找到的logcat文件及其排序键
TEMP_FILE_LIST=$(mktemp 2>/dev/null || echo "/tmp/merge_logcat_$$.tmp")
trap "rm -f $TEMP_FILE_LIST" EXIT

file_count=0

# 使用更可靠的方法查找文件
# 兼容Git Bash：直接使用for循环遍历，避免数组兼容性问题
log_info "正在扫描文件..."

# 启用nullglob，这样通配符未匹配时不会报错
shopt -s nullglob 2>/dev/null || true

# 直接收集文件到临时文件列表（避免数组兼容性问题）
file_list=""

# 检查logcat主文件
if [ -f "logcat" ] && [ "logcat" != "$OUTPUT_FILE" ]; then
    file_list="logcat"
    log_info "发现文件: logcat"
fi

# 添加所有logcat.*文件
for f in logcat.*; do
    if [ -f "$f" ] && [ "$f" != "$OUTPUT_FILE" ] && [[ "$f" != "${OUTPUT_FILE}.backup."* ]]; then
        if [ -z "$file_list" ]; then
            file_list="$f"
        else
            file_list="$file_list $f"
        fi
        log_info "发现文件: $f"
    fi
done

# 恢复nullglob设置
shopt -u nullglob 2>/dev/null || true

# 检查是否找到文件
if [ -z "$file_list" ]; then
    log_error "未找到任何logcat日志文件"
    log_info "当前目录: $(pwd)"
    log_info "目录内容: $(ls -la | head -20)"
    exit 1
fi

# 函数：从logcat日志行中提取时间戳并转换为可排序的格式
# 输入格式：02-09 21:49:57.662358
# 输出格式：MMDDHHMMSS.microseconds（用于排序）
extract_timestamp() {
    local line="$1"
    
    if [ -z "$line" ]; then
        echo "0000000000000000000"
        return 1
    fi
    
    # 提取前19个字符：MM-DD HH:MM:SS.microseconds
    local timestamp=$(echo "$line" | cut -c1-19 2>/dev/null)
    
    if [ -z "$timestamp" ] || [ ${#timestamp} -lt 19 ]; then
        echo "0000000000000000000"
        return 1
    fi
    
    # 解析时间戳：02-09 21:49:57.662358
    # 格式：MM-DD HH:MM:SS.microseconds
    # 使用awk或cut来解析各个部分
    local month=$(echo "$timestamp" | cut -c1-2)
    local day=$(echo "$timestamp" | cut -c4-5)
    local hour=$(echo "$timestamp" | cut -c7-8)
    local minute=$(echo "$timestamp" | cut -c10-11)
    local second_micro=$(echo "$timestamp" | cut -c13-19)
    
    # 验证数字有效性
    if ! [[ "$month" =~ ^[0-9]+$ ]] || ! [[ "$day" =~ ^[0-9]+$ ]] || \
       ! [[ "$hour" =~ ^[0-9]+$ ]] || ! [[ "$minute" =~ ^[0-9]+$ ]]; then
        echo "0000000000000000000"
        return 1
    fi
    
    # 组合为可排序的格式：MMDDHHMMSS.microseconds
    # 例如：02-09 21:49:57.662358 -> 0209214957.662358
    # 使用字符串拼接避免printf的八进制解析问题
    # 使用10#前缀强制按十进制解析，避免08、09等被当作八进制
    month_num=$((10#$month))
    day_num=$((10#$day))
    hour_num=$((10#$hour))
    minute_num=$((10#$minute))
    printf "%02d%02d%02d%02d%s" "$month_num" "$day_num" "$hour_num" "$minute_num" "$second_micro"
}

# 遍历找到的文件，读取第一行时间戳进行排序
for file in $file_list; do
    # 再次确认文件存在且不是输出文件
    if [ -f "$file" ] && [ "$file" != "$OUTPUT_FILE" ]; then
        # 读取文件的第一行（兼容不同系统）
        first_line=""
        if command -v head >/dev/null 2>&1; then
            first_line=$(head -n 1 "$file" 2>/dev/null)
        elif command -v sed >/dev/null 2>&1; then
            first_line=$(sed -n '1p' "$file" 2>/dev/null)
        elif command -v awk >/dev/null 2>&1; then
            first_line=$(awk 'NR==1' "$file" 2>/dev/null)
        else
            # 最后备选：使用read读取第一行
            first_line=$(read -r line < "$file" && echo "$line" 2>/dev/null || echo "")
        fi
        
        # 提取时间戳
        sort_key=""
        if [ -n "$first_line" ]; then
            sort_key=$(extract_timestamp "$first_line")
            # 显示原始时间戳
            timestamp_str=$(echo "$first_line" | cut -c1-19 2>/dev/null || echo "无法解析")
            log_info "找到文件: $file (第一行时间: $timestamp_str)"
        else
            # 如果文件为空或无法读取，使用文件名数字作为备选
            log_warning "文件 $file 为空或无法读取第一行，使用文件名排序"
            if [[ "$file" =~ logcat\.([0-9]+) ]]; then
                num="${BASH_REMATCH[1]}"
                sort_key=$(printf "0000000000000000000%06d" "$num")
            elif [ "$file" = "logcat" ]; then
                sort_key="999999999999999999999999"
            else
                sort_key="000000000000000000000000"
            fi
        fi
        
        # 将排序键和文件名写入临时文件
        echo "$sort_key|$file" >> "$TEMP_FILE_LIST"
        ((file_count++))
    fi
done

# 检查是否找到文件
if [ $file_count -eq 0 ]; then
    log_error "未找到任何logcat日志文件"
    exit 1
fi

log_info "共找到 $file_count 个logcat日志文件"

# 按第一行时间戳排序（最早的在前，使用数字排序）
log_info "正在按第一行时间戳排序文件..."
# 使用sort命令按排序键（第一列）进行数字排序
sort -n -t'|' -k1 "$TEMP_FILE_LIST" > "${TEMP_FILE_LIST}.sorted"
mv "${TEMP_FILE_LIST}.sorted" "$TEMP_FILE_LIST"

# 显示排序后的文件列表
log_info "文件排序结果（按第一行时间戳从早到晚）："
file_index=0
while IFS='|' read -r sort_key filename; do
    ((file_index++))
    # 尝试从排序键中提取时间信息用于显示
    if [ ${#sort_key} -ge 10 ]; then
        # 排序键格式：MMDDHHMMSS.microseconds
        # 使用cut命令提取各部分（更兼容）
        month=$(echo "$sort_key" | cut -c1-2)
        day=$(echo "$sort_key" | cut -c3-4)
        hour=$(echo "$sort_key" | cut -c5-6)
        minute=$(echo "$sort_key" | cut -c7-8)
        second_micro=$(echo "$sort_key" | cut -c9-)
        time_display="${month}-${day} ${hour}:${minute}:${second_micro}"
        log_info "  $file_index. $filename (时间: $time_display)"
    else
        log_info "  $file_index. $filename"
    fi
done < "$TEMP_FILE_LIST"

# 开始合并文件
log_info "开始合并日志文件到: $OUTPUT_FILE"
echo ""

total_lines=0
file_index=0

# 读取排序后的文件列表并合并
while IFS='|' read -r sort_key filename; do
    ((file_index++))
    log_info "[$file_index/$file_count] 正在处理: $filename"
    
    # 统计文件行数
    file_lines=0
    if [ -f "$filename" ]; then
        # 使用wc -l统计行数，兼容不同系统
        file_lines=$(wc -l < "$filename" 2>/dev/null | tr -d ' ' || echo "0")
        # 如果wc失败，尝试使用awk
        if [ -z "$file_lines" ] || [ "$file_lines" = "0" ]; then
            file_lines=$(awk 'END {print NR}' "$filename" 2>/dev/null || echo "0")
        fi
    fi
    
    total_lines=$((total_lines + file_lines))
    
    # 将文件内容追加到输出文件
    if [ -s "$filename" ]; then
        cat "$filename" >> "$OUTPUT_FILE"
        log_success "  ✓ 已合并 $filename (行数: $file_lines)"
    else
        log_warning "  ⚠ 文件为空，跳过: $filename"
    fi
done < "$TEMP_FILE_LIST"

# 检查输出文件是否成功创建
if [ ! -f "$OUTPUT_FILE" ]; then
    log_error "合并失败，输出文件未创建"
    exit 1
fi

# 获取输出文件大小（兼容不同系统的du命令）
output_size="未知"
if output_size_raw=$(du -h "$OUTPUT_FILE" 2>/dev/null); then
    output_size=$(echo "$output_size_raw" | cut -f1)
elif output_size_raw=$(du "$OUTPUT_FILE" 2>/dev/null); then
    # 如果-h不支持，使用字节数
    bytes=$(echo "$output_size_raw" | cut -f1)
    if [ "$bytes" -gt 1048576 ]; then
        output_size="$((bytes / 1048576))MB"
    elif [ "$bytes" -gt 1024 ]; then
        output_size="$((bytes / 1024))KB"
    else
        output_size="${bytes}B"
    fi
fi

# 获取输出文件的绝对路径
output_path=$(pwd)/$OUTPUT_FILE

echo ""
log_success "=========================================="
log_success "合并完成！"
log_success "=========================================="
log_info "输出文件: $output_path"
log_info "文件大小: $output_size"
log_info "总行数: $total_lines"
log_info "处理的文件数: $file_count"
echo ""
log_success "脚本执行完成！"
