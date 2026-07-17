class PaiementModel {
  final int id;
  final double montant;
  final String datePaiement;
  final String modePaiement;
  final String? reference;

  PaiementModel({
    required this.id,
    required this.montant,
    required this.datePaiement,
    required this.modePaiement,
    this.reference,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    return PaiementModel(
      id: json['id'] ?? 0,
      montant: (json['montant'] ?? 0).toDouble(),
      datePaiement: json['datePaiement']?.toString() ?? '',
      modePaiement: json['modePaiement']?.toString() ?? '',
      reference: json['reference']?.toString(),
    );
  }
}

class PaiementResumeModel {
  final double totalBrut;
  final double reduction;
  final double totalNet;
  final double totalPaye;
  final double resteAPayer;
  final String statutPaiement;

  PaiementResumeModel({
    required this.totalBrut,
    required this.reduction,
    required this.totalNet,
    required this.totalPaye,
    required this.resteAPayer,
    required this.statutPaiement,
  });

  factory PaiementResumeModel.fromJson(Map<String, dynamic> json) {
    return PaiementResumeModel(
      totalBrut: (json['totalBrut'] ?? 0).toDouble(),
      reduction: (json['reduction'] ?? 0).toDouble(),
      totalNet: (json['totalNet'] ?? 0).toDouble(),
      totalPaye: (json['totalPaye'] ?? 0).toDouble(),
      resteAPayer: (json['resteAPayer'] ?? 0).toDouble(),
      statutPaiement: json['statutPaiement']?.toString() ?? 'IMPAYE',
    );
  }
}
