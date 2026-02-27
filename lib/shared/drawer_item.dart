import 'package:flutter/material.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Function? onPressed;

  const DrawerItem({super.key, required this.title, required this.icon, this.onPressed });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      /// Appelle la fonction seulement quand on clique
      onTap: () {
        if (onPressed != null) onPressed!();
      },
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}