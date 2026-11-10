import 'dart:io';

class Palette {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[90m';
  static const String red = '\x1B[91m';
  static const String green = '\x1B[92m';
  static const String yellow = '\x1B[93m';
  static const String cyan = '\x1B[96m';

  static final bool _enabled = stdout.supportsAnsiEscapes;

  static String paint(String text, String color) =>
      _enabled ? '$color$text$reset' : text;

  static String strong(String text, String color) => paint(text, '$bold$color');
}

String formatPeso(double amount) => 'P${amount.toStringAsFixed(2)}';

double calculateLateFee(int daysKept, int allowedDays, double feePerDay) {
  final lateDays = daysKept - allowedDays;
  return lateDays > 0 ? lateDays * feePerDay : 0.0;
}

mixin Stamped {
  final DateTime madeAt = DateTime.now();

  String _two(int n) => n.toString().padLeft(2, '0');

  String get timeText =>
      '${madeAt.year}-${_two(madeAt.month)}-${_two(madeAt.day)} '
      '${_two(madeAt.hour)}:${_two(madeAt.minute)}';

  String get shortTime =>
      '${_two(madeAt.month)}-${_two(madeAt.day)} '
      '${_two(madeAt.hour)}:${_two(madeAt.minute)}';
}

mixin CardPrinter {
  String get cardHeading;
  List<String> get cardRows;
  String get color;

  String drawCard() => Screen.card(cardHeading, cardRows, color);
}

abstract class CenterEntry with Stamped, CardPrinter {
  final String _id;
  final String _title;

  CenterEntry(String id, String title) : _id = id, _title = title;

  String get id => _id;
  String get title => _title;

  String get kind;
  List<String> get tableCells;
  String get pickLabel;
}

abstract class Resource extends CenterEntry {
  final String _topic;
  final int _stock;
  int _onShelf;

  Resource(String id, String title, String topic, int stock)
    : _topic = topic,
      _stock = stock,
      _onShelf = stock,
      super(id, title);

  String get topic => _topic;
  int get stock => _stock;
  int get onShelf => _onShelf;

  int get loanDays;
  double get lateFeePerDay;

  bool takeOne() {
    if (_onShelf == 0) return false;
    _onShelf--;
    return true;
  }

  void putBack() {
    if (_onShelf < _stock) _onShelf++;
  }

  @override
  String get color => Palette.cyan;

  @override
  String get pickLabel =>
      '$id | $kind | $title | $_topic | $_onShelf of $_stock left';

  @override
  List<String> get tableCells => [
    id,
    kind,
    title,
    _topic,
    '$_onShelf/$_stock',
    '${loanDays}d',
  ];

  @override
  String get cardHeading => '${kind.toUpperCase()}  #$id';

  @override
  List<String> get cardRows => [
    'Title : $title',
    'Topic : $_topic',
    'Shelf : $_onShelf of $_stock copies',
    'Loan  : $loanDays days',
    'Late  : ${formatPeso(lateFeePerDay)} per day',
    'Added : $timeText',
  ];
}

class Book extends Resource {
  Book(String id, String title, String topic, int stock)
    : super(id, title, topic, stock);

  @override
  String get kind => 'Book';

  @override
  int get loanDays => 7;

  @override
  double get lateFeePerDay => 2.0;
}

class Gadget extends Resource {
  Gadget(String id, String title, String topic, int stock)
    : super(id, title, topic, stock);

  @override
  String get kind => 'Gadget';

  @override
  int get loanDays => 2;

  @override
  double get lateFeePerDay => 10.0;
}

class Member extends CenterEntry {
  final List<String> _held = [];

  Member(String id, String name) : super(id, name);

  int get maxItems => 2;
  String get tier => 'Member';
  List<String> get held => List.unmodifiable(_held);
  bool get hasRoom => _held.length < maxItems;

  void hold(String resourceId) => _held.add(resourceId);
  bool release(String resourceId) => _held.remove(resourceId);

  @override
  String get kind => 'Member';

  @override
  String get color => Palette.cyan;

  @override
  String get pickLabel =>
      '$id | $tier | $title | holding ${_held.length}/$maxItems';

  @override
  List<String> get tableCells => [id, title, tier, '${_held.length}/$maxItems'];

