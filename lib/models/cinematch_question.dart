enum CineMatchAnswerKey { mood, style, era, duration, audience }

class CineMatchChoice {
  final String label;
  final String value;

  const CineMatchChoice({required this.label, required this.value});
}

class CineMatchQuestion {
  final String title;
  final String subtitle;
  final List<CineMatchChoice> choices;

  const CineMatchQuestion({
    required this.title,
    required this.subtitle,
    required this.choices,
  });

  static const List<CineMatchQuestion> all = [
    CineMatchQuestion(
      title: 'Comment tu te sens ce soir ?',
      subtitle: 'Ton humeur du moment',
      choices: [
        CineMatchChoice(label: 'Je veux rire',             value: 'fun'),
        CineMatchChoice(label: 'Je veux avoir peur',       value: 'scared'),
        CineMatchChoice(label: 'Je veux réfléchir',        value: 'think'),
        CineMatchChoice(label: 'Je veux pleurer',          value: 'sad'),
        CineMatchChoice(label: "Je veux de l'adrénaline",  value: 'thrill'),
        CineMatchChoice(label: "Je veux m'évader",         value: 'escape'),
      ],
    ),
    CineMatchQuestion(
      title: "Quel style de film t'attire ?",
      subtitle: 'Ton type préféré ce soir',
      choices: [
        CineMatchChoice(label: 'Quelque chose de réaliste', value: 'realistic'),
        CineMatchChoice(label: 'Un univers fantastique',    value: 'fantasy'),
        CineMatchChoice(label: 'Basé sur des faits réels', value: 'true_story'),
        CineMatchChoice(label: 'Peu importe',              value: 'any'),
      ],
    ),
    CineMatchQuestion(
      title: 'Tu préfères quelle époque ?',
      subtitle: 'Période de sortie',
      choices: [
        CineMatchChoice(label: 'Très récent (après 2020)', value: 'recent'),
        CineMatchChoice(label: 'Années 2000–2020',         value: 'modern'),
        CineMatchChoice(label: 'Classique (avant 2000)',   value: 'classic'),
        CineMatchChoice(label: 'Peu importe',              value: 'any'),
      ],
    ),
    CineMatchQuestion(
      title: "Combien de temps t'as ?",
      subtitle: 'Durée du film',
      choices: [
        CineMatchChoice(label: 'Moins de 1h30', value: 'short'),
        CineMatchChoice(label: '1h30 — 2h',     value: 'medium'),
        CineMatchChoice(label: 'Plus de 2h',    value: 'long'),
      ],
    ),
    CineMatchQuestion(
      title: 'Tu regardes avec qui ?',
      subtitle: 'Ambiance du soir',
      choices: [
        CineMatchChoice(label: 'Solo',       value: 'solo'),
        CineMatchChoice(label: 'En couple',  value: 'couple'),
        CineMatchChoice(label: 'Entre amis', value: 'amis'),
        CineMatchChoice(label: 'En famille', value: 'famille'),
      ],
    ),
  ];
}