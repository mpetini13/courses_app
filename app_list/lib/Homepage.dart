import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'class.dart';
import 'ListeCoursesPage.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final List<Recette> recettes;
  const HomePage({super.key, required this.recettes});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<String> _ingredientsCoches = {};
  String _recherche = '';
  List<String> _autresArticles = [];
  Map<String, int> _nbPersonnesParPlat = {};
  int _nbPersonnes(String nomPlat) => _nbPersonnesParPlat[nomPlat] ?? 2;
  final TextEditingController _rechercheController = TextEditingController();
  final TextEditingController _autreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerPreferences();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    _autreController.dispose();
    super.dispose();
  }

  // Sauvegarde
  Future<void> _sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'ingredientsCoches', _ingredientsCoches.toList());
    await prefs.setStringList('autresArticles', _autresArticles);
    await prefs.setString('nbPersonnesParPlat', jsonEncode(_nbPersonnesParPlat));
  }

  // Chargement
  Future<void> _chargerPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ingredientsCoches =
          (prefs.getStringList('ingredientsCoches') ?? []).toSet();
      _autresArticles = prefs.getStringList('autresArticles') ?? [];
      final nbPersonnesJson = prefs.getString('nbPersonnesParPlat') ?? '{}';
      _nbPersonnesParPlat = Map<String, int>.from(jsonDecode(nbPersonnesJson));
    });
  }

  void _toggleIngredient(String cle) {
    setState(() {
      if (_ingredientsCoches.contains(cle)) {
        _ingredientsCoches.remove(cle);
      } else {
        _ingredientsCoches.add(cle);
      }
    });
    HapticFeedback.lightImpact(); // <-- ajoute ça
    _sauvegarder();
  }

  void _toutDecocher() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tout décocher ?'),
        content: const Text(
            'Ça va remettre à zéro tous les ingrédients et articles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _ingredientsCoches.clear();
                _autresArticles.clear();
              });
              _sauvegarder();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _genererCourses() {
    if (_ingredientsCoches.isEmpty && _autresArticles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Coche au moins un ingrédient ou ajoute un article !')),
      );
      return;
    }

    List<Recette> recettesFiltrees = [];
    for (final recette in widget.recettes) {
      final nb = _nbPersonnes(recette.nom);
      final ingredientsCochesDeCetteRecette = recette.ingredients
          .where((ing) =>
          _ingredientsCoches.contains('${recette.nom}__${ing.nom}'))
          .map((ing) => Ingredient(
        nom: ing.nom,
        quantite: ing.quantite * nb / 2,
        unite: ing.unite,
        categorie: ing.categorie,
      ))
          .toList();
      if (ingredientsCochesDeCetteRecette.isNotEmpty) {
        recettesFiltrees.add(Recette(
          nom: recette.nom,
          ingredients: ingredientsCochesDeCetteRecette,
          image: recette.image,
        ));
      }
    }

    if (_autresArticles.isNotEmpty) {
      recettesFiltrees.add(Recette(
        nom: 'Autres',
        ingredients: _autresArticles
            .map((a) => Ingredient(
          nom: a,
          quantite: 1,
          unite: '',
          categorie: 'Autre',
        ))
            .toList(),
        image: '',
      ));
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ListeCoursesPage(
          recettes: recettesFiltrees,
          ingredientsExclus: {},
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showIngredients(BuildContext context, Recette recette) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poignée
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  color: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              recette.image,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 52,
                                height: 52,
                                color: Colors.orange.shade200,
                                child: const Icon(Icons.restaurant, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recette.nom,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Sélecteur nombre de personnes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text('Personnes :',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (_nbPersonnes(recette.nom) > 1) {
                                setState(() => _nbPersonnesParPlat[recette.nom] =
                                    _nbPersonnes(recette.nom) - 1);
                                setModalState(() {});
                                _sauvegarder();
                              }
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_nbPersonnes(recette.nom)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() => _nbPersonnesParPlat[recette.nom] =
                                  _nbPersonnes(recette.nom) + 1);
                              setModalState(() {});
                              _sauvegarder();
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Text(
                    'Coche les ingrédients à acheter',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                ),
                const Divider(),

                // Ingrédients
                ...recette.ingredients.map((ing) {
                  final cle = '${recette.nom}__${ing.nom}';
                  final coche = _ingredientsCoches.contains(cle);
                  // Quantité ajustée au nombre de personnes
                  final qAjustee = ing.quantite * _nbPersonnes(recette.nom) / 2;
                  final qStr = qAjustee % 1 == 0
                      ? qAjustee.toInt().toString()
                      : qAjustee.toStringAsFixed(1);

                  return InkWell(
                    onTap: () {
                      setState(() => _toggleIngredient(cle));
                      setModalState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      color: coche
                          ? Colors.orange.shade50
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            coche
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 22,
                            color: coche
                                ? Colors.orange
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              ing.nom,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: coche
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: coche
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Text(
                            '$qStr ${ing.unite}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nbCoches = _ingredientsCoches.length;
    final recettesFiltrees = widget.recettes
        .where((r) => r.nom.toLowerCase().contains(_recherche))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🍽 Mes recettes'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Sélecteur nombre de personnes
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
            ),
          ),
          // Bouton tout décocher
          if (nbCoches > 0 || _autresArticles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Tout décocher',
              onPressed: _toutDecocher,
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _rechercheController,
              onChanged: (val) =>
                  setState(() => _recherche = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Rechercher un plat...',
                prefixIcon:
                const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _recherche.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _rechercheController.clear();
                    setState(() => _recherche = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Autres articles
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _autreController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText:
                          'Ajouter un article (ex: sac poubelle)...',
                          prefixIcon: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.orange,
                              size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              _autresArticles.add(val.trim());
                              _autreController.clear();
                            });
                            _sauvegarder();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (_autreController.text.trim().isNotEmpty) {
                          setState(() {
                            _autresArticles
                                .add(_autreController.text.trim());
                            _autreController.clear();
                          });
                          _sauvegarder();
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (_autresArticles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _autresArticles.map((article) {
                      return Chip(
                        label: Text(article,
                            style: const TextStyle(fontSize: 12)),
                        deleteIcon:
                        const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(
                                  () => _autresArticles.remove(article));
                          _sauvegarder();
                        },
                        backgroundColor: Colors.orange.shade50,
                        side:
                        BorderSide(color: Colors.orange.shade200),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Grille des recettes
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: recettesFiltrees.length,
              itemBuilder: (context, index) {
                final recette = recettesFiltrees[index];
                final nbCochesRecette = recette.ingredients
                    .where((ing) => _ingredientsCoches
                    .contains('${recette.nom}__${ing.nom}'))
                    .length;

                return GestureDetector(
                  onTap: () => _showIngredients(context, recette),
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          color: nbCochesRecette > 0
                              ? Colors.orange.shade700
                              : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  recette.nom,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (nbCochesRecette > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$nbCochesRecette',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              const Icon(Icons.expand_more,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Image.asset(
                            recette.image,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.orange.shade50,
                              child: const Icon(Icons.restaurant,
                                  size: 36, color: Colors.orange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Barre du bas
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (nbCoches > 0 || _autresArticles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      [
                        if (nbCoches > 0)
                          '$nbCoches ingrédient${nbCoches > 1 ? 's' : ''}',
                        if (_autresArticles.isNotEmpty)
                          '${_autresArticles.length} autre${_autresArticles.length > 1 ? 's' : ''}',
                      ].join(' + '),
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _genererCourses,
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Générer mes courses'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (nbCoches > 0)
                      Positioned(
                        top: -8,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '$nbCoches',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}