// Imports SMT IV data from aqiu384/megaten-fusion-tool (Unlicense) and writes
// decoded, readable JSON into assets/data/smt4/.
//
// Usage:
//   dart run tool/import_smt4.dart                 # downloads the pinned commit
//   dart run tool/import_smt4.dart --from <clone>  # reads a local clone instead
//
// The upstream files are compact and partly unlabeled. This script decodes them
// once so the app and fusion_core only ever see labeled fields. If the upstream
// shape changes, this script fails loudly instead of writing bad data.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const upstreamRepo = 'aqiu384/megaten-fusion-tool';
const upstreamCommit = '0b207612f6cdcff092e62af16f5c355271a1d892';
const upstreamDir = 'src/app/smt4/data';
const outDir = 'assets/data/smt4';

const files = [
  'comp-config.json',
  'demon-data.json',
  'enemy-data.json',
  'skill-data.json',
  'fusion-chart.json',
  'element-chart.json',
  'special-recipes.json',
  'fusion-prereqs.json',
  'demon-unlocks.json',
  'evolutions.json',
  'alignments.json',
  'affinity-bonuses.json',
];

Future<void> main(List<String> args) async {
  final fromIndex = args.indexOf('--from');
  final localDir = fromIndex >= 0 ? args[fromIndex + 1] : null;

  final raw = <String, dynamic>{};
  for (final f in files) {
    final text = localDir != null
        ? await File('$localDir/$upstreamDir/$f').readAsString()
        : await _download(
            'https://raw.githubusercontent.com/$upstreamRepo/$upstreamCommit/$upstreamDir/$f');
    raw[f] = jsonDecode(text);
  }

  final config = raw['comp-config.json'] as Map<String, dynamic>;
  final resistElems = (config['resistElems'] as List).cast<String>();
  final ailmentNames = (config['ailments'] as List).cast<String>();
  final resistCodes = (config['resistCodes'] as Map).cast<String, num>();
  final resistRankPrices = (config['resistRankPrices'] as List).cast<num>();
  final skillRankPrices = (config['skillRankPrices'] as List).cast<num>();
  final races = (config['races'] as List).cast<String>();

  // ---- skills -------------------------------------------------------------
  // Upstream row: a = [name, element, target], b = [rank, cost, power, minHits,
  // maxHits, accuracy, crit, modifier], c = [effect, condition, skillCard].
  // Rank >= 900 marks a unique skill (cannot be inherited).
  final skills = <String, Map<String, dynamic>>{};
  final skillPrices = <String, num>{};
  final skillRows = (raw['skill-data.json'] as Map).values;
  for (final row in skillRows) {
    final a = (row['a'] as List).cast<String>();
    final b = (row['b'] as List).cast<num>();
    final c = (row['c'] as List).cast<String>();
    _require(a.length == 3 && b.length == 8 && c.length == 3,
        'unexpected skill row shape for ${a.first}');
    final name = a[0];
    final rawRank = b[0].toInt();
    final unique = rawRank > 900;
    final rank = unique ? rawRank - 900 : (rawRank == 99 ? 0 : rawRank);
    skillPrices[name] = skillRankPrices[rank.clamp(0, skillRankPrices.length - 1)];
    final rawCost = b[1].toInt();
    // Upstream encodes MP skills as 1000 + mp (then adds a UI-only type tag).
    final costMp = rawCost == 0 ? 0 : rawCost - 1000;
    final acc = b[5].toInt();
    skills[name] = {
      'name': name,
      'element': a[1],
      'target': a[2] == '-' ? 'Self' : a[2],
      'rank': rawRank == 99 ? 99 : rank,
      'unique': unique,
      'costMp': costMp,
      'power': b[2].toInt(),
      'minHits': b[3].toInt(),
      'maxHits': b[4].toInt(),
      'accuracy': acc == 120 ? 110 : acc,
      'crit': b[6].toInt(),
      'modifier': b[7],
      'effect': c[0],
      'condition': c[1],
      'skillCard': c[2] == '-' ? null : c[2],
    };
  }

  // ---- demons -------------------------------------------------------------
  final alignments = (raw['alignments.json'] as Map).cast<String, String>();
  final prereqs = (raw['fusion-prereqs.json'] as Map).cast<String, String>();
  final specials = (raw['special-recipes.json'] as Map)
      .map((k, v) => MapEntry(k as String, (v as List).cast<String>()));
  final evolutions = (raw['evolutions.json'] as Map).cast<String, dynamic>();
  final unlockSets = (raw['demon-unlocks.json'] as List).cast<Map>();

  final unlockCategory = <String, String>{};
  final unlockCondition = <String, String>{};
  final unlocks = <Map<String, dynamic>>[];
  for (final set in unlockSets) {
    final category = set['category'] as String;
    final conds = (set['conditions'] as Map).cast<String, String>();
    final entries = <Map<String, dynamic>>[];
    for (final e in conds.entries) {
      final names = e.key.split(',');
      entries.add({'demons': names, 'condition': e.value});
      for (final n in names) {
        unlockCategory[n] = category;
        unlockCondition[n] = e.value;
      }
    }
    unlocks.add({
      'category': category,
      'enabledByDefault': set['unlocked'] as bool,
      'entries': entries,
    });
  }

  final demons = <String, Map<String, dynamic>>{};
  final demonRows = (raw['demon-data.json'] as Map).cast<String, dynamic>();
  for (final entry in demonRows.entries) {
    final name = entry.key;
    final d = entry.value as Map<String, dynamic>;
    final lvl = (d['lvl'] as num).floor();
    final baseStats = (d['stats'] as List).cast<num>();
    _require(baseStats.length == 9, 'unexpected stats for $name');
    // Upstream: stats = [hpBase, mpBase, hpGrowth, mpGrowth, st, dx, ma, ag, lu]
    final hp = baseStats[0] + lvl * baseStats[2];
    final mp = (0.45 * (baseStats[1] + lvl * baseStats[3])).floor();
    final stats = {
      'hp': hp.toInt(),
      'mp': mp,
      'st': baseStats[4].toInt(),
      'dx': baseStats[5].toInt(),
      'ma': baseStats[6].toInt(),
      'ag': baseStats[7].toInt(),
      'lu': baseStats[8].toInt(),
    };
    final resistStr = d['resists'] as String;
    _require(resistStr.length == resistElems.length, 'resists for $name');
    final resists = <String, String>{};
    for (var i = 0; i < resistElems.length; i++) {
      resists[resistElems[i]] = _resistLabel(resistStr[i]);
    }
    final ailStr = (d['ailments'] as String?) ?? '-' * ailmentNames.length;
    final ailments = <String, String>{};
    for (var i = 0; i < ailmentNames.length; i++) {
      ailments[ailmentNames[i].toLowerCase()] = _resistLabel(ailStr[i]);
    }
    final skillMap = (d['skills'] as Map).cast<String, num>();
    final skillList = skillMap.entries.map((e) {
      _require(skills.containsKey(e.key), 'unknown skill ${e.key} on $name');
      // < 2 means innate (0.1, 0.2 ... keep order), otherwise learned at level.
      return {'name': e.key, 'level': e.value < 2 ? 0 : e.value.toInt()};
    }).toList();

    // Macca price, ported from upstream updateComputedDemon (then x2 in Compendium).
    final hpPrice = _pow15(hp / 2);
    final mpPrice = _pow15(mp / 2);
    final statSum = baseStats.sublist(4).fold<num>(0, (a, b) => a + b);
    final statPrice = _pow15(statSum.toDouble());
    final innatePrice = skillMap.entries
        .where((e) => e.value < 2)
        .fold<num>(0, (acc, e) => acc + skillPrices[e.key]!);
    final resistRankSum = resistStr
        .split('')
        .map((r) => (resistCodes[r]! / 1000).floor())
        .fold<num>(0, (acc, i) => acc + resistRankPrices[i]);
    final resistPrice = lvl * resistRankSum * resistRankSum;
    final price =
        ((hpPrice + mpPrice + statPrice + innatePrice + resistPrice) / 2).floor() * 2;

    final race = d['race'] as String;
    final align = alignments[name] ?? alignments[race] ?? 'Neutral-Neutral';
    final prereq = prereqs[name];
    String fusion;
    if (specials.containsKey(name)) {
      fusion = specials[name]!.isEmpty ? 'accident' : 'special';
    } else if (prereq != null && prereq.contains('Fusion Accident')) {
      fusion = 'accident';
    } else {
      fusion = 'normal';
    }

    demons[name] = {
      'name': name,
      'race': race,
      'level': lvl,
      'alignment': align,
      'stats': stats,
      'resists': resists,
      'ailments': ailments,
      'skills': skillList,
      'price': price,
      'fusion': fusion,
      'prereq': prereq ?? unlockCondition[name],
      'unlockCategory': unlockCategory[name],
      'specialRecipe': specials[name],
      'evolvesTo': evolutions[name]?['result'],
      'evolvesAtLevel': evolutions[name]?['lvl'],
    };
  }
  for (final e in evolutions.entries) {
    final result = e.value['result'] as String;
    _require(demons.containsKey(result), 'evolution result $result missing');
    demons[result]!['evolvesFrom'] = e.key;
  }

  // Enemy-only demons: listed in the compendium but never fusable or recruitable.
  final enemyRows = (raw['enemy-data.json'] as Map).cast<String, dynamic>();
  for (final entry in enemyRows.entries) {
    final d = entry.value as Map<String, dynamic>;
    final s = (d['stats'] as List).cast<num>();
    demons[entry.key] = {
      'name': entry.key,
      'race': d['race'],
      'level': (d['lvl'] as num).floor(),
      'alignment': alignments[d['race']] ?? 'Neutral-Neutral',
      'stats': {
        'hp': s[0].toInt(), 'mp': s[1].toInt(), 'st': s[2].toInt(), 'dx': s[3].toInt(),
        'ma': s[4].toInt(), 'ag': s[5].toInt(), 'lu': s[6].toInt(),
      },
      'resists': {
        for (var i = 0; i < resistElems.length; i++)
          resistElems[i]: _resistLabel((d['resists'] as String)[i])
      },
      'ailments': {
        for (var i = 0; i < ailmentNames.length; i++)
          ailmentNames[i].toLowerCase(): _resistLabel((d['ailments'] as String)[i])
      },
      'skills': [for (final n in (d['eskills'] as List)) {'name': n, 'level': 0}],
      'price': 0,
      'fusion': 'enemy',
      'prereq': 'Enemy only',
    };
  }

  // ---- fusion chart --------------------------------------------------------
  // Upstream table is lower-triangular: row r lists results for races[r] x
  // races[0..r]. We expand it to a full symmetric map.
  final chart = raw['fusion-chart.json'] as Map<String, dynamic>;
  final chartRaces = (chart['races'] as List).cast<String>();
  final table = (chart['table'] as List).cast<List>();
  final fusionTable = <String, Map<String, String>>{};
  for (var r = 0; r < table.length; r++) {
    for (var c = 0; c < table[r].length; c++) {
      final result = table[r][c] as String;
      if (result == '-') continue;
      fusionTable.putIfAbsent(chartRaces[r], () => {})[chartRaces[c]] = result;
      fusionTable.putIfAbsent(chartRaces[c], () => {})[chartRaces[r]] = result;
    }
  }
  final elem = raw['element-chart.json'] as Map<String, dynamic>;
  final elemNames = (elem['elems'] as List).cast<String>();
  final elemRaces = (elem['races'] as List).cast<String>();
  final elemTable = (elem['table'] as List).cast<List>();
  final elementModifiers = <String, Map<String, int>>{};
  for (var r = 0; r < elemRaces.length; r++) {
    for (var c = 0; c < elemNames.length; c++) {
      final m = (elemTable[r][c] as num).toInt();
      if (m != 0) elementModifiers.putIfAbsent(elemRaces[r], () => {})[elemNames[c]] = m;
    }
  }

  final out = Directory(outDir)..createSync(recursive: true);
  const enc = JsonEncoder.withIndent(' ');
  void write(String name, Object data) =>
      File('${out.path}/$name').writeAsStringSync('${enc.convert(data)}\n');

  write('meta.json', {
    'game': 'smt4',
    'title': 'Shin Megami Tensei IV',
    'source': 'https://github.com/$upstreamRepo',
    'sourceLicense': 'Unlicense',
    'sourceCommit': upstreamCommit,
    'importedAt': DateTime.now().toUtc().toIso8601String(),
    'races': races,
    'resistElements': resistElems,
    'ailments': ailmentNames.map((a) => a.toLowerCase()).toList(),
    'elementDemons': elemNames,
    'maxSkillSlots': 8,
  });
  write('demons.json', demons.values.toList()..sort(_byRaceThenLevel(races)));
  write('skills.json', skills.values.toList()..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String)));
  write('fusion_chart.json', {'races': chartRaces, 'table': fusionTable});
  write('element_chart.json', {'elements': elemNames, 'modifiers': elementModifiers});
  write('unlocks.json', unlocks);
  write('affinity_bonuses.json', raw['affinity-bonuses.json']);

  stdout.writeln('Wrote ${demons.length} demons, ${skills.length} skills, '
      '${specials.length} special recipes to $outDir (upstream $upstreamCommit).');
}

int Function(Map<String, dynamic>, Map<String, dynamic>) _byRaceThenLevel(List<String> races) {
  final order = {for (var i = 0; i < races.length; i++) races[i]: i};
  return (a, b) {
    final r = (order[a['race']] ?? 999).compareTo(order[b['race']] ?? 999);
    if (r != 0) return r;
    return (a['level'] as int).compareTo(b['level'] as int);
  };
}

String _resistLabel(String code) {
  switch (code) {
    case '-': return 'none';
    case 'w': return 'weak';
    case 'W': return 'weak';
    case 'X': return 'weak'; // extra-weak ailment code
    case 's': return 'resist';
    case 'n': return 'null';
    case 'r': return 'repel';
    case 'd': return 'drain';
    default: throw StateError('unknown resist code "$code"');
  }
}

num _pow15(double x) => pow(x, 1.5).floor();

void _require(bool ok, String message) {
  if (!ok) throw StateError('import failed: $message');
}

Future<String> _download(String url) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close();
    _require(res.statusCode == 200, 'GET $url -> ${res.statusCode}');
    return await res.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}
