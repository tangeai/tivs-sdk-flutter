part of '../rapid_kit_sample_pages.dart';

Widget homeDeviceCard(
    Primary primary,
    Map<String, OnlineStatus> onlineStatusMap,
    Map<String, Thumbnail> thumbnailsMap,
    Map<String, BatteryStatus> batteryStatusMap,
    Map<String, Timezone> timezoneMap,
    BuildContext context,
    VoidCallback onRemovedCallback) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = constraints.maxWidth;
      final cardHeight = cardWidth * 9 / 16;

      return SizedBox(
        key: ValueKey('rapid-home-device-card-${primary.deviceId ?? ''}'),
        height: cardHeight,
        child: Card(
          margin: const EdgeInsets.only(bottom: 0),
          elevation: 0,
          color: SampleThemeConfigure.colorForeground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: InkWell(
            onTap: () => _handleOnTap(primary, context),
            onLongPress: () =>
                _handleOnLongPress(primary, context, onRemovedCallback),
            child: Stack(
              children: [
                _buildCoverBackground(primary, thumbnailsMap),
                _buildOverlay(primary, onlineStatusMap),
                _buildHeaderSection(primary),
                _buildBottomButtonSection(
                    primary, timezoneMap, context, onRemovedCallback),
                _buildBatteryLabel(primary, batteryStatusMap),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildCoverBackground(
    Primary primary, Map<String, Thumbnail> thumbnailsMap) {
  String url = "";
  if (thumbnailsMap.containsKey(primary.deviceId ?? "")) {
    url = thumbnailsMap[primary.deviceId ?? ""]?.url ?? "";
  }

  return Positioned.fill(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        children: [
          url.isEmpty
              ? Container(
                  color: Colors.grey[300],
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                    );
                  },
                ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildOverlay(
    Primary primary, Map<String, OnlineStatus> onlineStatusMap) {
  bool online = false;
  int? offlineAt;
  if (onlineStatusMap.containsKey(primary.deviceId ?? "")) {
    online = onlineStatusMap[primary.deviceId ?? ""]?.isOnline ?? false;
    offlineAt = onlineStatusMap[primary.deviceId ?? ""]?.offlineAt;
  }

  String offlineText = '离线';
  if (!online && offlineAt != null && offlineAt > 0) {
    final offlineTime = DateTime.fromMillisecondsSinceEpoch(offlineAt * 1000);
    final formattedTime =
        '${offlineTime.year.toString().padLeft(4, '0')}-${offlineTime.month.toString().padLeft(2, '0')}-${offlineTime.day.toString().padLeft(2, '0')} ${offlineTime.hour.toString().padLeft(2, '0')}:${offlineTime.minute.toString().padLeft(2, '0')}:${offlineTime.second.toString().padLeft(2, '0')}';
    offlineText = '已于 $formattedTime 离线';
  }

  return Positioned.fill(
    child: Container(
      decoration: BoxDecoration(
        color: online
            ? SampleThemeConfigure.colorOverlayLight
            : SampleThemeConfigure.colorOverlayDark,
        borderRadius: BorderRadius.circular(25),
      ),
      child: online
          ? Center(
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: SampleThemeConfigure.colorSoftWhite.withOpacity(0.6),
                size: 48,
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.portable_wifi_off,
                    color: SampleThemeConfigure.colorSoftWhite,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offlineText,
                    style: const TextStyle(
                      color: SampleThemeConfigure.colorSoftWhite,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    ),
  );
}

Widget _buildHeaderSection(Primary primary) {
  return Positioned(
    top: 16,
    left: 16,
    right: 16,
    child: Row(
      children: [
        const Icon(
          Icons.videocam_rounded,
          color: SampleThemeConfigure.colorSoftWhite,
          size: 28,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (primary.deviceName?.isNotEmpty == true)
                    ? primary.deviceName!
                    : "未命名设备",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: SampleThemeConfigure.colorSoftWhite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                primary.deviceId ?? "",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: SampleThemeConfigure.colorSoftWhite.withOpacity(0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildBottomButtonSection(
    Primary primary,
    Map<String, Timezone> timezoneMap,
    BuildContext context,
    VoidCallback onRemovedCallback) {
  return Positioned(
    bottom: 12,
    left: 8,
    right: 8,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBottomIconButton(Icons.wb_cloudy_rounded,
            () => _navigateToCloudReplay(context, primary, timezoneMap)),
        _buildBottomIconButton(Icons.event_note_rounded,
            () => _navigateToEvent(context, primary.deviceId ?? "")),
        _buildBottomIconButton(Icons.sd_card_outlined,
            () => _navigateToLocalReplay(context, primary)),
        if (primary.isOwner == true)
          _buildBottomIconButton(Icons.upload,
              () => _navigateToFirmware(context, primary.deviceId ?? ""))
        else
          _buildBottomIconButton(Icons.upload, null),
        _buildBottomIconButton(
            Icons.more_horiz_rounded,
            () =>
                _showSettingsBottomSheet(context, primary, onRemovedCallback)),
      ],
    ),
  );
}

Widget _buildBottomIconButton(IconData icon, VoidCallback? onPressed) {
  return SizedBox(
    width: 44,
    height: 44,
    child: IconButton(
      icon: Icon(
        icon,
        size: 24,
        color: onPressed != null
            ? SampleThemeConfigure.colorSoftWhite
            : SampleThemeConfigure.colorSoftWhite.withOpacity(0.4),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    ),
  );
}

Widget _buildBatteryLabel(
    Primary primary, Map<String, BatteryStatus> batteryStatusMap) {
  bool hasBattery = false;
  int level = -1;
  bool low = false;
  bool charging = false;

  if (batteryStatusMap.containsKey(primary.deviceId)) {
    level = batteryStatusMap[primary.deviceId]?.level ?? 0;
    low = batteryStatusMap[primary.deviceId]?.isLow ?? false;
    charging = batteryStatusMap[primary.deviceId]?.isCharging ?? false;
    if (level >= 0) {
      hasBattery = true;
    }
  }

  if (!hasBattery) {
    return const SizedBox.shrink();
  }

  final Icon batteryIcon;
  if (charging) {
    batteryIcon = const Icon(
      Icons.battery_charging_full_rounded,
      color: Colors.yellow,
      size: 14,
    );
  } else if (low) {
    batteryIcon = const Icon(
      Icons.battery_1_bar,
      color: Colors.red,
      size: 14,
    );
  } else {
    batteryIcon = const Icon(
      Icons.battery_full,
      color: SampleThemeConfigure.colorSoftWhite,
      size: 14,
    );
  }

  return Positioned(
    right: 16,
    top: 20,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        batteryIcon,
        const SizedBox(width: 4),
        Text(
          '$level%',
          style: const TextStyle(
            color: SampleThemeConfigure.colorSoftWhite,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

void _showSettingsBottomSheet(
    BuildContext pageContext, Primary primary, VoidCallback onRemovedCallback) {
  showModalBottomSheet(
    context: pageContext,
    builder: (BuildContext bottomSheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('重命名设备'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _onEditDeviceName(
                    pageContext, primary.deviceId ?? '', onRemovedCallback);
              },
            ),
            if (primary.isOwner == true)
              ListTile(
                title: const Text('共享设备'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _navigateToShare(pageContext, primary);
                },
              ),
            const Divider(),
            ListTile(
              title: Text(
                primary.isOwner == true ? '删除设备' : '退出分享',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showRemoveDeviceDialog(
                    pageContext, primary, onRemovedCallback);
              },
            ),
            ListTile(
              title: const Text('取消'),
              onTap: () => Navigator.pop(bottomSheetContext),
            ),
          ],
        ),
      );
    },
  );
}

void _navigateToShare(BuildContext context, Primary primary) {
  if (primary.isOwner != true) {
    SnackTips.show(context, "只有设备主人才能管理共享！");
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SharePage(
        deviceId: primary.deviceId ?? "",
        deviceName: primary.deviceName ?? "",
      ),
    ),
  );
}

void _navigateToEvent(BuildContext context, String deviceId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EventPage(
        deviceId: deviceId,
      ),
    ),
  );
}

void _navigateToCloudReplay(
    BuildContext context, Primary primary, Map<String, Timezone> timezoneMap) {
  final deviceId = primary.deviceId ?? "";
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CloudReplayPage(
        deviceId: deviceId,
        deviceName: primary.deviceName ?? "",
        cameraCount: recognizedCameraCount(primary),
        deviceTimezone: timezoneMap[deviceId],
      ),
    ),
  );
}

void _navigateToLocalReplay(BuildContext context, Primary primary) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LocalReplayPage(
        deviceId: primary.deviceId ?? "",
        deviceName: primary.deviceName ?? "",
        cameraCount: recognizedCameraCount(primary),
        deviceAbilities: primary.deviceAbilities,
      ),
    ),
  );
}

void _navigateToFirmware(BuildContext context, String deviceId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FirmwarePage(
        deviceId: deviceId,
      ),
    ),
  );
}

void _openCallLivePage(BuildContext context, Primary primary) {
  final deviceId = primary.deviceId ?? '';
  if (deviceId.isEmpty) {
    SnackTips.show(context, '设备 ID 为空');
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CallLivePage(
        outgoingOptions: const OutgoingCallOptions(),
        deviceId: primary.deviceId ?? '',
        deviceName: primary.deviceName ?? '',
        cameraCount: recognizedCameraCount(primary),
        lan: false,
        deviceAbilities: primary.deviceAbilities,
      ),
    ),
  );
}

void _navigateToLivePage(BuildContext context, Primary primary) {
  if (!context.mounted) return;
  int cameraCount = recognizedCameraCount(primary);
  final live = LivePage(
    deviceId: primary.deviceId ?? "",
    deviceName: primary.deviceName ?? "",
    cameraCount: cameraCount,
    lan: false,
    deviceAbilities: primary.deviceAbilities,
  );

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => live),
  );
}

void _navigateToComposePage(BuildContext context, Primary primary) {
  if (!context.mounted) return;
  int cameraCount = recognizedCameraCount(primary);
  final compose = ComposePage(
    deviceId: primary.deviceId ?? "",
    deviceName: primary.deviceName ?? "",
    cameraCount: cameraCount,
    lan: false,
    deviceAbilities: primary.deviceAbilities,
  );

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => compose),
  );
}

