part of '../rapid_kit_sample_pages.dart';

class EventPage extends StatefulWidget {
  final String deviceId;

  const EventPage({super.key, required this.deviceId});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends LifecycleAwareState<EventPage> {
  static const double _thumbnailWidth = 120.0;
  static const double _thumbnailHeight = 68.0;

  static const int _pageSize = 30;
  late String _deviceId;
  int _selectedCategoryIndex = 0;

  bool _eventsLoading = true;
  final List<Event> _events = [];
  List<Category> _categories = [];
  DateTime _selectedDate = DateTime.now();
  final DateTime _todayDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('报警消息',
          style: TextStyle(color: SampleThemeConfigure.colorPrimary, fontSize: 16)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: () => _showBulkDeleteMenu(),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NotificationPage(deviceId: _deviceId)));
          },
        ),
      ],
      elevation: 0,
    );
  }

  Widget _buildRootBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: <Widget>[
            Expanded(
              child: _buildRootBottom(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRootBottom() {
    return Column(
      children: <Widget>[
        _categoriesBar(),
        _listContainer(),
      ],
    );
  }

  Widget _listContainer() {
    if (!_eventsLoading && _events.isEmpty) {
      return _emptyTips();
    }

    return Expanded(
      child: _eventsLoading
          ? createCenterLoading(size: 20.0)
          : RefreshIndicator(
              backgroundColor: SampleThemeConfigure.colorPrimary,
              color: Colors.white,
              displacement: 50,
              onRefresh: _pullToRefresh,
              child: _eventList(),
            ),
    );
  }

  Expanded _emptyTips() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_note, size: 50, color: SampleThemeConfigure.colorPrimary),
            SizedBox(height: 10),
            Text(
              '当日无事件',
              style: TextStyle(
                fontSize: 16,
                color: SampleThemeConfigure.colorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pullToRefresh() async {
    _events.clear();
    return _loadEventsOfDate();
  }

  Container _categoriesBar() {
    return Container(
      height: 60.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _datePicker(),
          _eventCategory(),
        ],
      ),
    );
  }

  Widget _eventCategory() {
    return GestureDetector(
      onTap: () async => _onPickCategory(),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Icon(
          Icons.filter_list,
          size: 22,
          color: SampleThemeConfigure.colorTextPrimary,
        ),
      ),
    );
  }

  GestureDetector _datePicker() {
    return GestureDetector(
      onTap: () async => _onPickDate(),
      child: Row(
        children: <Widget>[
          Text(
            _formattedDateString(),
            style: const TextStyle(fontSize: 16.0, color: SampleThemeConfigure.colorTextPrimary),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 0),
            child: Icon(
              Icons.arrow_drop_down_rounded,
              size: 30,
              color: SampleThemeConfigure.colorTextPrimary,
            ),
          )
        ],
      ),
    );
  }

  String _formattedDateString() {
    String formattedDate = _selectedDate.toChineseDate();

    if (_todayDate.day == _selectedDate.day) {
      formattedDate = "$formattedDate | 今天";
    }
    return formattedDate;
  }

  ListView _eventList() {
    return ListView.builder(
      itemCount: _events.length + 1,
      itemBuilder: (context, index) {
        if (index == _events.length) {
          return _loadMore();
        } else {
          return _eventCard(index);
        }
      },
    );
  }

  Padding _loadMore() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: GestureDetector(
        onTap: () => _loadEventsOfDate(),
        child: Container(
          decoration: BoxDecoration(
            color: SampleThemeConfigure.colorTextHint,
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
          child: const Center(
            child: Text(
              '点击加载更多',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventCard(int index) {
    return GestureDetector(
      onTap: () {
        // do nothing
      },
      child: _buildEventCard(index),
    );
  }

  Widget _buildEventCard(int index) {
    final event = _events[index];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 5, bottom: 5, top: 5),
        child: Row(
          children: <Widget>[
            _cardIcon(event),
            const SizedBox(width: 20.0),
            _cardDesc(event, false),
            const SizedBox(width: 12.0),
            _cardDeleteButton(event),
            const SizedBox(width: 8.0),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _cardThumbnail(false, event),
            ),
          ],
        ),
      ),
    );
  }

  Container _cardIcon(Event event) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 255, 170, 59),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ClipOval(
          child: Image.network(
            event.detail?.categoryIcon ?? "",
            fit: BoxFit.cover,
            color: Colors.white,
            colorBlendMode: BlendMode.srcATop,
          ),
        ),
      ),
    );
  }

  Expanded _cardDesc(Event event, bool selected) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            event.detail?.categoryName ?? "",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: selected
                  ? SampleThemeConfigure.colorPrimary
                  : SampleThemeConfigure.colorTextPrimary,
            ),
          ),
          Text(
            (event.startTime ?? 0).toHHmmss(),
            style: TextStyle(
              fontSize: 14.0,
              color: selected ? SampleThemeConfigure.colorPrimary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardDeleteButton(Event event) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _showDeleteMenu(event),
        child: Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          ),
          child: const Icon(
            Icons.delete_outline,
            size: 18.0,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  ClipRRect _cardThumbnail(bool selected, Event event) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Stack(
        children: [
          Image.network(
            event.thumbnail ?? "",
            width: _thumbnailWidth,
            height: _thumbnailHeight,
            fit: BoxFit.cover,
          ),
          if (selected) _cardThumbnailSelectedCover(),
        ],
      ),
    );
  }

  Container _cardThumbnailSelectedCover() {
    return Container(
      width: _thumbnailWidth,
      height: _thumbnailHeight,
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Text(
          "播放中",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _onPickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _eventsLoading = true;
      });

      _loadEventsOfDate();
    }
  }

  @override
  void initState() {
    super.initState();
    _deviceId = widget.deviceId;
    _loadCategories();
    _loadEventsOfDate();
  }

  void _loadEventsOfDate() async {
    List<String> categoriesLabel = [];
    if (_selectedCategoryIndex > 0 && _categories.isNotEmpty) {
      final category = _categories[_selectedCategoryIndex - 1];
      categoriesLabel.add(category.categoryLabel ?? "");
    }

    final eventsResp = await EventService.eventsByPage(
        _deviceId, _selectedDate.toStandardDate(), _events.length,
        catagoriesLabel: categoriesLabel, limit: _pageSize);
    if (mounted) {
      if (eventsResp.success) {
        final size = eventsResp.data?.length ?? 0;

        if (size < 1 && _events.isNotEmpty) {
          SnackTips.show(context, "没有更多数据了");
          return;
        }

        if (size > 0) {
          _events.addAll(eventsResp.data!);
        }

        setState(() {
          _eventsLoading = false;
        });
      } else {
        SnackTips.show(context, "message: ${eventsResp.message}");
      }
    }
  }

  void _loadCategories() async {
    final categoriesResp = await EventService.catagories(_deviceId);
    if (mounted) {
      if (categoriesResp.success) {
        setState(() {
          _categories = categoriesResp.data!.list ?? [];
        });
      } else {
        SnackTips.show(context, "message: ${categoriesResp.message}");
      }
    }
  }

  void _onPickCategory() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.separated(
          itemCount: _categories.length + 1,
          itemBuilder: (BuildContext context, int index) {
            String categoryName;

            if (index == 0) {
              categoryName = '全部';
            } else {
              final category = _categories[index - 1];
              categoryName = category.categoryName ?? 'No Label';
            }

            return ListTile(
              leading: Icon(
                _selectedCategoryIndex == index ? Icons.check_circle : Icons.circle_outlined,
                color: _selectedCategoryIndex == index
                    ? SampleThemeConfigure.colorPrimary
                    : Colors.grey,
              ),
              title: Text(categoryName),
              onTap: () {
                if (_selectedCategoryIndex != index) {
                  _selectedCategoryIndex = index;
                  _events.clear();
                  setState(() {
                    _eventsLoading = true;
                  });
                  _loadEventsOfDate();
                }
                Navigator.pop(context);
              },
            );
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(),
        );
      },
    );
  }

  void _showDeleteMenu(Event event) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '删除事件',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.person, color: SampleThemeConfigure.colorPrimary),
                title: const Text('为当前用户删除'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteEvent(event, global: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.red),
                title: const Text('为所有用户删除'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteEvent(event, global: true);
                },
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteEvent(Event event, {required bool global}) async {
    final eventId = event.id;
    if (eventId == null || eventId.isEmpty) {
      SnackTips.show(context, "事件ID无效");
      return;
    }

    final result = await EventService.deleteList([eventId], global: global);
    if (mounted) {
      if (result.success) {
        setState(() {
          _events.removeWhere((e) => e.id == eventId);
        });
        SnackTips.show(context, global ? "已为所有用户删除事件" : "已为当前用户删除事件");
      } else {
        SnackTips.show(context, "删除失败: ${result.message}");
      }
    }
  }

  void _showBulkDeleteMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '批量删除最末事件及其前一个小时内',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.person, color: SampleThemeConfigure.colorPrimary),
                title: const Text('为当前用户删除'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteBulkEvents(global: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.red),
                title: const Text('为所有用户删除'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteBulkEvents(global: true);
                },
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteBulkEvents({required bool global}) async {
    if (_events.isEmpty) {
      SnackTips.show(context, "当前没有事件可删除");
      return;
    }

    final latestEventTimestamp = _events.first.startTime ?? 0;
    final oneHourBeforeLatestEvent = latestEventTimestamp - 3600;

    final result = await EventService.deleteRangeOfList(
        [_deviceId], oneHourBeforeLatestEvent, latestEventTimestamp,
        global: global);

    if (mounted) {
      if (result.success) {
        setState(() {
          _events.clear();
          _eventsLoading = true;
        });
        _loadEventsOfDate();
        SnackTips.show(context, global ? "已为所有用户删除最末事件及其前一个小时内" : "已为当前用户删除最末事件及其前一个小时内");
      } else {
        SnackTips.show(context, "批量删除失败: ${result.message}");
      }
    }
  }
}