  @override
  String get cardHeading => '${tier.toUpperCase()}  #$id';

  @override
  List<String> get cardRows => [
    'Name    : $title',
    'Joined  : $timeText',
    'Holding : ${_held.length} of $maxItems items',
    'Items   : ${_held.isEmpty ? 'none' : _held.join(', ')}',
  ];
}

class Student extends Member {
  Student(String id, String name) : super(id, name);

  @override
  int get maxItems => 3;

  @override
  String get tier => 'Student';
}

class Guest extends Member {
  Guest(String id, String name) : super(id, name);

  @override
  int get maxItems => 1;

  @override
  String get tier => 'Guest';
}

class LogEntry extends CenterEntry {
  final String _action;
  final String _who;
  final String _what;
  final double _fee;

  LogEntry(String id, String action, String who, String what, double fee)
    : _action = action,
      _who = who,
      _what = what,
      _fee = fee,
      super(id, action);

  double get fee => _fee;

  @override
  String get kind => 'Log';

  @override
  String get color => Palette.cyan;

  @override
  String get pickLabel => '$id | $_action | $_who | $_what';

  @override
  List<String> get tableCells => [
    id,
    shortTime,
    _action,
    _who,
    _what,
    _fee > 0 ? formatPeso(_fee) : '-',
  ];

  @override
  String get cardHeading => '$_action  #$id';

  @override
  List<String> get cardRows => [
    'When   : $timeText',
    'Member : $_who',
    'Item   : $_what',
    'Fee    : ${formatPeso(_fee)}',
  ];
}

class ActionResult {
  final bool ok;
  final String message;

  ActionResult(this.ok, this.message);
}

class LearningCenter {
  final List<Resource> _shelf = [];
  final Map<String, Member> _roster = {};
  final List<LogEntry> _log = [];

  int _resourceNo = 0;
  int _memberNo = 0;
  int _logNo = 0;

  List<Resource> get shelf => List.unmodifiable(_shelf);
  Map<String, Member> get roster => Map.unmodifiable(_roster);
  List<LogEntry> get log => List.unmodifiable(_log);

  String _nextId(String letter, int number) =>
      '$letter${number.toString().padLeft(3, '0')}';

  Resource addResource(bool isBook, String title, String topic, int stock) {
    _resourceNo++;
    final id = _nextId('R', _resourceNo);
    final Resource item = isBook
        ? Book(id, title, topic, stock)
        : Gadget(id, title, topic, stock);
    _shelf.add(item);
    return item;
  }

  Member register(bool isStudent, String name) {
    _memberNo++;
    final id = _nextId('M', _memberNo);
    final Member person = isStudent ? Student(id, name) : Guest(id, name);
    _roster[id] = person;
    return person;
  }

  Resource? findResource(String id) {
    for (final item in _shelf) {
      if (item.id == id.toUpperCase()) return item;
    }
    return null;
  }

  Member? findMember(String id) => _roster[id.toUpperCase()];

  List<Member> membersWithRoom() => [
    for (final person in _roster.values)
      if (person.hasRoom) person,
  ];

  List<Member> membersHolding() => [
    for (final person in _roster.values)
      if (person.held.isNotEmpty) person,
  ];

  List<Resource> availableFor(Member person) => [
    for (final item in _shelf)
      if (item.onShelf > 0 && !person.held.contains(item.id)) item,
  ];

  List<Resource> heldBy(Member person) {
    final items = <Resource>[];
    for (final id in person.held) {
      final item = findResource(id);
      if (item != null) items.add(item);
    }
    return items;
  }

  int itemsOut() {
    var count = 0;
    for (final person in _roster.values) {
      count += person.held.length;
    }
    return count;
  }

  double computeFee(Resource item, int daysKept) {
    return calculateLateFee(daysKept, item.loanDays, item.lateFeePerDay);
  }

  void _record(String action, Member person, Resource item, double fee) {
    _logNo++;
    _log.add(
      LogEntry(_nextId('L', _logNo), action, person.title, item.title, fee),
    );
  }

