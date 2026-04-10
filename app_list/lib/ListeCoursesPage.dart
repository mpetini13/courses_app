import 'package:flutter/material.dart';
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

  String _construireTextePartage(List<Map<String, dynamic>> items) {
    final buffer = StringBuffer('🛒 Ma liste de courses\n\n');
    if (_triMode == TriMode.categorie) {
      final groupes = _grouperParCategorie(items);
      for (final cat in groupes.keys.toList()..sort()) {
        buffer.writeln('── $cat ──');
        for (final item in groupes[cat]!) {
          final q = item['quantite'] as double;
          final qStr =
          q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);
          buffer.writeln('  • ${item['nom']} — $qStr ${item['unite']}');
        }
        buffer.writeln();
      }
    } else {
      for (final item in items) {
        final q = item['quantite'] as double;
        final qStr =
        q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);
        buffer.writeln('• ${item['nom']} — $qStr ${item['unite']}');
      }
    }
    return buffer.toString();
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
            onPressed: () {
              final texte = _construireTextePartage(allItems);
              Share.share(texte, subject: 'Ma liste de courses');
            },
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