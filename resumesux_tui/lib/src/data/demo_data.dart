/// Demo adapter: builds seed [TableViewRow]s and detail sections for every
/// screen so `--demo` can render the whole shell with realistic resume data
/// and no network. Also honours a demo `state` (empty|error) for exercising
/// those states.
library;

import '../app/store.dart';
import '../term/theme.dart';
import '../widgets/detail.dart';

/// Build the initial rows for a screen. When [demoState] is 'empty' the
/// screen is empty; when 'error' it throws-like failure (conveyed to the view
/// through the error load state).
List<TableViewRow> demoRows(ScreenId screen, String? demoState) {
  if (demoState == 'empty') return [];
  if (demoState == 'error') return [];

  switch (screen) {
    case ScreenId.applicants:
      return _applicants();
    case ScreenId.jobreqs:
      return _jobreqs();
    case ScreenId.applications:
      return _applications();
    case ScreenId.gigs:
      return _gigs();
    case ScreenId.assets:
      return _assets();
  }
}

/// Load state for a demo screen (mirrors adapter outcome).
LoadState demoLoadState(ScreenId screen, String? demoState) {
  if (demoState == 'error') return LoadState.error;
  if (demoState == 'empty') return LoadState.empty;
  return LoadState.loaded;
}

String? demoError(ScreenId screen, String? demoState) =>
    demoState == 'error' ? 'could not reach adapter (seed error)' : null;

/// Detail sections for a selected row of [screen]. [row] carries `.detail`.
List<DetailSection> demoDetail(ScreenId screen, TableViewRow row) {
  switch (screen) {
    case ScreenId.applicants:
      final name = row.cells.isNotEmpty ? row.cells[0].text : '';
      return [
        DetailSection('identity', [
          DetailEntry('name', name),
          DetailEntry('pref name', 'Jay'),
          DetailEntry('email', 'jane@x.com', valueColor: ColorSlot.fgAccent),
          DetailEntry('phone', '+1 555 0100'),
        ]),
        DetailSection('links', [
          DetailEntry('linkedin', '/in/$name'),
          DetailEntry('github', 'github.com/${name.toLowerCase().replaceAll(' ', '')}'),
          DetailEntry('portfolio', 'portfolio.xyz'),
        ]),
        DetailSection('counts', [
          DetailEntry('gigs', '3'),
          DetailEntry('assets', '5'),
        ]),
        DetailSection('tags', [
          DetailEntry('tags', '<license> <edu>'),
        ]),
      ];
    case ScreenId.jobreqs:
      final title = row.cells.isNotEmpty ? row.cells[0].text : '';
      return [
        DetailSection('identity', [
          DetailEntry('title', title),
          DetailEntry('concern', 'St. Mary\'s'),
          DetailEntry('location', 'Denver, CO'),
        ]),
        DetailSection('details', [
          DetailEntry('salary', '\$38 / hr'),
          DetailEntry('found', 'LinkedIn'),
        ]),
        DetailSection('content', [
          DetailEntry('req', 'RN with 2+ yrs pediatric experience. BLS/ACLS required. 12-hour shifts, nights. Contact HR for details.'),
        ]),
      ];
    case ScreenId.applications:
      final app = row.cells.isNotEmpty ? row.cells[0].text : '';
      return [
        DetailSection('identity', [
          DetailEntry('applicant', app),
          DetailEntry('job', 'RN - Pediatric'),
        ]),
        DetailSection('docs', [
          DetailEntry('resume', '✓', valueColor: ColorSlot.statusOk),
          DetailEntry('cover', '✓', valueColor: ColorSlot.statusOk),
          DetailEntry('feedback', '—'),
        ]),
      ];
    case ScreenId.gigs:
      final title = row.cells.isNotEmpty ? row.cells[0].text : '';
      return [
        DetailSection('identity', [
          DetailEntry('title', title),
          DetailEntry('concern', 'Denver Children\'s'),
          DetailEntry('location', 'Denver, CO'),
          DetailEntry('dates', '2021 - 2023'),
        ]),
        DetailSection('achievements', [
          DetailEntry('awards', 'Led pediatric intake team of 4; cut avg triage time 18%.'),
        ]),
      ];
    case ScreenId.assets:
      final content = row.cells.isNotEmpty ? row.cells[0].text : '';
      return [
        DetailSection('tags', [
          DetailEntry('tags', '<license>'),
        ]),
        DetailSection('content', [
          DetailEntry('content', content),
        ]),
      ];
  }
}

List<TableViewRow> _applicants() => [
      _row(['Jane Doe', 'matched', '0.92', '10m'], ColorSlot.statusOk),
      _row(['John Roe', 'pending', '0.61', '1h'], ColorSlot.statusWarn),
      _row(['Al Smith', 'failed', '0.44', '3h'], ColorSlot.statusErr),
      _row(['May Chen', 'matched', '0.88', '4h'], ColorSlot.statusOk),
      _row(['Ravi Patel', 'ready', '0.77', '6h'], ColorSlot.statusInfo),
      _row(['Kim Lee', 'pending', '0.59', '1d'], ColorSlot.statusWarn),
      _row(['Nina Ortiz', 'failed', '0.38', '2d'], ColorSlot.statusErr),
      _row(['Omar Haddad', 'matched', '0.91', '2d'], ColorSlot.statusOk),
      _row(['Sara Kim', 'ready', '0.70', '3d'], ColorSlot.statusInfo),
      _row(['Leo Martin', 'pending', '0.55', '4d'], ColorSlot.statusWarn),
    ];

List<TableViewRow> _jobreqs() => [
      _row(['RN - Pediatric', 'St. Mary\'s', '0.81', 'Denver']),
      _row(['ICU - Nights', 'Denver Health', '0.72', 'Aurora']),
      _row(['ER - Float', 'Presbyterian', '0.64', 'Denver']),
      _row(['OR - Circulator', 'UCHealth', '0.58', 'Boulder']),
      _row(['L&D - RN', 'Rose Medical', '0.49', 'Denver']),
      _row(['Psych - RN', 'Centennial', '0.41', 'Englewood']),
    ];

List<TableViewRow> _applications() => [
      _row(['Jane Doe', 'RN - Pediatric', '✓', 'Oct 8']),
      _row(['John Roe', 'ICU - Nights', '✓', 'Oct 6']),
      _row(['Al Smith', 'ER - Float', '—', 'Sep 30']),
      _row(['May Chen', 'OR - Circulator', '✓', 'Sep 27']),
      _row(['Ravi Patel', 'L&D - RN', '✓', 'Sep 22']),
    ];

List<TableViewRow> _gigs() => [
      _row(['Lead Pediatric RN', 'Denver Children\'s', '2021 - 2023']),
      _row(['Staff RN - ER', 'Aurora Medical', '2018 - 2021']),
      _row(['Float RN', 'Centura', '2015 - 2018']),
    ];

List<TableViewRow> _assets() => [
      _row(['BLS Certification', 'license']),
      _row(['ACLS Certification', 'license']),
      _row(['RN License - Colorado', 'license']),
      _row(['BSN - Nursing', 'education']),
      _row(['PALS Provider', 'certification']),
    ];

TableViewRow _row(List<String> vals, [ColorSlot? color]) =>
    TableViewRow([for (final v in vals) ViewCell(v)], rowColor: color);
