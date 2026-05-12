import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'class.dart';

enum TriMode { categorie, alphabetique, nonCoches }

class ListeCoursesPage extends StatefulWidget {
  final List<Recette> recettes;
  final Set<String> ingredientsExclus;
  const ListeCoursesPage({
    super.key,
    required this.recettes,
    required this.ingredientsExclus,
  });

  @override
  State<ListeCoursesPage> createState() => _ListeCoursesPageState();
}

class _ListeCoursesPageState extends State<ListeCoursesPage> {
  Set<String> _dansLeCaddie = {};
  TriMode _triMode = TriMode.categorie;

  Map<String, Map<String, dynamic>> _agreger() {
    Map<String, Map<String, dynamic>> agregat = {};
    for (final recette in widget.recettes) {
      for (final ing in recette.ingredients) {
        final cle = ing.nom.toLowerCase().trim();
        if (agregat.containsKey(cle)) {
          agregat[cle]!['quantite'] += ing.quantite;
        } else {
          agregat[cle] = {
            'nom': ing.nom,
            'quantite': ing.quantite,
            'unite': ing.unite,
            'categorie': ing.categorie,
          };
        }
      }
    }
    return agregat;
  }

  List<Map<String, dynamic>> _trierItems(
      List<Map<String, dynamic>> items) {
    switch (_triMode) {
      case TriMode.alphabetique:
        items.sort((a, b) =>
            (a['nom'] as String).compareTo(b['nom'] as String));
        break;
      case TriMode.nonCoches:
        items.sort((a, b) {
          final aCoche = _dansLeCaddie
              .contains((a['nom'] as String).toLowerCase().trim());
          final bCoche = _dansLeCaddie
              .contains((b['nom'] as String).toLowerCase().trim());
          if (aCoche && !bCoche) return 1;
          if (!aCoche && bCoche) return -1;
          return 0;
        });
        break;
      case TriMode.categorie:
        items.sort((a, b) =>
            (a['categorie'] as String).compareTo(b['categorie'] as String));
        break;
    }
    return items;
  }

  Map<String, List<Map<String, dynamic>>> _grouperParCategorie(
      List<Map<String, dynamic>> items) {
    Map<String, List<Map<String, dynamic>>> groupes = {};
    for (final item in items) {
      final cat = item['categorie'] as String;
      groupes.putIfAbsent(cat, () => []).add(item);
    }
    return groupes;
  }

  String _genererHtml(List<Map<String, dynamic>> items) {
    final groupes = _grouperParCategorie(items);
    final categories = groupes.keys.toList()..sort();

    final itemsHtml = StringBuffer();
    for (final cat in categories) {
      itemsHtml.writeln('<div class="cat"><span class="cat-label">$cat</span></div>');
      for (final item in groupes[cat]!) {
        final q = item['quantite'] as double;
        final qStr = q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);
        final id = '${item['nom']}_$cat'.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        itemsHtml.writeln('''
          <label class="item" for="$id">
            <input type="checkbox" id="$id" onchange="save()">
            <span class="nom">${item['nom']}</span>
            <span class="qty">$qStr ${item['unite']}</span>
          </label>''');
      }
    }

    final plats = widget.recettes.map((r) => r.nom).where((n) => n != 'Autres').join(', ');

