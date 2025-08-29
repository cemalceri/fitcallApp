// ignore_for_file: constant_identifier_names

class ReasonOption {
  final String kod;
  final String etiket;
  const ReasonOption(this.kod, this.etiket);
}

class OnayRedIptalNedeniEnums {
  static const String YPL_PLAN = "YPL_PLAN";
  static const String YPL_TELAFI = "YPL_TELAFI";
  static const String YPL_DENEME = "YPL_DENEME";
  static const String YMD_OGRENCI = "YMD_OGRENCI";
  static const String YMD_ANTRENOR = "YMD_ANTRENOR";
  static const String YMD_HAVA = "YMD_HAVA";
  static const String YMD_KORT = "YMD_KORT";
  static const String YMD_DIGER = "YMD_DIGER";
  static const String IPT_PROG = "IPT_PROG";
  static const String IPT_HAVA = "IPT_HAVA";
  static const String IPT_BAKIM = "IPT_BAKIM";
  static const String IPT_TALEP = "IPT_TALEP";
  static const String IPT_DIGER = "IPT_DIGER";

  static const List<ReasonOption> yapildi = [
    ReasonOption(YPL_PLAN, "Planlandığı gibi yapıldı"),
    ReasonOption(YPL_TELAFI, "Telafi/ek ders yapıldı"),
    ReasonOption(YPL_DENEME, "Deneme dersi yapıldı"),
  ];
  static const List<ReasonOption> yapilmadi = [
    ReasonOption(YMD_OGRENCI, "Öğrenci gelmedi"),
    ReasonOption(YMD_ANTRENOR, "Antrenör mazeretli"),
    ReasonOption(YMD_HAVA, "Hava şartları"),
    ReasonOption(YMD_KORT, "Kort müsait değil"),
    ReasonOption(YMD_DIGER, "Diğer"),
  ];
  static const List<ReasonOption> iptal = [
    ReasonOption(IPT_PROG, "Program değişikliği"),
    ReasonOption(IPT_HAVA, "Hava koşulları"),
    ReasonOption(IPT_BAKIM, "Kort bakımı"),
    ReasonOption(IPT_TALEP, "Öğrenci talebi"),
    ReasonOption(IPT_DIGER, "Diğer"),
  ];
  static ReasonOption? findByKod(String? kod) {
    if (kod == null) return null;
    for (final r in [...yapildi, ...yapilmadi, ...iptal]) {
      if (r.kod == kod) return r;
    }
    return null;
  }
}
