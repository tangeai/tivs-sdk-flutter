## 1.7.4-alpha.1
2026-11-10
- Document a known H.265 local replay picture corruption issue: split or malformed encoded packets can trigger `invalid_nal_framing` and decoder input errors.
- Packet-level capture and a native repair are pending; this release updates the package version and issue status only.

## 1.7.3-alpha.20
2026-11-06
- Pin Android, iOS, macOS, Windows, Linux and OHOS native SDKs to 1.7.3-alpha.20.
- Validate the traceable cross-platform release pipeline before the 1.7.3 stable release.

## 1.7.3-alpha.18
2026-11-02
- Pin Android, iOS, macOS, Windows, Linux and OHOS native SDKs to RapidKit 1.7.3-alpha.18.
- Validate Flutter OHOS dependencies, plugin synchronization and packaged HAR contents before publication.
- Recover incomplete Flutter Windows and Linux SDK caches before consumer builds.

## 1.7.3-alpha.17
2026-11-02
- Pin Android, iOS, macOS, Windows and Linux native SDKs to RapidKit 1.7.3-alpha.17.
- Add cross-platform release gates for native version freshness and public artifact integrity.
- Recover incomplete Flutter Windows SDK caches before consumer builds.

## 1.7.3-alpha.16
2026-10-29
- Pin the Android, iOS and macOS native SDKs to RapidKit 1.7.3-alpha.16.
- Harden codec and configuration transitions before decode to prevent corrupt output.
- Improve active quality-switch queue cleanup while preserving passive stream transitions.
- Add bounded Android MediaCodec input backpressure recovery.

## 1.7.3-alpha.15
2026-10-27
- Pin the Android, iOS and macOS native SDKs to RapidKit 1.7.3-alpha.15.
- Harden H.264 and H.265 decoder recovery after corrupt frames, missing references and decoder restarts.
- Preserve parameter sets across resolution changes and normalize Annex-B and length-prefixed restart input.
- Add opt-in replay and live-stream diagnostics with bounded per-frame dump support.
- Support local replay playback mode selection across native and Flutter platforms.

## 1.7.3-alpha.12
2026-10-22
- Pin the Android, iOS and macOS native SDKs to RapidKit 1.7.3-alpha.12.
- Configure the current subnet broadcast address before iOS LAN discovery.
- Restart iOS discovery and clear stale devices when the broadcast address changes, without extending the scan deadline.
- Preserve scan generations and stop before timeout callbacks so discovery can restart safely.
- Guard missing iOS interface addresses and preserve distinct IP and netmask logs.

## 1.7.3-alpha.10
2026-10-22
- Pin the Android, iOS and macOS native SDKs to RapidKit 1.7.3-alpha.10.
- Support H.265 software recording and native iOS/Android video decoder backends.
- Harden replay query isolation, seek generations, playback modes and timezone handling.
- Fix command timeout progress and player lifecycle handling during page teardown.

## 1.7.3-alpha.8
2026-10-15
- Add opt-in PPCS and replay timeline diagnostics without changing read results.
- Preserve partial-read behavior while stream debugging is enabled.
- Keep Android Wi-Fi diagnostics behind explicit app consent.
- Pin the Android native SDK to RapidKit 1.7.3-alpha.8.
- This alpha targets Android. Other platforms are outside this release's validation scope.

## 1.7.3-alpha.6
2026-10-12
- Gate Android Wi-Fi diagnostic logging behind explicit app consent.
- Add a privacy consent gate to the Flutter sample before service initialization.
- Pin the Android native SDK to RapidKit 1.7.3-alpha.6.
- This alpha targets Android. Other platforms are outside this release's validation scope.

## 1.7.3-alpha.5
2026-10-10
- Harden local replay timeline isolation across repeated and backward AOV seeks.
- Reuse verified UTC/PTS anchors only for matching replay requests and playback modes.
- Pin the Android native SDK to RapidKit 1.7.3-alpha.5.
- This alpha targets Android. Other platforms are outside this release's validation scope.

## 1.7.3-alpha.4
2026-09-29
- Updated the Android RapidKit dependency to 1.7.3-alpha.4.
- Kept the iOS and macOS RapidKit dependencies at 1.7.0.
- Added Android receive metrics access.
- Added firmware upgrade progress polling APIs.