void _navigateToSimpleLive(BuildContext context, Primary primary) {
  if (!context.mounted) return;
  final simpleLive = SimpleLivePage(
    deviceId: primary.deviceId ?? "",
    deviceName: primary.deviceName ?? "",
    deviceAbilities: primary.deviceAbilities,
  );

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => simpleLive),
  );
}

void _navigateToSimpleRtc(BuildContext context, Primary primary) {
  if (!context.mounted) return;
  final simpleRtc = SimpleRtcPage(
    deviceId: primary.deviceId ?? "",
    deviceName: primary.deviceName ?? "",
  );

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => simpleRtc),
  );
}

void _handleOnTap(Primary primary, BuildContext context) {
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          "选择页面",
          style: TextStyle(
            fontSize: 20,
            color: SampleThemeConfigure.colorPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.network_check),
                title: const Text('Receive monitor'),
                subtitle: const Text('Audio and camera receive stability'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiveMonitorPage(
                    deviceId: primary.deviceId ?? '',
                    cameraCount: recognizedCameraCount(primary),
                    deviceAbilities: primary.deviceAbilities,
                  )));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.live_tv,
                  color: Colors.red,
                  size: 28,
                ),
                title: const Text(
                  "独立直播页",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  "支持多目设备 • 专注直播体验",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToLivePage(context, primary);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.call_rounded,
                  color: SampleThemeConfigure.colorPrimary,
                  size: 28,
                ),
                title: const Text(
                  "呼叫&直播页",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  "呼叫接通后再进入音视频",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openCallLivePage(context, primary);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.tab,
                  color: Colors.blue,
                  size: 28,
                ),
                title: const Text(
                  "聚合播放页",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  "Tab 切换设计 • 直播 + 回放一体化",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToComposePage(context, primary);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.green,
                  size: 28,
                ),
                title: const Text(
                  "简易播放页",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  "轻量级实现 • 快速集成演示",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSimpleLive(context, primary);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.link,
                  color: Colors.orange,
                  size: 28,
                ),
                title: const Text(
                  "RTC 连接页",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  "仅 P2P 连接 • 状态监控展示",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSimpleRtc(context, primary);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "取消",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    },
  );
}

