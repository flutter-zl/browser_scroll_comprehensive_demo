import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void main() {
  _registerPlatformViews();
  runApp(const MyApp());
}

void _registerPlatformViews() {
  ui_web.platformViewRegistry.registerViewFactory(
    'youtube-iframe',
    (int viewId) {
      return html.IFrameElement()
        ..src = 'https://www.youtube.com/embed/dQw4w9WgXcQ'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..setAttribute('allowfullscreen', 'true');
    },
  );

  ui_web.platformViewRegistry.registerViewFactory(
    'scrollable-html-div',
    (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'auto'
        ..style.backgroundColor = '#f5f5f5'
        ..style.fontFamily = 'Arial, sans-serif'
        ..style.fontSize = '14px'
        ..style.padding = '16px'
        ..style.boxSizing = 'border-box';

      final title = html.HeadingElement.h3()
        ..text = 'Same-Origin Scrollable HTML'
        ..style.color = '#6200ea'
        ..style.marginTop = '0';
      container.append(title);

      final desc = html.ParagraphElement()
        ..text = 'This is a same-origin <div> with overflow:auto. '
            'It has its own scrollable content. When this div reaches '
            'its scroll boundary, the parent Flutter page should take over.'
        ..style.color = '#666';
      container.append(desc);

      for (int i = 1; i <= 30; i++) {
        final item = html.DivElement()
          ..style.padding = '12px'
          ..style.margin = '4px 0'
          ..style.backgroundColor = i.isEven ? '#e8eaf6' : '#ffffff'
          ..style.borderRadius = '4px'
          ..style.borderLeft = '3px solid #6200ea';

        final itemTitle = html.Element.tag('strong')..text = 'HTML Item $i';
        item.append(itemTitle);

        final itemText = html.ParagraphElement()
          ..text = 'This is native HTML content inside a scrollable div. '
              'Scroll down to reach the boundary.'
          ..style.margin = '4px 0 0 0'
          ..style.fontSize = '12px'
          ..style.color = '#888';
        item.append(itemText);

        container.append(item);
      }

      return container;
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Browser Scroll - Comprehensive Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ComprehensiveTestPage(),
    );
  }
}

class ComprehensiveTestPage extends StatefulWidget {
  const ComprehensiveTestPage({super.key});

  @override
  State<ComprehensiveTestPage> createState() => _ComprehensiveTestPageState();
}