## 1.7.3-alpha.3
2026-09-28
- Isolate record-query and presentation state across replay timeline seeks.
- Support sparse AOV timelines and selected recording ranges during seeks.
- Pin the Android native SDK to RapidKit 1.7.3-alpha.3.
- This alpha targets Android. Other platforms are outside this release's validation scope.

## 1.7.3-alpha.2
2026-09-22
- Normalize timelapse video frame flags at the playback boundary.
- Accept wire video frame flags 0 through 3 while preserving audio and RTM flags.
- Pin the Android native SDK to RapidKit 1.7.3-alpha.2.
- This alpha targets Android. Other platforms are outside this release's validation scope.

## 1.7.3-alpha.1
2026-09-21
- Isolate replay-list queries and preserve response ownership across cancellation and retries.
- Release query connections asynchronously with bounded cleanup and recover local replay session boundaries.
- Pin the Android native SDK to RapidKit 1.7.3-alpha.1.
- This alpha targets Android. Other platforms are outside this release's validation scope.

## 1.7.2
2026-09-14
- [修复] 修复卡录像播放无音频的问题

## 1.7.1
2026-09-07
- [新增] 支持云录像索引查询、回放码流选择，以及云录像和本地回放截取接口
- [新增] 标准指令补充呼叫控制、能力集、云台长指令、预置点与变焦、电源策略、最大唤醒时长和屏幕显示时长
- [新增] 标准指令补充 OSD、移动侦测区域、巡航轨迹、定时巡航和守望点
- [优化] 统一 Android、iOS 和 Flutter 标准指令的类型化响应模型
- [新增] 支持 Flutter Linux 和 macOS 桌面端蓝牙配网
- [新增] 支持基于实际写入媒体时间戳的原生录制时长接口与回调
- [新增] 支持 iOS 对讲硬件 AEC 音频链路
- [优化] 完善云回放和本地回放时间线、Pipe 生命周期及本地录制稳定性
- [修复] 修复 iOS 插件注册崩溃及 BLE 自动选择 SIG 标准服务的问题
- [修复] 修复云回放时间戳、本地回放 UTC 同步及远程唤醒错误处理问题

## 1.6.0
2026-08-04
- [新增] Android 对讲支持软件 AEC、硬件 AEC、降噪和自动增益控制
- [优化] 完善对讲发送音频和录制时长诊断能力
- [修复] 修复对讲 G711A 编码杂音和缓存连接音频能力查询异常问题
- [修复] 修复录制时长计算、音频重采样时间戳和回调时序问题
- [修复] 修复 Windows Flutter 插件日志 API 编译和 macOS 动态库打包问题
- [修复] 修复双目设备本地回放仅显示一路画面的问题
- [修复] 修复 iOS 视频渲染失败未正确上报的问题

## 1.5.2
2026-06-29
- [新增] 支持播放器自动缓冲上限配置
- [修复] 修复 BLE 配网兼容和设备能力查询异常响应崩溃问题

## 1.5.0
2026-06-24
- [新增] 支持 WebRTC 局域网本地预览、Android BLE 设备绑定和录制时长回调
- [新增] 支持 Android 硬件解码链路、视频主时钟模式、固定缓冲和直播播放诊断
- [优化] 优化直播延时、播放缓冲策略和 Android 硬解纹理渲染
- [修复] 修复 MediaCodec 截图、iOS BLE 广播名称、BLE 写特征选择、Wi-Fi SSID 权限判断和 Android 音频录制句柄兼容性问题

## 1.4.0
2026-06-01
- [新增] 支持设备呼叫与被呼叫，覆盖来电、呼出、接通、挂断、拒接、未接、忙线和异地接听等状态
- [新增] 支持 App 向设备发送自定义消息
- [新增] 标准指令支持云台预置位管理和播放报警声
- [新增] 云存回放支持 AOV 场景、AES 解密、按文件列表回放和时间线时间戳显示
- [新增] 播放器支持音频-only 播放和本地回放录制
- [优化] 优化云存回放 seek 与低帧率 AOV 回放体验
- [修复] 修复云存 G711A 音频周期性蜂鸣问题
- [修复] 修复局域网直播启动、云存回放时间同步、对讲 AEC、Android 音频录制、指令请求响应和 iOS 编译相关问题