    return '''<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Liste de courses</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: #f9f9f9; color: #222; max-width: 480px; margin: 0 auto; padding: 16px; }
    h1 { font-size: 22px; font-weight: 700; color: #e65100; margin-bottom: 4px; }
    .plats { font-size: 12px; color: #888; margin-bottom: 20px; }
    .progress { background: #ffe0b2; border-radius: 6px; height: 8px; margin-bottom: 20px; overflow: hidden; }
    .progress-bar { background: #ff6f00; height: 100%; border-radius: 6px; transition: width 0.3s; }
    .progress-label { font-size: 12px; color: #888; margin-bottom: 6px; text-align: right; }
    .cat { margin-top: 18px; margin-bottom: 6px; }
    .cat-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #aaa; }
    .item { display: flex; align-items: center; background: #fff; border-radius: 12px; padding: 12px 14px; margin-bottom: 6px; cursor: pointer; box-shadow: 0 1px 3px rgba(0,0,0,.06); transition: opacity .2s; }
    .item input { display: none; }
    .item::before { content: ""; width: 22px; height: 22px; border: 2px solid #ddd; border-radius: 50%; margin-right: 12px; flex-shrink: 0; transition: all .2s; }
    .item.done { opacity: 0.45; }
    .item.done::before { background: #4caf50; border-color: #4caf50; content: "✓"; color: white; font-size: 13px; display: flex; align-items: center; justify-content: center; }
    .nom { flex: 1; font-size: 15px; }
    .qty { font-size: 13px; color: #aaa; margin-left: 8px; }
    .reset { display: block; margin-top: 24px; text-align: center; font-size: 13px; color: #ff6f00; background: none; border: 1px solid #ff6f00; border-radius: 10px; padding: 10px; cursor: pointer; width: 100%; }
  </style>
</head>
<body>
  <h1>🛒 Liste de courses</h1>
  <p class="plats">$plats</p>
  <p class="progress-label" id="lbl"></p>
  <div class="progress"><div class="progress-bar" id="bar"></div></div>
  <div id="liste">$itemsHtml</div>
  <button class="reset" onclick="reset()">Tout décocher</button>
  <script>
    const KEY = 'courses_v1';
    function ids() { return [...document.querySelectorAll('input[type=checkbox]')].map(i => i.id); }
    function save() {
      const checked = [...document.querySelectorAll('input:checked')].map(i => i.id);
      localStorage.setItem(KEY, JSON.stringify(checked));
      update();
    }
    function load() {
      const checked = JSON.parse(localStorage.getItem(KEY) || '[]');
      checked.forEach(id => { const el = document.getElementById(id); if(el) el.checked = true; });
      update();
    }
    function update() {
      document.querySelectorAll('.item').forEach(item => {
        item.classList.toggle('done', item.querySelector('input').checked);
      });
      const total = ids().length, done = document.querySelectorAll('input:checked').length;
      document.getElementById('lbl').textContent = done + ' / ' + total;
      document.getElementById('bar').style.width = (total ? done/total*100 : 0) + '%';
    }
    function reset() { document.querySelectorAll('input').forEach(i => i.checked = false); save(); }
    load();
  </script>
</body>
</html>''';
  }

  Future<void> _partager(List<Map<String, dynamic>> items) async {
    final html = _genererHtml(items);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/liste_courses.html');
    await file.writeAsString(html);
    await Share.shareXFiles([XFile(file.path)], subject: 'Ma liste de courses');
  }

  @override
  Widget build(BuildContext context) {
    final agregat = _agreger();
    final allItems = _trierItems(agregat.values.toList());
    final total = allItems.length;
    final achetes = _dansLeCaddie.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma liste de courses'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _partager(allItems),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Plats : ${widget.recettes.map((r) => r.nom).where((n) => n != 'Autres').join(', ')}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$achetes / $total',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? achetes / total : 0,
                    backgroundColor: Colors.orange.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.orange),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Sélecteur de tri
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _TriChip(
                  label: 'Catégorie',
                  icon: Icons.category,
                  selected: _triMode == TriMode.categorie,
                  onTap: () =>
                      setState(() => _triMode = TriMode.categorie),
                ),
                const SizedBox(width: 8),
                _TriChip(
                  label: 'A → Z',
                  icon: Icons.sort_by_alpha,
                  selected: _triMode == TriMode.alphabetique,
                  onTap: () =>
                      setState(() => _triMode = TriMode.alphabetique),
                ),
                const SizedBox(width: 8),
                _TriChip(
                  label: 'À faire',
                  icon: Icons.radio_button_unchecked,
                  selected: _triMode == TriMode.nonCoches,
                  onTap: () =>
                      setState(() => _triMode = TriMode.nonCoches),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: _triMode == TriMode.categorie
                ? _buildListeParCategorie(allItems)
                : _buildListeFlat(allItems),
          ),
        ],
      ),
    );
  }

  Widget _buildListeParCategorie(List<Map<String, dynamic>> items) {
    final groupes = _grouperParCategorie(items);
    final categories = groupes.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: categories.length,
      itemBuilder: (context, catIndex) {
        final cat = categories[catIndex];
        final catItems = groupes[cat]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(cat,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
            ...catItems.map((item) => _buildTile(item)),
            const Divider(indent: 16, endIndent: 16),
          ],
        );
      },
    );
  }

  Widget _buildListeFlat(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildTile(items[index]),
    );
  }

  Widget _buildTile(Map<String, dynamic> item) {
    final cle = (item['nom'] as String).toLowerCase().trim();
    final coche = _dansLeCaddie.contains(cle);
    final q = item['quantite'] as double;
    final qStr =
    q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        coche ? Icons.check_circle : Icons.radio_button_unchecked,
        color: coche ? Colors.green : Colors.grey.shade400,
      ),
      title: Text(
        item['nom'],
        style: TextStyle(
          fontSize: 15,
          decoration: coche ? TextDecoration.lineThrough : null,
          color: coche ? Colors.grey.shade400 : Colors.black87,
        ),
      ),
      trailing: Text(
        '$qStr ${item['unite']}',
        style: TextStyle(
          fontSize: 14,
          color: coche ? Colors.grey.shade400 : Colors.grey.shade700,
          decoration: coche ? TextDecoration.lineThrough : null,
        ),
      ),
      onTap: () {
        setState(() {
          if (coche) {
            _dansLeCaddie.remove(cle);
          } else {
            _dansLeCaddie.add(cle);
          }
        });
      },
    );
  }
}

class _TriChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TriChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.orange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.orange
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}