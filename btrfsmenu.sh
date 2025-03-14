#!/bin/bash

# 定义逻辑盘
LOG_FILE="/opt/snap/btrfs_manager.log"
VOLUMES=(/vol1 /vol2 /vol3)

log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 查看磁盘空间使用和剩余可用空间
show_disk_usage() {
    for vol in "${VOLUMES[@]}"; do
        echo "=== $vol ==="
        btrfs filesystem usage "$vol"
        echo
    done
}

# 列出所有子卷与快照
list_subvolumes_and_snapshots() {
    echo "=== 列出所有子卷与快照 ==="
    for vol in "${VOLUMES[@]}"; do
        echo "--- $vol ---"
        btrfs subvolume list -t "$vol"
        echo
    done

    echo "1) 管理快照"
    echo "[回车] 返回主菜单"
    read -p "选择: " choice

    case "$choice" in
        1) manage_snapshots;;
        "") return;;
        *) echo "无效输入";;
    esac
}

# 管理快照
manage_snapshots() {
    echo "=== 选择要管理的逻辑盘 ==="
    select vol in "${VOLUMES[@]}" "返回"; do
        [[ "$vol" == "返回" ]] && return
        if [[ -n "$vol" ]]; then
            list_snapshots "$vol"
            break
        fi
    done
}

list_snapshots() {
    local vol="$1"
    echo "=== $vol 的快照 ==="
    btrfs subvolume list "$vol"

    echo "a) 创建快照"
    echo "b) 删除快照"
    echo "c) 回滚快照"
    echo "[回车] 返回上级"
    read -p "选择: " choice

    case "$choice" in
        a) create_snapshot "$vol";;
        b) delete_snapshot "$vol";;
        c) rollback_snapshot "$vol";;
        "") return;;
        *) echo "无效输入";;
    esac
}

# 创建快照
create_snapshot() {
    local vol="$1"
    local snap_name="snapshot_$(date +%Y%m%d_%H%M%S)"
    sudo btrfs subvolume snapshot "$vol" "$vol/$snap_name"
    echo "快照已创建: $snap_name"
}

# 删除快照
delete_snapshot() {
    local vol="$1"
    echo "=== 选择要删除的快照 ==="
    local snaps=($(btrfs subvolume list "$vol" | awk '{print $NF}'))

    select snap in "${snaps[@]}" "返回"; do
        [[ "$snap" == "返回" ]] && return
        if [[ -n "$snap" ]]; then
            if [[ $(btrfs subvolume show "$vol/$snap" | grep -c "toplevel") -gt 0 ]]; then
                echo "禁止删除根子卷!"
                return
            fi
            sudo btrfs subvolume delete "$vol/$snap"
            log_action "删除快照: $snap"
            echo "快照已删除: $snap"
            break
        fi
    done
}

# 回滚快照
rollback_snapshot() {
    local vol="$1"
    echo "=== 选择要回滚的快照 ==="
    local snaps=($(btrfs subvolume list "$vol" | awk '{print $NF}'))

    select snap in "${snaps[@]}" "返回"; do
        [[ "$snap" == "返回" ]] && return
        if [[ -n "$snap" ]]; then
            read -p "确认回滚到快照 $snap? (yes/no): " confirm
            if [[ "$confirm" == "yes" ]]; then
                sudo umount "$vol" 2>/dev/null
                sudo btrfs subvolume delete "$vol"
                sudo btrfs subvolume snapshot "$vol/$snap" "$vol"
                log_action "回滚快照: $snap"
                echo "已回滚到快照: $snap"
                break
            fi
        fi
    done
}

# 维护与优化
maintain_and_optimize() {
    echo "1) 完整性检查与修复"
    echo "2) 数据平衡"
    echo "3) 查看上次完整性检查结果"
    echo "[回车] 返回主菜单"
    read -p "选择: " choice

    case "$choice" in
        1) scrub_data;;
        2) balance_data;;
        3) show_last_scrub_status;;
        "") return;;
        *) echo "无效输入";;
    esac
}

# 完整性检查与修复
scrub_data() {
    echo "=== 选择要修复的逻辑盘 ==="
    select vol in "${VOLUMES[@]}" "全部" "返回"; do
        [[ "$vol" == "返回" ]] && return
        if [[ "$vol" == "全部" ]]; then
            for v in "${VOLUMES[@]}"; do
                sudo btrfs scrub start "$v"
                log_action "启动 scrub: $v"
            done
        elif [[ -n "$vol" ]]; then
            sudo btrfs scrub start "$vol"
            log_action "启动 scrub: $vol"
        fi

        # 监测 scrub 是否完成
        while true; do
            clear
            echo "检查 $vol 的 scrub 状态..."
            btrfs scrub status "$vol"
            if btrfs scrub status "$vol" | grep -q "running"; then
                echo "scrub 仍在运行，请等待..."
                sleep 10
            else
                echo "scrub 完成。"
                break
            fi
        done
    done
}

# 显示上次完整性检查状态
show_last_scrub_status() {
    for vol in "${VOLUMES[@]}"; do
        echo "=== $vol 的最新完整性检查状态 ==="
        btrfs scrub status "$vol"
        log_action "查询 scrub 状态: $vol"
        echo
    done
}

# 监控设备健康状态
monitor_health() {
    for vol in "${VOLUMES[@]}"; do
        echo "=== $vol 信息 ==="
        btrfs device stats "$vol"
    done
}

# 显示文件系统基本信息
show_fs_info() {
    for vol in "${VOLUMES[@]}"; do
        echo "=== $vol 信息 ==="
        btrfs filesystem show "$vol"
    done
}

# 主循环
while true; do
    clear
    echo "==== BTRFS 管理工具 ===="
    echo "1) 查看磁盘空间使用和剩余可用空间"
    echo "2) 列出所有子卷与快照"
    echo "3) 维护与优化"
    echo "4) 监控设备健康状态"
    echo "5) 显示文件系统基本信息"
    echo "0) 退出"
    read -p "请输入选项: " choice

    case "$choice" in
        1) show_disk_usage;;
        2) list_subvolumes_and_snapshots;;
        3) maintain_and_optimize;;
        4) monitor_health;;
        5) show_fs_info;;
        0) exit;;
        *) echo "无效输入";;
    esac

    read -p "按回车继续..."
done