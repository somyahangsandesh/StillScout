class VerdictGenerator {
  VerdictGenerator._();

  static String generate({
    required int runsScored,
    required int ballsFaced,
    required double seasonBatAvg,
    required double seasonBatSR,
    required int wicketsTaken,
    required double runsConceeded,
    required int oversBowled,
    required double seasonEconomy,
    required double ovrChange,
    required int runsToMilestone,
    required String milestoneLabel,
  }) {
    final lines = <String>[];

    // Batting verdict
    if (ballsFaced >= 6) {
      final sr = ballsFaced > 0 ? (runsScored / ballsFaced * 100) : 0.0;
      if (runsScored >= 50) {
        lines.add('Outstanding innings — $runsScored from $ballsFaced balls.');
      } else if (runsScored >= 25 && sr > seasonBatSR * 1.1) {
        lines.add(
            'Solid with the bat. $runsScored at SR ${sr.toStringAsFixed(0)} — ${((sr / seasonBatSR - 1) * 100).abs().toStringAsFixed(0)}% above your season average.');
      } else if (runsScored < 15) {
        lines.add('Quiet day with the bat. $runsScored from $ballsFaced balls.');
      } else {
        lines.add('Useful innings. $runsScored from $ballsFaced balls.');
      }
    }

    // Bowling verdict
    if (oversBowled >= 2) {
      final econ = oversBowled > 0 ? runsConceeded / oversBowled : 0.0;
      if (wicketsTaken >= 3) {
        lines.add(
            'Excellent with the ball — $wicketsTaken wickets at ${econ.toStringAsFixed(1)}/over.');
      } else if (wicketsTaken >= 1 && econ < seasonEconomy) {
        lines.add(
            'Effective bowling. $wicketsTaken wicket${wicketsTaken > 1 ? 's' : ''}, economy ${econ.toStringAsFixed(1)} against your season average of ${seasonEconomy.toStringAsFixed(1)}.');
      } else if (econ > seasonEconomy * 1.2) {
        lines.add(
            'Tough day bowling. Went at ${econ.toStringAsFixed(1)}/over against your average of ${seasonEconomy.toStringAsFixed(1)}.');
      }
    }

    // OVR change line
    if (ovrChange > 1.5) {
      lines.add(
          'OVR up ${ovrChange.toStringAsFixed(1)} — your best contribution this season.');
    } else if (ovrChange > 0) {
      lines.add('OVR up ${ovrChange.toStringAsFixed(1)} points.');
    } else if (ovrChange < -1) {
      lines.add(
          'OVR down ${ovrChange.abs().toStringAsFixed(1)} points. Form is dropping.');
    }

    // Milestone approach
    if (runsToMilestone > 0 && runsToMilestone <= 30) {
      lines.add('You\'re $runsToMilestone runs from $milestoneLabel.');
    }

    return lines.isEmpty ? 'Match recorded. OVR updated.' : lines.join(' ');
  }
}
