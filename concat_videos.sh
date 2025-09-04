#!/bin/bash

# 视频无损拼接脚本 (适用于Windows GitBash环境)
# 功能: 1. 收集指定目录下所有MP4文件并按文件名升序排序
#      2. 生成ffmpeg所需的input.txt文件
#      3. 使用ffmpeg进行无损拼接，输出为final.mp4
# 使用方法: ./concat_videos.sh [输入目录路径] [--verbose]

# 初始化变量
INPUT_DIR=""
VERBOSE=0
SCRIPT_NAME=$(basename "$0")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE=""

# 日志函数
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # 始终输出到日志文件
    echo "[$timestamp] $message" >> "$LOG_FILE"
    
    # 如果开启详细模式，同时输出到控制台
    if [ $VERBOSE -eq 1 ]; then
        echo "[$timestamp] $message"
    fi
}

# 显示帮助信息
show_help() {
    echo "用法: $SCRIPT_NAME [选项] <输入目录路径>"
    echo "用于将指定目录下的所有MP4文件按文件名升序排序并使用ffmpeg无损拼接"
    echo
    echo "选项:"
    echo "  --verbose    显示详细运行日志"
    echo "  --help       显示此帮助信息"
    echo
    echo "示例:"
    echo "  $SCRIPT_NAME ./videos"
    echo "  $SCRIPT_NAME /c/Users/User/Videos --verbose"
}

# 解析命令行参数
parse_args() {
    # 处理参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --verbose)
                VERBOSE=1
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            -*)
                echo "错误: 未知选项 $1" >&2
                show_help >&2
                exit 1
                ;;
            *)
                # 检查是否已设置输入目录
                if [ -z "$INPUT_DIR" ]; then
                    INPUT_DIR="$1"
                else
                    echo "错误: 只能指定一个输入目录" >&2
                    show_help >&2
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 检查输入目录是否提供
    if [ -z "$INPUT_DIR" ]; then
        echo "错误: 必须指定输入目录" >&2
        show_help >&2
        exit 1
    fi

    # 转换为绝对路径并处理Windows路径格式
    INPUT_DIR=$(cd "$INPUT_DIR" 2>/dev/null || { echo "错误: 目录 $INPUT_DIR 不存在"; exit 1; }; pwd)
    
    # 设置日志文件路径
    LOG_FILE="$INPUT_DIR/concat_log_$TIMESTAMP.txt"
}

# 检查依赖工具
check_dependencies() {
    log "检查必要工具..."
    
    # 检查ffmpeg是否可用
    if ! command -v ffmpeg &> /dev/null; then
        log "错误: 未找到ffmpeg。请确保ffmpeg已安装并添加到系统PATH中。"
        exit 1
    fi
    
    # 检查ffmpeg版本 (可选)
    FFMPEG_VERSION=$(ffmpeg -version | head -n 1 | awk '{print $3}' | cut -d '-' -f 1)
    log "找到ffmpeg版本: $FFMPEG_VERSION"
}

# 收集并排序MP4文件
collect_mp4_files() {
    log "开始收集MP4文件..."
    log "目标目录: $INPUT_DIR"
    
    # 在指定目录中查找所有MP4文件，按文件名升序排序
    # 使用printf确保正确处理包含空格的文件名
    local mp4_files
    mp4_files=$(find "$INPUT_DIR" -maxdepth 1 -type f -name "*.mp4" -printf "%f\n" | sort)
    
    # 检查是否找到MP4文件
    if [ -z "$mp4_files" ]; then
        log "错误: 在目录 $INPUT_DIR 中未找到任何MP4文件"
        exit 1
    fi
    
    # 统计找到的文件数量
    local file_count=$(echo "$mp4_files" | wc -l)
    log "找到 $file_count 个MP4文件，准备生成input.txt..."
    
    # 生成input.txt文件
    local input_txt="$INPUT_DIR/input.txt"
    > "$input_txt"  # 清空文件
    
    # 写入文件列表，格式为 "file '文件名'"
    while IFS= read -r filename; do
        # 处理文件名中的特殊字符
        sanitized_filename=$(printf "%q" "$filename")
        echo "file '$sanitized_filename'" >> "$input_txt"
        log "添加文件到列表: $filename"
    done <<< "$mp4_files"
    
    log "input.txt生成完成，保存路径: $input_txt"
}

# 执行ffmpeg拼接命令
concat_videos() {
    log "开始视频拼接过程..."
    
    local input_txt="$INPUT_DIR/input.txt"
    local output_file="$INPUT_DIR/final.mp4"
    
    # 检查输出文件是否已存在
    if [ -f "$output_file" ]; then
        log "警告: 输出文件 $output_file 已存在，将被覆盖"
    fi
    
    log "开始执行ffmpeg命令..."
    log "输入文件列表: $input_txt"
    log "输出文件: $output_file"
    
    # 执行ffmpeg无损拼接命令
    ffmpeg -f concat -safe 0 -i "$input_txt" -c copy "$output_file" 2>> "$LOG_FILE"
    
    # 检查命令执行结果
    if [ $? -eq 0 ]; then
        log "视频拼接成功完成! 输出文件: $output_file"
    else
        log "错误: ffmpeg命令执行失败，请查看日志文件了解详情"
        exit 1
    fi
}

# 主函数
main() {
    # 解析参数
    parse_args "$@"
    
    # 记录脚本开始运行
    log "=== $SCRIPT_NAME 开始运行 ==="
    log "详细模式: $(if [ $VERBOSE -eq 1 ]; then echo "开启"; else echo "关闭"; fi)"
    
    # 检查依赖
    check_dependencies
    
    # 收集MP4文件并生成input.txt
    collect_mp4_files
    
    # 执行视频拼接
    concat_videos
    
    log "=== $SCRIPT_NAME 运行结束 ==="
    log "日志已保存到: $LOG_FILE"
    
    # 如果未开启详细模式，提示日志位置
    if [ $VERBOSE -eq 0 ]; then
        echo "操作完成，日志已保存到: $LOG_FILE"
        echo "输出文件: $INPUT_DIR/final.mp4"
    fi
}

# 启动主函数
main "$@"