## 1.3.2
2026-05-19
- [优化] 修复直播播放中音频输出未绑定时提前到达的音频帧处理问题，改善多次进入播放页后可能出现的播放异常

## 1.3.1
2025-12-23
 - [优化] 语音对讲：屏蔽各平台音频采集回调分包差异，统一对远端送流的 payload 长度为 320 字节，提升设备播放兼容性
 - [优化] 音频播放：Android 平台下统一采用 AudioTrack，规避 OpenSL ES 在部分设备上的兼容性问题

## 1.3.0
2025-12-20
- [新增] 语音对讲支持全双工双向对讲场景
- [新增] 播放器支持切换系统音频通道（媒体 / 通话），用于对讲场景适配
- [优化] macOS Framework 打包：修复 Framework 结构异常导致的 Xcode Archive -> Distribute 失败问题

## 1.2.1
2025-11-19
- [优化] 修复部分设备录屏 MP4 底部绿边问题，兼容编码端 U/V linesize > width/2 的对齐场景

## 1.2.0
2025-11-12
- [新增] 标准指令支持电源策略
- [新增] 云录像下载支持获取原始视频文件路径

## 1.1.4
2025-11-08
- [优化] 低功耗设备在高并发指令交互场景下，因 fd 双重关闭与快速复用触发 fdsan 终止导致的概率性闪退

## 1.1.3
2025-10-10
- [优化] Windows 平台下多重响应型指令的回调处理逻辑，解决查询回放索引列表无响应的问题

## 1.1.2
2025-10-09
- [新增] Windows 平台支持将 SDK 运行时日志写入本地并上传
- [优化] Windows 平台 UTC 时间帧的校验逻辑，解决特定场景下的闪退问题

## 1.1.1
2025-09-24
- [优化] Windows 平台 Socket 关闭逻辑，以解决低功耗设备连接闪退问题

## 1.1.0
2025-09-22
- [优化] 更新 Windows TGRTC 底层库版本
- [优化] 优化关键帧重定位算法，增强弱网环境下的播放恢复能力

## 1.0.99
2025-09-18
- [优化] 优化数据读取超时逻辑，以改善停止视频流时的响应性能
- [新增] 云端事件删除功能现已支持面向所有用户进行操作

## 1.0.98
2025-09-17
- [优化] 更新 ohos 二进制包

## 1.0.97
2025-09-16
- [新增] 标准指令支持指定主通道
- [新增] 连接出图性能监测面板

## 1.0.96
2025-09-15
- [新增] 支持 Android 16 KB 的页面大小
- [新增] 扩展 P2P 连接状态枚举，新增“互联网不可用”、“设备密码错误”、“设备令牌无效”等
- [优化] 强化 P2P 实例生命周期管理，修复高并发连接场景下的 Use-After-Free 风险
- [优化] 重构指令通道的请求响应模型，解决高并发压力测试下的死锁问题
- [优化] 优化首帧视频的处理流程，提升出图速度
- [优化] 调整“查询卡录像索引”指令的超时阈值，提升弱网查询成功率

## 1.0.95
2025-09-11
- [新增] 标准指令“查询卡录像索引”中支持返回事件时间戳
- [优化] 部分低功耗设备在查询录像列表响应为空场景下的闪退问题
- [优化] 视频 PTS 异常跳跃场景下，播放线程出现阻塞的问题

## 1.0.94
2025-09-09
- [新增] 标准指令“云台”支持指定通道 channel

## 1.0.93
2025-09-09
- [新增] 标准指令“画面”支持指定通道 channel

## 1.0.92
2025-09-02
- [修复] 未下发连接信息的设备，无法通过重试获取最新云端信息的问题
- [新增] 标准指令支持查询电池状态
- [新增] 标准指令支持变焦设置
- [新增] 标准指令支持 PIR 设置
- [新增] 标准指令支持 LED 状态灯设置
- [新增] 标准指令支持电源频率设置

## 1.0.91
2025-08-30
- [优化] 提升播放器截图的编码性能，解决特定场景下的超时问题
- [新增] 播放器支持获取截图与录屏产物的本地文件路径

## 1.0.90
2025-08-22
- [修复] P2P 连接的引用计数管理时序，解决预连接场景下连接状态回调丢失的问题