class _ComprehensiveTestPageState extends State<ComprehensiveTestPage> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  String _dropdownValue = 'Option A';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  static const MethodChannel _browserScrollChannel = MethodChannel(
    'flutter/browser_scroll',
    JSONMethodCodec(),
  );

  Future<void> _browserSmoothScrollTo(double offset) {
    return _browserScrollChannel.invokeMethod<void>(
      'smoothScrollTo',
      <String, Object?>{'offset': offset},
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Scroll Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_scrollOffset.toStringAsFixed(0)}px',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'top',
            onPressed: () => _browserSmoothScrollTo(0),
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Scroll to Top'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'bottom',
            onPressed: () => _browserSmoothScrollTo(999999),
            icon: const Icon(Icons.arrow_downward),
            label: const Text('Scroll to Bottom'),
          ),
        ],
      ),
      body: BrowserScrollable(
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          physics: const BrowserScrollPhysics(),
          children: [
            // TEST 1: Basic scroll
            _TestSection(
              number: 1,
              title: 'Basic Flutter Scroll',
              description: 'Scroll this page with mouse wheel or trackpad. '
                  'The browser drives scrolling natively.',
              color: Colors.blue,
              status: _scrollOffset > 50 ? TestStatus.pass : TestStatus.pending,
              child: SizedBox(
                height: 400,
                child: ListView(
                  children: [
                    for (int i = 1; i <= 20; i++) _FlutterCard(index: i),
                  ],
                ),
              ),
            ),

            // TEST 2: Cross-origin iframe (YouTube)
            _TestSection(
              number: 2,
              title: 'Cross-Origin Iframe (YouTube)',
              description: 'Move your cursor over the video and scroll. '
                  'The page should continue scrolling without getting stuck.',
              color: Colors.red,
              child: const SizedBox(
                height: 315,
                child: HtmlElementView(viewType: 'youtube-iframe'),
              ),
            ),

            // TEST 3: Same-origin scrollable div
            _TestSection(
              number: 3,
              title: 'Same-Origin Scrollable HTML',
              description:
                  'This HTML div has its own scroll. Scroll inside it to '
                  'the bottom, then keep scrolling. The parent Flutter page should '
                  'take over at the boundary.',
              color: Colors.deepPurple,
              child: const SizedBox(
                height: 300,
                child: HtmlElementView(viewType: 'scrollable-html-div'),
              ),
            ),

            // TEST 4: Keyboard scroll
            _TestSection(
              number: 4,
              title: 'Keyboard Scroll',
              description: 'Click on the page, then press Page Down, Space, '
                  'or Arrow Down. The browser should handle keyboard scrolling '
                  'on the flutter-view element.',
              color: Colors.teal,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _KeyHint(label: 'Page Down'),
                        _KeyHint(label: 'Space'),
                        _KeyHint(label: 'Arrow Down'),
                        _KeyHint(label: 'Home'),
                        _KeyHint(label: 'End'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // TEST 5: Overlays & Dialogs
            _TestSection(
              number: 5,
              title: 'Overlays & Dialogs',
              description: 'Test dialogs, menus, dropdowns, and bottom sheets '
                  'inside BrowserScrollable. They should position correctly '
                  'and not interfere with scroll.',
              color: Colors.purple,
              child: _buildOverlayTests(context),
            ),

            // More content for scrolling
            for (int i = 6; i <= 25; i++) _FlutterCard(index: i),

            // TEST 6: Bottom reached
            _TestSection(
              number: 6,
              title: 'Bottom Reached',
              description: 'You scrolled to the bottom without getting stuck! '
                  'All scroll boundary crossing scenarios are working.',
              color: Colors.green,
              status: TestStatus.pass,
              child:
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayTests(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dialog
        _overlayRow(
          icon: Icons.open_in_new,
          label: 'Show Dialog',
          child: ElevatedButton(
            onPressed: () => _showTestDialog(context),
            child: const Text('Open Dialog'),
          ),
        ),
        const Divider(height: 24),

        // Input Dialog
        _overlayRow(
          icon: Icons.edit_note,
          label: 'Input Dialog',
          child: ElevatedButton(
            onPressed: () => _showInputDialog(context),
            child: const Text('Open Input Dialog'),
          ),
        ),
        const Divider(height: 24),

        // DropdownButton
        _overlayRow(
          icon: Icons.arrow_drop_down_circle,
          label: 'Dropdown',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: DropdownButton<String>(
              value: _dropdownValue,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'Option A', child: Text('Option A')),
                DropdownMenuItem(value: 'Option B', child: Text('Option B')),
                DropdownMenuItem(value: 'Option C', child: Text('Option C')),
                DropdownMenuItem(value: 'Option D', child: Text('Option D')),
                DropdownMenuItem(value: 'Option E', child: Text('Option E')),
              ],
              onChanged: (v) => setState(() => _dropdownValue = v!),
            ),
          ),
        ),
        const Divider(height: 24),

        // PopupMenuButton
        _overlayRow(
          icon: Icons.more_vert,
          label: 'Popup Menu',
          child: PopupMenuButton<String>(
            onSelected: (v) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Selected: $v'),
                    duration: const Duration(seconds: 1)),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'cut',
                  child:
                      ListTile(leading: Icon(Icons.cut), title: Text('Cut'))),
              PopupMenuItem(
                  value: 'copy',
                  child:
                      ListTile(leading: Icon(Icons.copy), title: Text('Copy'))),
              PopupMenuItem(
                  value: 'paste',
                  child: ListTile(
                      leading: Icon(Icons.paste), title: Text('Paste'))),
              PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete), title: Text('Delete'))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Actions'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 24),

        // MenuAnchor
        _overlayRow(
          icon: Icons.menu_open,
          label: 'MenuAnchor',
          child: _MenuAnchorTest(),
        ),
        const Divider(height: 24),

        // Bottom Sheet
        _overlayRow(
          icon: Icons.vertical_align_bottom,
          label: 'Bottom Sheet',
          child: ElevatedButton(
            onPressed: () => _showBottomSheet(context),
            child: const Text('Show Bottom Sheet'),
          ),
        ),
      ],
    );
  }

  Widget _overlayRow(
      {required IconData icon, required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.purple.shade400),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
  }

  void _showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Dialog'),
        content: const Text(
          'This dialog should appear centered in the viewport. '
          'Tapping outside or pressing the button should close it. '
          'Scroll should be blocked while this is open.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Dialog'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Type something to test keyboard interaction inside a dialog overlay.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('You typed: ${controller.text}'),
                    duration: const Duration(seconds: 2)),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Bottom Sheet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'This bottom sheet slides up from the bottom of the viewport.'),
            const SizedBox(height: 16),
            ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () => Navigator.pop(ctx)),
            ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Link'),
                onTap: () => Navigator.pop(ctx)),
            ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('Bookmark'),
                onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }
}

enum TestStatus { pending, pass, fail }

class _TestSection extends StatelessWidget {
  const _TestSection({
    required this.number,
    required this.title,
    required this.description,
    required this.color,
    required this.child,
    this.status = TestStatus.pending,
  });

  final int number;
  final String title;
  final String description;
  final MaterialColor color;
  final Widget child;
  final TestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  radius: 16,
                  child: Text('$number',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 13, color: color.shade600),
                      ),
                    ],
                  ),
                ),
                if (status == TestStatus.pass)
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                if (status == TestStatus.fail)
                  const Icon(Icons.cancel, color: Colors.red, size: 28),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FlutterCard extends StatelessWidget {
  const _FlutterCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Text('$index'),
        ),
        title: Text('Flutter Widget $index'),
        subtitle: const Text('Regular Flutter content in the scroll list'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100,
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade800,
        ),
      ),
    );
  }
}

class _MenuAnchorTest extends StatefulWidget {
  @override
  State<_MenuAnchorTest> createState() => _MenuAnchorTestState();
}

class _MenuAnchorTestState extends State<_MenuAnchorTest> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.undo),
          onPressed: () {},
          child: const Text('Undo'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.redo),
          onPressed: () {},
          child: const Text('Redo'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.select_all),
          onPressed: () {},
          child: const Text('Select All'),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.format_align_left),
          menuChildren: [
            MenuItemButton(onPressed: () {}, child: const Text('Left')),
            MenuItemButton(onPressed: () {}, child: const Text('Center')),
            MenuItemButton(onPressed: () {}, child: const Text('Right')),
          ],
          child: const Text('Align'),
        ),
      ],
      child: GestureDetector(
        onTap: () {
          if (_controller.isOpen) {
            _controller.close();
          } else {
            _controller.open();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Menu'),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
