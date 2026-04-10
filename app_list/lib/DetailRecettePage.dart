import 'package:flutter/material.dart';
import 'class.dart';

class DetailRecettePage extends StatefulWidget {
  final Recette recette;
  const DetailRecettePage({super.key, required this.recette});

  @override
  State<DetailRecettePage> createState() => _DetailRecettePageState();
}

class _DetailRecettePageState extends State<DetailRecettePage> {
  // Ingrédients déjà cochés (déjà à la maison)
  Set<String> _dejaDisponibles = {};

  void _toggleIngredient(String nom) {
    setState(() {
      if (_dejaDisponibles.contains(nom)) {
        _dejaDisponibles.remove(nom);
      } else {
        _dejaDisponibles.add(nom);
      }
    });
  }

  // Couleur par catégorie
  Color _couleurCategorie(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'viande':       return Colors.red.shade100;
      case 'légumes':      return Colors.green.shade100;
      case 'féculents':    return Colors.amber.shade100;
      case 'fromage':      return Colors.yellow.shade100;
      case 'charcuterie':  return Colors.orange.shade100;
      default:             return Colors.grey.shade100;
    }
  }

  IconData _iconeCategorie(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'viande':       return Icons.lunch_dining;
      case 'légumes':      return Icons.eco;
      case 'féculents':    return Icons.grain;
      case 'fromage':      return Icons.breakfast_dining;
      case 'charcuterie':  return Icons.set_meal;
      default:             return Icons.kitchen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recette = widget.recette;
    final restants = recette.ingredients.length - _dejaDisponibles.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar avec image en arrière-plan
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(recette.nom,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    recette.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.orange.shade200,
                      child: const Icon(Icons.restaurant,
                          size: 80, color: Colors.white),
                    ),
                  ),
                  // Dégradé pour lisibilité du titre
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Résumé
                  Row(
                    children: [
                      _StatChip(
                        label: '${recette.ingredients.length} ingrédients',
                        icon: Icons.list_alt,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        label: '$restants à acheter',
                        icon: Icons.shopping_basket,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Ingrédients',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Coche ce que tu as déjà',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Liste des ingrédients
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final ing = recette.ingredients[index];
                final dispo = _dejaDisponibles.contains(ing.nom);

                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _toggleIngredient(ing.nom),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: dispo
                            ? Colors.grey.shade100
                            : _couleurCategorie(ing.categorie),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dispo
                              ? Colors.grey.shade300
                              : Colors.transparent,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Icône catégorie
                          Icon(
                            _iconeCategorie(ing.categorie),
                            size: 22,
                            color: dispo
                                ? Colors.grey.shade400
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 12),
                          // Nom
                          Expanded(
                            child: Text(
                              ing.nom,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: dispo
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                                decoration: dispo
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          // Quantité + unité
                          Text(
                            '${ing.quantite % 1 == 0 ? ing.quantite.toInt() : ing.quantite} ${ing.unite}',
                            style: TextStyle(
                              fontSize: 14,
                              color: dispo
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                              decoration:
                              dispo ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Checkbox
                          Icon(
                            dispo
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: dispo ? Colors.green : Colors.grey.shade400,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: recette.ingredients.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

// Widget chip d'info
class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _StatChip(
      {required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(label,
              style:
              TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}