## 1.0.89
2025-08-21
- [修复] 部分 Android 设备 OpenSL ES 引擎在倍速播放模式下停止响应的问题
- [修复] P2P 连接的资源管理时序，解决因快速重复建连/断连导致的竞态崩溃
- [修复] P2P 密码错误场景下，认证流程因竞态条件导致的偶发崩溃
- [修复] 修复播放中 P2P 连接异常中断后，停止卡回放导致的崩溃
- [优化] 提升视频解码模块对特定像素格式的处理性能
- [新增] “运行状态”面板增加对云、卡录像流的异常状态检测功能
- [新增] 云事件查询支持跨天聚合，可一次性获取多日事件列表


## 1.0.88
2025-08-14
- [优化] 多目设备播放场景中，多个播放器的音画同步性能
- [优化] 多目设备录屏时，子播放器录屏无声音的问题

## 1.0.87
2025-08-12
- [优化] HTTP 请求中 platform 的判定逻辑

## 1.0.86
2025-08-11
- [新增] 存储卡录像日期查询接口
- [新增] 播放器纹理绑定状态动态检测
- [优化] 播放器内部包队列管理逻辑，解决特定场景下的概率性闪退
- [优化] 播放器特殊帧的分发逻辑，防止潜在内存泄漏

## 1.0.85
2025-08-04
- [优化] P2P 连接清理逻辑，解决快速反复创建与断开连接时的概率性闪退
- [优化] 视频解码内存管理机制，解决特定场景下的概率性闪退
- [优化] 数据帧过滤逻辑，解决网络或设备传输异常引发的闪退
- [优化] ANativeWindow 图像渲染逻辑，解决部分 Android 手机的视频绿边问题
- [优化] 播放数据队列分发机制，解决视频积压时加速逻辑滞后触发的问题

## 1.0.84
2025-08-01
* [优化] 改进播放器解码渲染和内存管理机制，降低运行时内存占用
* [优化] 改进播放状态检测机制，减少网络抖动导致的缓冲状态切换
* [优化] 修复 iOS 平台连接某些设备热点后本地广播地址获取失败问题
* [优化] 修复 HarmonyOS 平台未指定蓝牙特征值时的空指针异常

## 1.0.83
2025-07-26
* [优化] 白光灯设置中的返回值处理逻辑

## 1.0.82
2025-07-24
* [优化] HarmonyOS 上申请蓝牙权限，可能无法触发弹窗的问题
* [优化] 提升视频录制的性能表现
* [优化] 优化视频截图的内存占用
* [新增] 支持查询或更新 AI 功能开关
* [新增] 支持查询或更新事件侦测开关
* [新增] 支持获取设备附近的 Wi-Fi 列表
* [新增] 支持更新设备连接的 Wi-Fi
* [新增] 支持查询或更新 IP 配置
* [新增] 支持查询设备网络类型与信号强度
* [新增] 支持获取直播流当前所使用的清晰度

## 1.0.81
2025-07-22
* [优化] HarmonyOS 上触发人机校验时，可能无法发送验证码的问题

## 1.0.80
2025-07-21
* [新增] 支持监听视频录制的 Muxer 队列大小，用于录制性能监控

## 1.0.79
2025-07-20
* [优化] 视频解码缓冲机制，解决低性能设备内存占用过高问题
* [优化] P2P 连接建立后的处理逻辑异步化，避免与底层 TGRTC 冲突
* [新增] 播放器实时性能监控，支持播放状态跟踪分析

## 1.0.78
2025-07-16
* [优化] 请求清晰度的指令返回的 label 与能力集中配置不对应的问题
* [优化] 视频播放缓冲逻辑，减少卡顿提升播放流畅度

## 1.0.77
2025-07-10
* [优化] Android 平台热点配网中的 Wi-Fi 切换与释放

## 1.0.76
2025-07-08
* [优化] 弱网络场景，产生视频丢包后的快速关键帧重定位
* [优化] 弱网络场景，产生视频丢包后的音频快速消费策略
* [优化] 调整缓冲算法的阈值，提升播放体验
* [优化] P2P 连接，自动进行有限次重试
* [优化] P2P 连接，兼容某些场景下断开连接的闪退
* [优化] P2P 连接，针对密码校验进行自动重试与超时处理
* [新增] 调试工具“运行状态”面板加入播放缓冲的状态监控