  ActionResult lend(String memberId, String resourceId) {
    final person = findMember(memberId);
    final item = findResource(resourceId);

    if (person == null) {
      return ActionResult(false, 'Member "$memberId" was not found.');
    }
    if (item == null) {
      return ActionResult(false, 'Resource "$resourceId" was not found.');
    }
    if (!person.hasRoom) {
      return ActionResult(
        false,
        '${person.title} is a ${person.tier} and can only hold ${person.maxItems} item(s).',
      );
    }
    if (person.held.contains(item.id)) {
      return ActionResult(
        false,
        '${person.title} already holds "${item.title}".',
      );
    }
    if (!item.takeOne()) {
      return ActionResult(
        false,
        '"${item.title}" has no copies left on the shelf.',
      );
    }

    person.hold(item.id);
    _record('BORROW', person, item, 0);
    return ActionResult(
      true,
      '${person.title} borrowed "${item.title}" (free for ${item.loanDays} days).',
    );
  }

  ActionResult takeBack(String memberId, String resourceId, int daysKept) {
    final person = findMember(memberId);
    final item = findResource(resourceId);

    if (person == null) {
      return ActionResult(false, 'Member "$memberId" was not found.');
    }
    if (item == null) {
      return ActionResult(false, 'Resource "$resourceId" was not found.');
    }
    if (!person.release(item.id)) {
      return ActionResult(
        false,
        '${person.title} is not holding "${item.title}".',
      );
    }

    item.putBack();
    final fee = computeFee(item, daysKept);
    _record('RETURN', person, item, fee);
    final note = fee > 0
        ? 'Late fee: ${formatPeso(fee)} for $daysKept days kept.'
        : 'Returned on time, no fee.';
    return ActionResult(
      true,
      '"${item.title}" returned by ${person.title}. $note',
    );
  }

  Map<String, int> copiesByTopic() {
    final totals = <String, int>{};
    for (final item in _shelf) {
      totals[item.topic] = (totals[item.topic] ?? 0) + item.stock;
    }
    return totals;
  }

  double feesCollected() {
    double sum = 0;
    for (final entry in _log) {
      sum += entry.fee;
    }
    return sum;
  }
}

class Screen {
  static const int width = 80;
  static String accent = Palette.cyan;

  static String fit(String text, int size) => text.length > size
      ? '${text.substring(0, size - 3)}...'
      : text.padRight(size);

