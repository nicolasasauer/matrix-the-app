import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Short rules for new players.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.table,
      appBar: AppBar(title: const Text(AppStrings.rulesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _p('In der Mitte des 5 × 5 Felds liegt eine Startkarte. Reihum legt '
              'ihr Karten an: Wer dran ist, wählt ein freies Feld neben einer '
              'liegenden Karte und tippt, was gezogen wird.'),
          _h('Was getippt wird'),
          _p('Das hängt davon ab, wie viele Karten direkt neben dem Feld '
              'liegen (oben, unten, links, rechts). Die Zahl steht klein im '
              'freien Feld.'),
          const _NeighborTable(),
          _p('Ass ist die höchste Karte, 2 die niedrigste. Gleich hoch zählt '
              'weder als höher noch als niedriger.'),
          _h('Richtig getippt'),
          _p('Die Karte bleibt liegen und du tippst weiter. Nach 3 Treffern '
              'entscheidest du: sichern und weitergeben oder weiterspielen. '
              'Jedes weitere 3er-Set erhöht den Pegel, den der nächste Spieler '
              'bekommt, um 1.'),
          _h('Falsch getippt'),
          _p('Die ganze Zeile und Spalte des Felds wird abgeräumt. Du trinkst '
              'so viele Schlücke, wie Karten abgeräumt werden, mal deinem '
              'Pegel. Danach fällt der Pegel auf 1x. Die abgeräumten Karten '
              'kommen zurück in den Stapel, und der Stapel wird einmal '
              'gemischt.'),
          _h('Streak-Multiplikator (Hausregel)'),
          _p('Ist er aktiv, steigt der Pegel mit jeder fehlerfreien Weitergabe '
              'um 1: 2x, 3x, 4x … bis jemand einen Fehler macht.'),
          _h('Stapel & Mitspieler'),
          _p('Der Stapel behält seine Reihenfolge, bis jemand oben auf '
              '„Mischen“ tippt – das geht jederzeit. Über das Menü (⋮) lassen '
              'sich Spieler auch mitten im Spiel hinzufügen, entfernen, '
              'umsortieren oder aussetzen lassen.'),
          _h('Spielende'),
          _p('Das Spiel endet, wenn alle 25 Felder belegt sind – dann habt '
              'ihr die Matrix geschafft – oder wenn ihr es über das Menü (⋮) '
              '„Spiel beenden“ auswertet. Wer die wenigsten Schlücke hat, '
              'gewinnt.'),
        ],
      ),
    );
  }

  static Widget _h(String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 6),
        child: Text(text, style: AppText.display(18, weight: 700)),
      );

  static Widget _p(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: AppText.body(14.5, color: AppColors.fg, height: 1.5)),
      );
}

class _NeighborTable extends StatelessWidget {
  const _NeighborTable();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('1', 'Höher oder niedriger als der Nachbar'),
      ('2', 'Dazwischen oder außerhalb der beiden Werte'),
      ('3', 'Hat eine der Farben der Nachbarn – oder keine'),
      ('4', 'Die genaue Farbe: ♥ ♠ ♦ ♣'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final (n, text) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(n,
                        style: AppText.mono(15,
                            weight: 700, color: AppColors.amber)),
                  ),
                  Expanded(child: Text(text, style: AppText.body(13.5))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