void _handleOnLongPress(
    Primary primary, BuildContext context, VoidCallback onRemovedCallback) {
  // _navigateToSimpleLive(context, primary);
}

void _showRemoveDeviceDialog(
    BuildContext pageContext, Primary primary, VoidCallback onRemovedCallback) {
  final isOwner = primary.isOwner ?? false;
  showDialog(
    context: pageContext,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('移除设备'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(isOwner ? '你确定要删除这个设备吗？' : "你确定要退出分享吗？"),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () async {
              _removeDevice(primary, pageContext, onRemovedCallback);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void _removeDevice(Primary primary, BuildContext context,
    VoidCallback onRemovedCallback) async {
  final isOwner = primary.isOwner ?? false;
  if (isOwner) {
    final resp = await BindingService.unbind(primary.deviceId ?? "");
    if (!context.mounted) return;
    if (resp.success) {
      SnackTips.show(context, "设备已删除");
      onRemovedCallback.call();
    } else {
      SnackTips.show(context, "错误: ${resp.code} ${resp.message}");
    }
  } else {
    final resp = await SharingService.leaveSharing(primary.deviceId ?? "");
    if (!context.mounted) return;
    if (resp.success) {
      SnackTips.show(context, "已退出分享");
      onRemovedCallback.call();
    } else {
      SnackTips.show(context, "错误: ${resp.code} ${resp.message}");
    }
  }
}

void _onEditDeviceName(
    BuildContext context, String deviceId, VoidCallback onRemovedCallback) {
  final TextEditingController controller = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('更新名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '新的名称，如"大门口"',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: const Text('设备名称不能为空'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                final response =
                    await SpecService.rename(deviceId, controller.text);
                if (!context.mounted) return;
                if (!response.success) {
                  SnackTips.show(context, "Error: ${response.message}");
                } else {
                  SnackTips.show(context, "重命名成功");
                  onRemovedCallback.call();
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('确认'),
          ),
        ],
      );
    },
  );
}

int recognizedCameraCount(Primary primary) {
  int cameraCount = 1;
  if (primary.deviceAttributes?.contains("ipc-2ch") == true ||
      primary.deviceAbilities?.contains("2-composed") == true) {
    cameraCount = 2;
  } else if (primary.deviceAbilities?.contains("3-composed") == true) {
    cameraCount = 3;
  }
  return cameraCount;
}
