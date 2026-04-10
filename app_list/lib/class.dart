import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

// Classe Ingredient
class Ingredient {
  final String nom;
  double quantite;
  final String unite;
  final String categorie;

  Ingredient({
    required this.nom,
    required this.quantite,
    required this.unite,
    required this.categorie,
  });
}

// Classe Recette
class Recette {
  final String nom;
  final List<Ingredient> ingredients;
  final String image;

  Recette({
    required this.nom,
    required this.ingredients,
    required this.image,
  });
}