## 1.0.75
2025-07-03
* [新增] 播放器支持获取当前图像帧数据
* [新增] 设备信息查询返回 productKey 字段
* [优化] 弱网络播放体验
* [优化] Android 平台包体积降低 25%

## 1.0.74
2025-06-30
* [新增] 支持监听用户令牌中途失效的情形
* [新增] 基础指令支持设置与获取云台位置

## 1.0.73
2025-06-27
* [优化] 云录像下载支持自定义文件名称

## 1.0.72
2025-06-27
* [优化] iOS 本地沙盒路径生成逻辑
* [优化] 云录像下载支持多路视频

## 1.0.71
2025-06-27
* [新增] HarmonyOS 支持长连接消息
* [优化] HarmonyOS 的视频渲染机制
* [优化] HarmonyOS 的静音控制逻辑
* [优化] iOS 平台的日志打印机制
* [优化] 云录像播放在某些场景下无法收到播放结束回调的问题

## 1.0.70
2025-06-22
* [新增] 支持云录像下载
* [优化] 云录像的播放体验
* [优化] 视频录制在某些场景下可能缺少尾部数据的问题

## 1.0.69
2025-06-18
* [新增] 格式化存储卡支持自定义超时时长
* [新增] Windows 支持长连接消息
* [优化] Windows 音频输出体验
* [优化] 播放器在启动前设置静音不生效

## 1.0.68
2025-06-11
* [新增] “关闭计划”标准指令
* [新增] 调试工具“运行状态”面板

## 1.0.67
2025-06-07
* [优化] 特定设备播放时音频偏小的问题

## 1.0.66
2025-06-04
* [新增] 长连接消息传输通道
* [优化] 特定设备清晰度设置失败导致无法出图
* [优化] 特定设备在连接失败场景下的处理逻辑

## 1.0.65
2025-05-30
* [新增] 支持 16K 音频播放
* [新增] “移动侦测”标准指令
* [优化] 音频播放体验

## 1.0.64
2025-05-23
* [新增] 在 iOS 上进行人机校验

## 1.0.63
2025-05-08
* [优化] Windows 底层接入最新 Native 库

## 1.0.62
2025-05-06
* [优化] Android 平台上的静音逻辑

## 1.0.61
2025-04-24
* [新增] 支持设置语音对讲的音频采样率（8K、16K）
* [新增] 支持定制固件升级轮询的总时长
* [优化] iOS 平台上二进制库的打包方式

## 1.0.60
2025-03-28
* [新增] 标准指令集支持查询当前连接的 Wi-Fi

## 1.0.59
2025-03-24
* [改进] 优化 iOS 平台中的 BLE 连接逻辑

## 1.0.58
2025-03-24
* [改进] 优化 BleTransport 的超时通知机制

## 1.0.57
2025-03-24
* [改进] 优化 Android / iOS 平台中的 BLE GATT 服务发现与重试逻辑

## 1.0.56
2025-03-17
* [新增] 支持 Windows 平台

## 1.0.55
2025-03-14
* [改进] AP 配网下的密码校验逻辑

## 1.0.54
2025-03-13
* [改进] TGRTC_V2 在 Android 平台闪退的问题

## 1.0.53
2025-03-13
* [改进] 局域网直连场景下连接成功但不出图的问题

## 1.0.52
2025-03-10
* [新增] LiveStream 支持请求设备立即发出关键帧

## 1.0.51
2025-03-08
* [改进] 弱网丢帧场景下的帧重定位逻辑

## 1.0.50
2025-03-06
* [新增] 宠物喂养指令

## 1.0.49
2025-03-02
* [新增] 警戒语音指令：支持铃声自定义

## 1.0.48
2025-02-28
* [新增] 警戒语音指令：支持查询、设置、播放

## 1.0.47
2025-02-27
* [改进] TGRTC_V1 在特定场景下闪退的问题
* [改进] 音视频流 WatchDog 线程的退出机制
* [新增] 注册推送服务时，支持指定自定义铃声

## 1.0.46
2025-01-19
* [改进] 优化 HarmonyOS 的音频渲染逻辑，以解决录像播放速度异常问题
* [改进] 底层 native 库播放器 Release 逻辑精简

## 1.0.45
2025-01-17
* [改进] 优化下载机制，提升针对部分云存储源的兼容性