  static List<String> wrap(String text, int size) {
    final lines = <String>[];
    var current = '';
    for (final word in text.split(' ')) {
      if (current.isEmpty) {
        current = word;
      } else if (current.length + 1 + word.length <= size) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  static String _edge(String color) =>
      Palette.paint('+${'-' * (width - 2)}+', color);

  static String _row(String text, String color, {String? textColor}) {
    final cell = fit(text, width - 4);
    final body = textColor == null ? cell : Palette.paint(cell, textColor);
    return '${Palette.paint('|', color)} $body ${Palette.paint('|', color)}';
  }

  static void banner(String title, String color, {bool close = true}) {
    accent = color;
    final inner = width - 4;
    final left = (inner - title.length) ~/ 2;
    final centered = title.padLeft(left + title.length);
    print('');
    print(_edge(color));
    print(_row(centered, color, textColor: '${Palette.bold}$color'));
    if (close) print(_edge(color));
  }

  static String card(String heading, List<String> rows, String color) {
    final out = StringBuffer();
    out.writeln(_edge(color));
    out.writeln(_row(heading, color, textColor: '${Palette.bold}$color'));
    out.writeln(_edge(color));
    for (final row in rows) {
      out.writeln(_row(row, color));
    }
    out.write(_edge(color));
    return out.toString();
  }

  static void showCard(CenterEntry entry) => print('\n${entry.drawCard()}');

  static void menu(List<MenuItem> items) {
    banner('COMMUNITY LEARNING CENTER', Palette.cyan);
    final bar = Palette.paint('|', Palette.cyan);
    for (final item in items) {
      print('$bar   ${item.key}   ${fit(item.label, width - 10)} $bar');
    }
    print(_edge(Palette.cyan));
  }

  static void table(
    String title,
    String color,
    List<String> headers,
    List<int> widths,
    List<CenterEntry> entries,
  ) {
    banner(title, color, close: false);

    final fixed = widths.fold<int>(0, (sum, w) => sum + w);
    final flex = width - 1 - (3 * widths.length) - fixed;
    final cols = [for (final w in widths) w == 0 ? flex : w];
    final bar = Palette.paint('|', color);

    String divider(String fill) =>
        Palette.paint('+${cols.map((w) => fill * (w + 2)).join('+')}+', color);

    String line(List<String> cells, {String? tint}) {
      final parts = [
        for (var i = 0; i < cols.length; i++)
          tint == null
              ? fit(cells[i], cols[i])
              : Palette.paint(fit(cells[i], cols[i]), tint),
      ];
      return '$bar ${parts.join(' $bar ')} $bar';
    }

    print(divider('-'));
    print(line(headers, tint: Palette.bold));
    print(divider('='));
    if (entries.isEmpty) {
      print(_row('Nothing here yet.', color, textColor: Palette.dim));
    } else {
      for (final entry in entries) {
        print(line(entry.tableCells));
      }
    }
    print(divider('-'));
    print(
      '  ${Palette.paint('${entries.length} record(s) shown', Palette.dim)}',
    );
  }

  static void note(String text, String color, {String tag = ''}) {
    final lines = wrap(text, width - 4 - tag.length);
    print('');
    print(_edge(color));
    for (var i = 0; i < lines.length; i++) {
      final prefix = i == 0 ? tag : ' ' * tag.length;
      print(_row('$prefix${lines[i]}', color, textColor: color));
    }
    print(_edge(color));
  }

  static void success(String text) => note(text, Palette.green, tag: '[OK] ');

  static void error(String text) => note(text, Palette.red, tag: '[!]  ');

  static void notice(String text) => note(text, Palette.yellow);
}

class Input {
  static String text(String prompt) {
    while (true) {
      stdout.write('  > $prompt');
      final raw = stdin.readLineSync();
      if (raw == null) {
        Screen.notice('Input closed. Ending the program.');
        exit(0);
      }
      if (raw.trim().isNotEmpty) return raw.trim();
      Screen.error('Oops, this cannot be empty. Try again.');
    }
  }

  static int number(String prompt, int low, int high) {
    while (true) {
      final raw = text(prompt);
      try {
        final value = int.parse(raw);
        if (value < low || value > high) {
          Screen.error('Enter a number from $low to $high.');
          continue;
        }
        return value;
      } on FormatException {
        Screen.error('');
      }
    }
  }

  static T? pick<T>(
    String heading,
    List<T> options,
    String Function(T) labelOf,
  ) {
    var filter = '';
    while (true) {
      final needle = filter.toLowerCase();
      final shown = <T>[
        for (final option in options)
          if (needle.isEmpty || labelOf(option).toLowerCase().contains(needle))
            option,
      ];

      if (shown.isEmpty) {
        Screen.error('Nothing matches "$filter". Showing everything again.');
        filter = '';
        continue;
      }

      final title = filter.isEmpty ? heading : '$heading - search: "$filter"';
      final rows = [
        for (var i = 0; i < shown.length; i++)
          '${(i + 1).toString().padLeft(2)}. ${labelOf(shown[i])}',
      ];
      print('');
      print(Screen.card(title, rows, Screen.accent));
      print('  ${Palette.paint('', Palette.dim)}');

      final raw = text('Your pick: ');
      final number = int.tryParse(raw);
      if (number != null) {
        if (number == 0) return null;
        if (number >= 1 && number <= shown.length) return shown[number - 1];
        Screen.error(
          'Choose a number from 1 to ${shown.length}, or 0 to cancel.',
        );
      } else {
        filter = raw == '*' ? '' : raw;
      }
    }
  }
}

class MenuItem {
  final String key;
  final String label;

  MenuItem(this.key, this.label);
}

class CenterApp {
  final LearningCenter _center = LearningCenter();
  bool _running = true;

  static const String _newTopic = 'Other (type a new topic)';

  final List<MenuItem> _menu = [
    MenuItem('1', 'Add a book or gadget'),
    MenuItem('2', 'Sign up a member'),
    MenuItem('3', 'Borrow something'),
    MenuItem('4', 'Return something'),
    MenuItem('5', 'See what is on the shelf'),
    MenuItem('6', 'See all members'),
    MenuItem('7', 'See recent activity'),
    MenuItem('8', 'Look something up'),
    MenuItem('9', 'Quick summary'),
    MenuItem('0', 'Exit'),
  ];

  void _loadSamples() {
    _center.addResource(true, 'Dart Basics Handbook', 'Coding', 2);
    _center.addResource(true, 'Math Made Easy', 'Math', 3);
    _center.addResource(false, 'Reading Tablet', 'Devices', 1);
    _center.addResource(false, 'Laptop Lab Unit', 'Devices', 2);
    _center.register(true, 'Ana Cruz');
    _center.register(false, 'Visitor Ben');
    _center.register(true, 'Carlo Reyes');
  }

  void _offerSamples() {
    Screen.banner('WELCOME', Palette.cyan);
    final choice = Input.pick<String>('START WITH SAMPLE RECORDS?', [
      'Yes, load a few sample records',
      'No, start with an empty center',
    ], (s) => s);
    if (choice != null && choice.startsWith('Yes')) {
      _loadSamples();
      Screen.success('Sample books, gadgets and members are ready to use.');
    }
  }

  void run() {
    _offerSamples();
    while (_running) {
      Screen.menu(_menu);
      final choice = Input.text('What would you like to do? (0-9): ');
      _handle(choice);
    }
  }

  void _handle(String choice) {
    switch (choice) {
      case '1':
        _addResource();
        break;
      case '2':
        _registerMember();
        break;
      case '3':
        _borrow();
        break;
      case '4':
        _giveBack();
        break;
      case '5':
        Screen.table(
          'ON THE SHELF',
          Palette.cyan,
          ['ID', 'Type', 'Title', 'Topic', 'Shelf', 'Loan'],
          [4, 7, 0, 10, 7, 5],
          _center.shelf,
        );
        break;
      case '6':
        Screen.table(
          'MEMBERS',
          Palette.cyan,
          ['ID', 'Name', 'Tier', 'Holding'],
          [4, 0, 9, 8],
          _center.roster.values.toList(),
        );
        break;
      case '7':
        Screen.table(
          'RECENT ACTIVITY',
          Palette.cyan,
          ['ID', 'When', 'Action', 'Member', 'Item', 'Fee'],
          [4, 11, 6, 14, 0, 8],
          _center.log,
        );
        break;
      case '8':
        _lookUp();
        break;
      case '9':
        _summary();
        break;
      case '0':
        _running = false;
        Screen.banner('Thanks for stopping by. See you!', Palette.cyan);
        break;
      default:
        Screen.error(
          'Hmm, "$choice" is not on the menu. Pick a number from 0 to 9.',
        );
    }
  }

  void _cancelled() => Screen.notice('No problem, nothing was changed.');

  void _addResource() {
    Screen.banner('ADD A BOOK OR GADGET', Palette.cyan);

    final type = Input.pick<String>('SELECT RESOURCE TYPE', [
      'Book',
      'Gadget',
    ], (s) => s);
    if (type == null) {
      _cancelled();
      return;
    }

    final title = Input.text('Title: ');

    final known = _center.copiesByTopic().keys.toList();
    String topic;
    if (known.isEmpty) {
      topic = Input.text('Topic (e.g. Coding, Math): ');
    } else {
      final choice = Input.pick<String>('SELECT A TOPIC', [
        ...known,
        _newTopic,
      ], (s) => s);
      if (choice == null) {
        _cancelled();
        return;
      }
      topic = choice == _newTopic ? Input.text('New topic name: ') : choice;
    }

    final stock = Input.number('Copies (1-50): ', 1, 50);
    final item = _center.addResource(type == 'Book', title, topic, stock);
    Screen.success('"${item.title}" was added to the shelf.');
    Screen.showCard(item);
  }

  void _registerMember() {
    Screen.banner('SIGN UP A MEMBER', Palette.cyan);

    final name = Input.text('Full name: ');
    final tier = Input.pick<String>('SELECT A TIER', [
      'Student (can hold 3 items)',
      'Guest (can hold 1 item)',
    ], (s) => s);
    if (tier == null) {
      _cancelled();
      return;
    }

    final person = _center.register(tier.startsWith('Student'), name);
    Screen.success('${person.title} is all signed up.');
    Screen.showCard(person);
  }

  void _borrow() {
    Screen.banner('BORROW SOMETHING', Palette.cyan);

    if (_center.shelf.isEmpty || _center.roster.isEmpty) {
      Screen.error('Add a resource and register a member first.');
      return;
    }

    final eligible = _center.membersWithRoom();
    if (eligible.isEmpty) {
      Screen.error('Every member has reached their borrowing limit.');
      return;
    }

    final person = Input.pick<Member>(
      'SELECT A MEMBER',
      eligible,
      (m) => m.pickLabel,
    );
    if (person == null) {
      _cancelled();
      return;
    }

    final available = _center.availableFor(person);
    if (available.isEmpty) {
      Screen.error('No resources are available for ${person.title} right now.');
      return;
    }

    final item = Input.pick<Resource>(
      'SELECT A RESOURCE TO BORROW',
      available,
      (r) => r.pickLabel,
    );
    if (item == null) {
      _cancelled();
      return;
    }

    _show(_center.lend(person.id, item.id));
  }

  void _giveBack() {
    Screen.banner('RETURN SOMETHING', Palette.cyan);

    final holders = _center.membersHolding();
    if (holders.isEmpty) {
      Screen.error('Nothing is currently borrowed.');
      return;
    }

    final person = Input.pick<Member>(
      'SELECT THE MEMBER RETURNING',
      holders,
      (m) => m.pickLabel,
    );
    if (person == null) {
      _cancelled();
      return;
    }

    final item = Input.pick<Resource>(
      'SELECT THE ITEM BEING RETURNED',
      _center.heldBy(person),
      (r) => r.pickLabel,
    );
    if (item == null) {
      _cancelled();
      return;
    }

    final days = Input.pick<int>(
      'HOW LONG WAS IT KEPT?',
      [
        for (final extra in [0, 1, 2, 3, 5, 7]) item.loanDays + extra,
      ],
      (d) {
        final late = d - item.loanDays;
        return late == 0
            ? 'Kept $d days (on time)'
            : 'Kept $d days ($late day(s) late)';
      },
    );
    if (days == null) {
      _cancelled();
      return;
    }

    _show(_center.takeBack(person.id, item.id, days));
  }

  void _lookUp() {
    Screen.banner('LOOK SOMETHING UP', Palette.cyan);

    final group = Input.pick<String>('WHAT ARE YOU LOOKING FOR?', [
      'Learning resource',
      'Member',
      'Activity log entry',
    ], (s) => s);
    if (group == null) {
      _cancelled();
      return;
    }

    final List<CenterEntry> pool = group == 'Learning resource'
        ? <CenterEntry>[..._center.shelf]
        : group == 'Member'
        ? <CenterEntry>[..._center.roster.values]
        : <CenterEntry>[..._center.log];

    if (pool.isEmpty) {
      Screen.error('There are no records in that group yet.');
      return;
    }

    final entry = Input.pick<CenterEntry>(
      'SELECT A RECORD',
      pool,
      (e) => e.pickLabel,
    );
    if (entry == null) {
      _cancelled();
      return;
    }

    Screen.showCard(entry);
  }

  void _summary() {
    Screen.banner('QUICK SUMMARY', Palette.cyan);

    print('');
    print(
      Screen.card('OVERVIEW', [
        'Resources on record : ${_center.shelf.length}',
        'Registered members  : ${_center.roster.length}',
        'Items borrowed now  : ${_center.itemsOut()}',
        'Logged activities   : ${_center.log.length}',
        'Late fees collected : ${formatPeso(_center.feesCollected())}',
      ], Palette.cyan),
    );

    final topics = _center.copiesByTopic();
    final rows = <String>[];
    topics.forEach((topic, total) {
      final bar = '#' * (total > 30 ? 30 : total);
      rows.add('${Screen.fit(topic, 14)} ${total.toString().padLeft(3)}  $bar');
    });
    if (rows.isEmpty) rows.add('No resources yet.');

    print('');
    print(Screen.card('COPIES PER TOPIC', rows, Palette.cyan));
  }

  void _show(ActionResult result) {
    if (result.ok) {
      Screen.success(result.message);
    } else {
      Screen.error(result.message);
    }
  }
}

void main() {
  CenterApp().run();
}
