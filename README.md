Btrfs Management Script Function Overview
​1. Core Modules
​Disk Space Monitoring
Displays storage usage details (total/used/free space, RAID modes) via btrfs filesystem usage.
​Function: show_disk_usage()

​Subvolume & Snapshot Management

Lists all subvolumes/snapshots (btrfs subvolume list) with per-volume filtering.
​Snapshot Operations: Create/delete/rollback snapshots using COW (Copy-on-Write) mechanisms.
Safety checks to prevent accidental deletion of root subvolumes.
​Functions: list_subvolumes_and_snapshots(), manage_snapshots(), etc.
​Maintenance & Optimization

​Data Scrubbing: Detects and repairs silent data corruption via btrfs scrub.
​Data Balancing: Optimizes storage distribution (requires parameter extension).
Displays latest scrub status (btrfs scrub status).
​Functions: maintain_and_optimize(), scrub_data()
​Device Health Monitoring
Tracks physical device health (I/O errors, read/write failures) using btrfs device stats.
​Function: monitor_health()

​2. Auxiliary Features
​Logging
Logs all operations to /opt/snap/btrfs_manager.log with timestamps.
​Function: log_action()

​Interactive CLI Menu
User-friendly menu system for multi-level navigation.

​Safety Mechanisms

Confirmation prompts for critical actions (e.g., rollback).
Protection checks before subvolume deletion.
​3. Use Cases
​Data Backup & Recovery: Snapshot-based version control.
​Storage Pool Management: RAID status monitoring and optimization.
​System Maintenance: Scheduled data integrity checks and balancing.
​Design Highlights
​Modular Architecture: Easily extendable (e.g., adding RAID management).
​Automated Logging: Auditable operation records.
​User-Friendly: Reduces CLI complexity through interactive menus.