## 1.0.44
2025-01-14
* [新增] 适配 HarmonyOS 的临时相册权限
* [新增] Player 新增 paused 状态
* [改进] 底层 native 库的截图逻辑精简

## 1.0.43
2025-01-09
* [改进] 已连接状态下，新建 Pipe 无法收到 established 状态
* [改进] 标准指令的底层数据结构内存分配优化
* [改进] 发送自定义指令时，若请求错误，状态未回调
* [新增] example 新增标准指令、自定义指令的示例

## 1.0.42
2025-01-07
* [新增] 云录像流支持暂停、恢复
* [新增] 卡录像流支持暂停、恢复
* [新增] 播放器支持暂停、恢复

## 1.0.41
2025-01-07
* [改进] 更新“移动追踪”查询指令所使用的结构体格式

## 1.0.40
2025-01-06
* [新增] 标准指令集支持“移动追踪”
* [新增] 卡录像流支持根据起止时间获取
* [改进] 兼容“夜视”指令中，设备采用通用响应结构体回复而引起的闪退

## 1.0.39
2024-12-31
* [改进] 优化录像场景下的 completed 状态判定机制
* [新增] 播放器支持设置进度回调的更新间隔

## 1.0.38
2024-12-30
* [改进] 优化下载机制，提高对各种云存储源的兼容性
* [新增] “云录像流” CloudReplayStream 支持监听状态

## 1.0.37
2024-12-26
* [改进] 升级 iOS native 库
* [改进] 优化 iOS 与 macOS 中的音频停止播放逻辑

## 1.0.36
2024-12-25 🎁 🎄 🫎 🎉 🎆
* [新增] 云录像支持 UTC 时间戳回调
* [改进] 优化云录像 SEEK 逻辑

## 1.0.35
2024-12-23
* [新增] 云录像支持倍速播放
* [改进] 诊断助手逻辑优化

## 1.0.34
2024-12-20
* [新增] 自动采集 native 层闪退信息
* [改进] 在 Android 中禁用 impeller 渲染引擎

## 1.0.33
2024-12-20
* [新增] 自动采集 native 层闪退信息
* [改进] 播放器销毁逻辑优化

## 1.0.32
2024-12-18
* [改进] Android OPENSL ES 音频渲染优化

## 1.0.31
2024-12-18
* [新增] 卡录像支持倍速播放
* [改进] 优化播放器渲染模块的停止逻辑
* [改进] 适配 Flutter v3.27.x 的编译工具链

## 1.0.30
2024-12-16
* [修复] HarmonyOS NEXT release 包中接口报 undefined
* [改进] 运行时日志上传时的内部文件结构
* [新增] API 通道，支持直接请求 TIVS 云端接口

## 1.0.29
2024-12-13
* [修复] 部分设备通过热点传输配网信息时的崩溃问题

## 1.0.28
2024-12-12
* [改进] 支持在音视频源数据流出现异常后重新进行定位

## 1.0.27
2024-12-11
* [修复] 绑定状态轮询逻辑可能不会启动的问题
* [修复] 通过接入点热点传输配网信息时的崩溃问题
* [改进] 支持回调申请运行时权限的授权状态
* [改进] 将 "Wifi" 类重命名为 "WifiAbility" 并更新方法名称
* [改进] 将 "Permission" 枚举重命名为 "PermissionType"
* [新增] 支持通过 Platform Channel 启动系统设置页面
* [新增] 提供开发者工具集，用于日志上传与调试码的生成
* [新增] 支持设置播放器使用启用音频
* [新增] 支持本地回放流的暂停与恢复

## 1.0.26
2024-12-07
* [新增] 支持回调当前播放 UTC 时间戳

## 1.0.25
2024-12-05
* [新增] 媒体播放器时间戳的回调

## 1.0.24
2024-12-03
* [新增] 支持回调与获取视频的原始尺寸

## 1.0.23
2024-11-29
* [新增] 在 Android 和 OHOS 上进行人机校验

## 1.0.22
2024-11-28
* [新增] 局域网下进行设备发现和连接、播放

## 1.0.21
2024-11-26
* [新增] 通过 HTTP 协议发送绑定配置信息

## 1.0.20
2024-11-25
* [新增] 在 OHOS 上支持 BLE 绑定

## 1.0.19
2024-11-25
* [新增] 在 Android 上支持 BLE 绑定
* [改进] 能力集指令内部的解析优化

## 1.0.18
2024-11-16
* [改进] 设备连接

## 1.0.17
2024-11-14
* [新增] 一批基础指令集
* [新增] 支持低功耗设备的唤醒与连接
* [新增] 性能统计工具

## 1.0.16
2024-11-07
* [新增] 支持在 OHOS 上写入视频到系统相册
* [新增] 设备连接的多实例管理
* [改进] 设备连接的处理逻辑

## 1.0.15
2024-11-04
* [新增] 视频录制支持

## 1.0.14
2024-10-30
* [新增] 多通道播放器的支持

## 1.0.13
2024-10-28
* [新增] 在 Android 上声明 INTERNET 权限

## 1.0.12
2024-10-28
* [改进] 在 Android 上使用 OPEN SL ES 进行音频渲染

## 1.0.11
2024-10-26
* [新增] 更新 iOS native 库

## 1.0.10
2024-10-25
* [新增] 示例更新

## 1.0.9
2024-10-24
* [新增] 在 OHOS 上支持 TGRTC 协议

## 1.0.8
2024-10-24
* [新增] 更新 Android native 库

## 1.0.7
2024-10-23
* [新增] 基础指令集支持云台控制

## 1.0.6
2024-10-23
* [新增] 推送通知的处理示例

## 1.0.5
2024-10-23
* [改进] 更新 OH native 库

## 1.0.4
2024-10-22
* [新增] 支持 Harmony 移动推送通道

## 1.0.3
2024-10-17
* [新增] 在 macOS 上支持 TGRTC 协议

## 1.0.2
2024-10-10
* [新增] 在 macOS 上支持切换 API 环境

## 1.0.1
2024-10-09
* [改进] 降低 path 和 intl 依赖版本，以兼容 OHOS Flutter 框架

## 1.0.0
2024-09-30
* [新增] 首个正式版本

## 0.1.14
2024-09-30
* [改进] 更新 OH 原生库

## 0.1.12
2024-09-25
* [修复] 在 OHOS 上外接纹理的初始状态

## 0.1.11
2024-09-23
* [新增] 支持 HarmonyOS NEXT 平台

## 0.1.10
2024-08-31
* [改进] 文档更新

## 0.1.9
2024-08-31
* [改进] 文档更新

## 0.1.8
2024-08-31
* [新增] 运行时日志的写入、导出和上传
* [修复] 在 Android 平台上的 HTTPS 证书问题

## 0.1.7
2024-08-25
* [改进] 设备连接的重试逻辑
* [改进] 缓冲分发逻辑
* [改进] 渲染状态通知

## 0.1.6
2024-08-23
* [修复] 在 iOS 上的内存泄漏问题
* [修复] 在 iOS 上的音频播放问题
* [新增] 在 iOS 上的本地网络广播
* [新增] 在 iOS 上的视频录制

## 0.1.5
2024-08-23
* [修复] 在 Android 上销毁 MediaChat 时的崩溃问题

## 0.1.4
2024-08-19
* [新增] 进一步优化 "Player" 的设计

## 0.1.3
2024-08-16
* [新增] 优化设备连接

## 0.1.2
2024-08-16
* [新增] 添加视频截图和屏幕录制功能

## 0.1.1
2024-08-09
* [修复] 处理一系列问题

## 0.1.0
2024-08-04
* [新增] 云录像播放

## 0.0.9
2024-07-08
* [新增] 支持设备绑定
* [新增] 支持本地回放

## 0.0.8
2024-06-24
* [新增] 常用云端API的封装

## 0.0.7
2024-06-22
* [新增] 支持音频播放（iOS SDL 实现）
* [新增] 支持音画同步

## 0.0.6
2024-06-21
* [新增] 支持音频播放（MacOS SDL 实现）

## 0.0.5
2024-06-18
* [新增] 支持音频播放（Android SDL 实现）

## 0.0.4
2024-06-18
* [新增] 更新原生基础依赖

## 0.0.3
2024-06-15
* [新增] 移除一些平台支持

## 0.0.2
2024-06-15
* [新增] 支持 iOS / MacOS 平台

## 0.0.1
2024-06-15
* [新增] 初始测试版本，支持 Android 平台
