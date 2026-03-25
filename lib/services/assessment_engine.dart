import 'package:horizon_protocol/models/game_models.dart';

class AssessmentEngine {
  // Statik analiz için metodlar
  Map<String, double> calculateScores(List<Decision> decisions, List<ChapterMetric> metrics) {
    return {
      'cognitive_focus': _calculateCognitiveFocus(decisions, metrics),
      'strategic_prioritization': _calculateStrategicPrioritization(decisions, metrics),
      'stress_resilience': _calculateStressResilience(decisions, metrics),
      'leadership_impact': _calculateLeadershipImpact(decisions, metrics),
      'consistency_index': _calculateConsistencyIndex(decisions),
      // Radar Chart Metrics
      'trust_score': _calculateTrustScore(decisions, metrics),
      'feedback_score': _calculateFeedbackScore(decisions, metrics),
      'initiative_score': _calculateInitiativeScore(decisions, metrics),
      'team_impact': _calculateTeamImpact(decisions, metrics),
    };
  }

  List<String> generateFlags(List<Decision> decisions, List<ChapterMetric> metrics) {
    List<String> flags = [];

    // --- Helper Fonksiyonlar ---
    bool hasVal(String chapter, String choice) => 
        decisions.any((d) => d.chapterId.toLowerCase().contains(chapter.toLowerCase()) && 
                             d.choiceId.toLowerCase().contains(choice.toLowerCase()));
    
    bool hasTrigger(String chapter, String trigger) =>
        decisions.any((d) => d.chapterId.toLowerCase().contains(chapter.toLowerCase()) && 
                             d.triggers.any((t) => t.toLowerCase().contains(trigger.toLowerCase())));
                             
    final c3Metrics = metrics.where((m) => m.chapterId.contains('3')).firstOrNull;
    final c5Dec = decisions.where((d) => d.chapterId.contains('5')).firstOrNull;
    final c6Dec = decisions.where((d) => d.chapterId.contains('6')).firstOrNull;
    final c7Dec = decisions.where((d) => d.chapterId.contains('7')).firstOrNull;

    // 1. Kriz Altında Paralizi (Decision Paralysis)
    if (c5Dec != null && c5Dec.durationMs > 60000 && c7Dec != null && c7Dec.durationMs > 25000) {
      flags.add('analitik_paralizi'); // Karar vermekte çok yavaş kalıyor
    }

    // 2. Çeldirici Zafiyeti (High Distractibility)
    bool distractible = false;
    if (c3Metrics != null && c3Metrics.additionalData != null) {
      final timeline = c3Metrics.additionalData!['timeline'] as List<dynamic>?;
      if (timeline != null) {
        final popups = timeline.where((e) => e != null && e is Map && e['a'] == 'POPUP_CLOSED');
        if (popups.isNotEmpty) {
          final popupClosed = popups.first as Map;
          if (popupClosed['reactionTime'] != null && popupClosed['reactionTime'] > 2000) {
            flags.add('odak_erozyonu_(çeldirici_zafiyeti)');
            distractible = true;
          }
        }
      }
    }

    // 3. Akıcı Zeka ve Dürtüsellik (Bölüm 1 Hata Analizi)
    final c1Metrics = metrics.where((m) => m.chapterId.contains('1')).firstOrNull;
    if (c1Metrics != null && c1Metrics.additionalData != null) {
      int errors = c1Metrics.additionalData!['errorCount'] ?? 0;
      int t1 = c1Metrics.additionalData!['timeToFirstClick'] ?? 0;
      if (errors > 3) {
        flags.add('dürtüsel_karar_alma_riski');
        flags.add('akıcı_zeka_bariyeri'); 
      }
      if (t1 > 20000) {
        if (!flags.contains('analitik_paralizi')) flags.add('analitik_paralizi');
      }
    }

    // 4. Aşırı Reaktif Karar Verme (Bölüm 2)
    final c2Dec = decisions.where((d) => d.chapterId.contains('2')).firstOrNull;
    if (c2Dec != null && c2Dec.durationMs < 2000) {
      flags.add('aşırı_reaktif_karar_verme');
    }

    // 4. Dürtüsel Karar Alma (Genel ve Bölüm 6)
    if ((c6Dec != null && c6Dec.triggers.contains('panic_clicks')) || 
        decisions.any((d) => d.durationMs < 1000 && !d.chapterId.contains('1'))) {
      if (!flags.contains('dürtüsel_karar_alma_riski')) flags.add('dürtüsel_karar_alma_riski');
    }

    // 5. Sistem Odaklılık vs Empati Odaklılık (C2 ve C4 Kesişimi)
    bool systemFocus = hasVal('2', 'reactor') && hasVal('4', 'lab');
    bool empathyFocus = hasVal('2', 'quarters') && hasVal('4', 'dorm');
    if (systemFocus) flags.add('katı_sistem_odaklılık');
    if (empathyFocus) flags.add('yüksek_sosyal_empati');

    // 5. Otoriter ve Makyavelist Eğilimler (C10, C11, C13)
    if (hasVal('10', 'kael') && hasVal('11', 'authoritarian') && hasVal('13', 'self')) {
      flags.add('otoriter_kontrol_ihtiyacı');
      flags.add('makyavelist_eğilimler');
    } else if (hasVal('11', 'authoritarian')) {
      flags.add('direktif_yönetim_tarzı');
    }

    // 6. Hizmetkar Liderlik ve Psikolojik Güvenlik (C11, C12, C13)
    if (hasVal('12', 'pardon') && hasVal('13', 'delegate')) {
      flags.add('hizmetkar_liderlik_potansiyeli');
      flags.add('psikolojik_güvenlik_inşası');
      if (hasVal('11', 'collaborative')) flags.add('güçlü_işbirliği_kültürü');
    }

    // 7. Dışsal vs İçsel Denetim Odağı (Locus of Control) - C9 ve C12 kesişimi
    if (hasVal('9', 'external') && hasVal('12', 'punish')) {
      flags.add('dışsal_denetim_odağı_(savunmacı)');
    } else if (hasVal('9', 'internal')) {
      flags.add('öz_farkındalık_ve_içsel_denetim');
    }

    // 8. Taktiksel Soğukkanlılık ve Dürtüsel Cezalandırma (Bölüm 12)
    final d12 = decisions.where((d) => d.chapterId.contains('12')).firstOrNull;
    if (d12 != null && d12.choiceId.contains('punish') && d12.durationMs < 1200) {
      flags.add('dürtüsel_cezalandırıcı_eğilimi');
    }

    // 9. Triage Mikro-Metrik Analizi (Kararsızlık ve Önceliklendirme)
    final c2Metrics = metrics.where((m) => m.chapterId.contains('2')).firstOrNull;
    if (c2Metrics != null && c2Metrics.additionalData != null) {
      final data = c2Metrics.additionalData!;
      int switches = data['switch_count'] ?? 0;
      Map<String, dynamic>? finalLevels = data['final_levels'];
      
      if (switches > 12) {
        flags.add('karar_verme_kararsızlığı_(aşırı_flickering)');
      }
      
      if (finalLevels != null) {
        int r = finalLevels['reactor'] ?? 0;
        int o = finalLevels['oxygen'] ?? 0;
        int c = finalLevels['comms'] ?? 0;
        
        // Kritik Sistem İhmali (Reaktör patlarken iletişimle uğraşmak)
        if (r < 30 && c > 70) {
          flags.add('stratejik_önceliklendirme_zafiyeti');
        }
        
        // Mükemmeliyetçilik (Her şeyi dengede tutma çabası)
        if (r > 65 && o > 65 && c > 65) {
          flags.add('yüksek_operasyonel_titizlik_(mükemmeliyetçilik)');
        }
      }
    }

    // 10. Bölüm 3 Gelişmiş Metrikler (Kutu Yönetimi)
    if (c3Metrics != null && c3Metrics.additionalData != null) {
      final data = c3Metrics.additionalData!;
      int flips = data['tile_flips'] ?? 0;
      int symErrors = data['symbolMatchErrors'] ?? 0;
      String strategy = data['box_closing_strategy'] ?? '';

      if (flips < 8 && symErrors == 0) {
        flags.add('stratejik_sorun_giderme_yetkinliği');
      } else if (flips > 15) {
        flags.add('deneme_yanılma_odaklı_yaklaşım');
      }
      
      if (strategy.contains('Toplu')) {
        flags.add('yüksek_operasyonel_hız_tercihi');
      }
    }

    if (!distractible && c6Dec != null && !c6Dec.triggers.contains('panic_clicks') && hasVal('7', 'success')) {
      flags.add('ileri_düzey_kriz_soğukkanlılığı');
    }

    // Hiçbir belirgin özellik yoksa
    if (flags.isEmpty) flags.add('normatif_profil_çizgisi');

    return flags;
  }

  // --- ÖZEL FORMÜLLER ---

  double _calculateConsistencyIndex(List<Decision> decisions) {
    double consistency = 100.0;
    
    // C2 (Triage) ve C4 (Kritik Seçim) arasındaki felsefi tutarlılık
    final d2 = decisions.where((d) => d.chapterId.contains('2')).firstOrNull;
    final d4 = decisions.where((d) => d.chapterId.contains('4')).firstOrNull;
    
    if (d2 != null && d4 != null) {
      bool d2System = d2.choiceId.toLowerCase().contains('reactor');
      bool d4System = d4.choiceId.toLowerCase().contains('lab');
      if (d2System != d4System) consistency -= 25.0; 
    }

    // C11 (Tartışma) ve C12 (Hata Yönetimi) arasındaki yönetim tutarlılığı
    final d11 = decisions.where((d) => d.chapterId.contains('11')).firstOrNull;
    final d12 = decisions.where((d) => d.chapterId.contains('12')).firstOrNull;
    
    if (d11 != null && d12 != null) {
      bool d11Collab = d11.choiceId.toLowerCase().contains('collaborative');
      bool d12Punish = d12.choiceId.toLowerCase().contains('punish');
      // İşbirlikçi deyip, hatada hemen cezalandırıyorsa tutarsızdır.
      if (d11Collab && d12Punish) consistency -= 20.0;
    }

    return consistency.clamp(0, 100);
  }

  double _calculateCognitiveFocus(List<Decision> decisions, List<ChapterMetric> metrics) {
    double score = 50.0; 
    
    // Bölüm 1 Hız ve Hata Analizi (KPI: Minimum Süre)
    final c1Metrics = metrics.where((m) => m.chapterId.contains('1')).firstOrNull;
    if (c1Metrics != null) {
      if (c1Metrics.totalTimeMs <= 6000) score += 20.0; // Yüksek hız bonusu
      else if (c1Metrics.totalTimeMs > 20000) score -= 15.0;
      
      // Hata cezası (Dürtüsellik)
      int errors = c1Metrics.additionalData?['errorCount'] ?? 0;
      if (errors > 2) score -= 20.0;
    }

    // Bölüm 3 Parazitler (Yan uyaranlara rağmen odaklanma)
    final c3Metrics = metrics.where((m) => m.chapterId.contains('3')).firstOrNull;
    if (c3Metrics != null && c3Metrics.additionalData != null) {
      final timeline = c3Metrics.additionalData!['timeline'] as List<dynamic>?;
      if (timeline != null) {
        final popups = timeline.where((e) => e != null && e is Map && e['a'] == 'POPUP_CLOSED');
        if (popups.isNotEmpty) {
          final popup = popups.first as Map;
          if (popup['reactionTime'] != null) {
            int rt = popup['reactionTime'];
            if (rt < 800) score += 20.0; // Mükemmel odak ve refleks
            else if (rt > 2000) score -= 15.0; // Çelinebilirlik yüksek
          }
        }
      }
    }

    // Bölüm 5 Şifre çözme hızı (KPI: Minimum Süre)
    final c5 = decisions.where((d) => d.chapterId.contains('5')).firstOrNull;
    final c5Metrics = metrics.where((m) => m.chapterId.contains('5')).firstOrNull;
    if (c5 != null) {
      if (c5.durationMs < 35000) score += 20.0; // Yüksek verimlilik
      else if (c5.durationMs > 80000) score -= 15.0;
      
      if (c5Metrics != null && c5Metrics.additionalData != null) {
        int rTime = c5Metrics.additionalData!['readingTime'] ?? 0;
        if (rTime > 45000) score -= 10.0; 
      }
    }

    // Bölüm 3 Ek Metrikler (Derinleştirilmiş)
    if (c3Metrics != null && c3Metrics.additionalData != null) {
      int missed = c3Metrics.additionalData!['missedPopups'] ?? 0;
      int symErrors = c3Metrics.additionalData!['symbolMatchErrors'] ?? 0;
      int flips = c3Metrics.additionalData!['tile_flips'] ?? 0;
      
      if (missed > 2) score -= 10.0;
      if (symErrors > 2) score -= 15.0;
      
      // Çok fazla gereksiz kutu çevirme "dağınık" bir odağı gösterir
      if (flips > 15) score -= 15.0;
      else if (flips < 7 && symErrors == 0) score += 10.0; // Verimli çalışma
    }
    
    return score.clamp(0, 100);
  }

  double _calculateStrategicPrioritization(List<Decision> decisions, List<ChapterMetric> metrics) {
    double score = 40.0;
    
    // Sistem vs İnsan ağırlıkları
    for (var d in decisions) {
      final cid = d.choiceId.toLowerCase();
      // Kurum/Strateji tercihleri
      if (cid.contains('reactor') || cid.contains('lab') || cid.contains('strategic') || cid.contains('kael')) {
        score += 15.0;
      }
      // Kısa vadeli duygusal/insani tercihler
      if (cid.contains('quarters') || cid.contains('dorm') || cid.contains('empath') || cid.contains('elara')) {
        score -= 5.0; 
      }
    }

    return score.clamp(0, 100);
  }

  double _calculateStressResilience(List<Decision> decisions, List<ChapterMetric> metrics) {
    double score = 50.0;
    
    final c5Metrics = metrics.where((m) => m.chapterId.contains('5')).firstOrNull;
    final c6 = decisions.where((d) => d.chapterId.contains('6')).firstOrNull;
    if (c6 != null) {
      if (c6.triggers.contains('panic_clicks') || c6.triggers.contains('panic')) score -= 25.0;
      else score += 15.0;
    }

    // Bölüm 7 - Çöküş (KPI: Seçim kalitesi ve Hata Sayısı)
    // Bu bölümde süre ana kıstas değildir, çünkü rastgele seçim ihtimali vardır.
    final c7 = decisions.where((d) => d.chapterId.contains('7')).firstOrNull;
    final c7Metrics = metrics.where((m) => m.chapterId.contains('7')).firstOrNull;
    
    if (c7 != null) {
      if (c7.choiceId.toLowerCase().contains('success') || c7.choiceId.toLowerCase().contains('blue')) score += 20.0;
      // Süre cezası kaldırıldı, hata cezası korunuyor
      
      int errors = c7Metrics?.additionalData?['errorCount'] ?? 0;
      if (errors > 0) score -= (errors * 8.0).clamp(0, 30); // Hatalı seçimler daha ağır cezalandırılır
    }

    // Sızıntı sırasındaki mantıksal eylem (Bölüm 8)
    final c8 = decisions.where((d) => d.chapterId.contains('8')).firstOrNull;
    final c8Metrics = metrics.where((m) => m.chapterId.contains('8')).firstOrNull;
    if (c8 != null && c8.choiceId.toLowerCase().contains('mask')) {
      score += 15.0; 
    }
    if (c8Metrics != null && c8Metrics.additionalData != null) {
      int rTime = c8Metrics.additionalData!['reactionTime'] ?? 0;
      if (rTime > 10000) score -= 15.0; // Kararsızlık
    }

    // Bölüm 5 Hatalı PIN denemeleri
    if (c5Metrics != null && c5Metrics.additionalData != null) {
      int failed = c5Metrics.additionalData!['failedAttempts'] ?? 0;
      if (failed > 3) score -= 20.0;
    }

    // Bölüm 6 Susturma Hızı
    final c6Metrics = metrics.where((m) => m.chapterId.contains('6')).firstOrNull;
    if (c6Metrics != null && c6Metrics.additionalData != null) {
      int mSpeed = c6Metrics.additionalData!['mutingSpeed'] ?? 0;
      if (mSpeed < 1000) score += 15.0; // Hızlı refleks
    }

    return score.clamp(0, 100);
  }

  double _calculateLeadershipImpact(List<Decision> decisions, List<ChapterMetric> metrics) {
    double score = 40.0;
    
    final c11 = decisions.where((d) => d.chapterId.contains('11')).firstOrNull;
    final c12 = decisions.where((d) => d.chapterId.contains('12')).firstOrNull;
    
    // Tartışma Yönetim Stili (Bölüm 11)
    final c11Metrics = metrics.where((m) => m.chapterId.contains('11')).firstOrNull;
    if (c11 != null) {
      if (c11.choiceId.toLowerCase().contains('collaborative')) score += 15.0;
      else if (c11.choiceId.toLowerCase().contains('authoritarian')) score -= 10.0; // Toksik etki riski
      
      if (c11Metrics != null && c11Metrics.additionalData != null) {
        int agree = c11Metrics.additionalData!['finalAgreement'] ?? 0;
        if (agree == 1) score += 10.0;
      }
    }

    // Hata Toleransı / Koçluk (Bölüm 12)
    final c12Metrics = metrics.where((m) => m.chapterId.contains('12')).firstOrNull;
    if (c12 != null) {
      if (c12.choiceId.toLowerCase().contains('pardon') || c12.choiceId.toLowerCase().contains('forgive')) score += 20.0;
      if (c12.choiceId.toLowerCase().contains('punish')) score -= 15.0;
      
      if (c12Metrics != null && c12Metrics.additionalData != null) {
        int fDelay = c12Metrics.additionalData!['forgiveDelay'] ?? 0;
        if (fDelay > 5000) score -= 10.0; // Karar ağırlığı veya iç-çatışma gecikmesi
      }
    }

    // Delegasyon ve Güven (Bölüm 13)
    final c13 = decisions.where((d) => d.chapterId.contains('13')).firstOrNull;
    final c13Metrics = metrics.where((m) => m.chapterId.contains('13')).firstOrNull;
    if (c13 != null) {
      if (c13.choiceId.toLowerCase().contains('delegate')) score += 25.0;
      if (c13.choiceId.toLowerCase().contains('self')) score -= 15.0; // Mikro-yönetim
      
      if (c13Metrics != null && c13Metrics.additionalData != null) {
        num dRatioNum = c13Metrics.additionalData!['delegationRatio'] ?? 0.0;
        double dRatio = dRatioNum.toDouble();
        int rDur = c13Metrics.additionalData!['readDuration'] ?? 0;
        if (dRatio > 0.8) score += 10.0;
        if (rDur < 5000 && rDur > 0) score -= 10.0; // Karar ağırlığı yetersiz (Yüzeysel liderlik)
      }
    }
    
    return score.clamp(0, 100);
  }

  String getLeadershipArchetype(double leadershipScore, double strategicScore) {
    if (leadershipScore >= 75 && strategicScore >= 70) return "İşbirlikçi Vizyoner";
    if (leadershipScore >= 75 && strategicScore < 70) return "Hizmetkar Lider / Koç";
    if (leadershipScore < 50 && strategicScore >= 70) return "Otorite Odaklı Uygulayıcı";
    if (leadershipScore >= 50 && leadershipScore < 75 && strategicScore >= 70) return "Stratejik Yönetici";
    if (leadershipScore < 45 && strategicScore < 45) return "Düzen Arayan / Reaktif Operatör";
    return "Dengeli Köprü Kurucu";
  }

  String getExecutiveSummary(Map<String, double> scores, List<String> flags) {
    List<String> insights = [];

    // Bilişsel ve Stratejik Yetiler
    double focus = scores['cognitive_focus'] ?? 0;
    double strategy = scores['strategic_prioritization'] ?? 0;
    double stress = scores['stress_resilience'] ?? 0;
    double leadership = scores['leadership_impact'] ?? 0;

    // Profilin Ana Çerçevesi
    if (focus > 75 && strategy > 75) {
      insights.add("Aday, kompleks sistem bilgileriyle çalışırken yüksek düzeyde odaklanabiliyor. Organizasyonel hedefleri bireysel konuların önünde tutarak sistem bütünlüğünü koruma eğiliminde.");
    } else if (focus < 50) {
      insights.add("Adayın çevresel uyaranlara (çeldiricilere) olan duyarlılığı, analitik süreçleri bölme riski taşıyor. Derin odaklanma gerektiren görevlerde sıkıntı yaşayabilir.");
    } else {
      insights.add("Bilişsel kapasitesi ve hedef önceliklendirmesi standartların içinde, dengeli bir performans gösteriyor.");
    }

    // Kriz Yönetimi Derin Analizi
    if (flags.contains('analitik_paralizi')) {
      insights.add("Ancak, şiddetli kriz anlarında saniye bazlı ciddi bir 'analitik paralizi' (karar donması) yaşamaktadır. Acil müdahale gerektiren roller için risk teşkil eder.");
    } else if (stress > 75) {
      insights.add("Kriz anlarında (baskı altında ve kısıtlı sürede) soğukkanlılığını olağanüstü koruyarak doğru mantıksal seçimleri yapabiliyor.");
    } else if (flags.contains('dürtüsel_karar_alma_riski')) {
      insights.add("Stres altında dürtüsel davranma ve panik (hatalı/rastgele tuşlama) eğilimi gözlemlenmiştir.");
    }

    // Liderlik ve Takım Dinamiği
    if (flags.contains('makyavelist_eğilimler') || flags.contains('otoriter_kontrol_ihtiyacı')) {
      insights.add("Takım yönetiminde fazlasıyla otoriter, kontrolü elinde tutmak isteyen ve mikro-yönetime kayan bir profil çiziyor. Ekip üyelerinde tükenmişlik yaratma potansiyeli vardır.");
    } else if (flags.contains('hizmetkar_liderlik_potansiyeli') && leadership > 70) {
      insights.add("Psikolojik olarak güvenli bir alan yaratmada son derece başarılı. Hataları bağışlayıp ekibi sürece dahil eden, güçlü bir delegasyon (yetki devri) ve takım koçu zihniyetine sahip.");
    } else if (flags.contains('değer_tutarsızlığı_uyarısı')) {
      insights.add("Sözel ifadeleri (örn: işbirlikçi yaklaşım) ile kriz anındaki yaptırımları (örn: anında cezalandırma) arasında tutarsızlıklar saptanmıştır. Söylem-eylem uyumu sorunlu olabilir.");
    }

    if (flags.contains('dışsal_denetim_odağı_(savunmacı)')) {
      insights.add("Başarısızlıklarda faturayı dış koşullara veya takıma kesme (savunmacı yapı) yatkınlığı göstermektedir.");
    } else if (flags.contains('öz_farkındalık_ve_içsel_denetim')) {
      insights.add("Olayların sorumluluğunu içselleştirerek, öz-farkındalığı yüksek bir profesyonellik sergilemektedir.");
    }

    if (insights.isEmpty) {
      return "Genel tabloda extrem sapmalar göstermeyen, olağan ve istikrarlı bir çalışan profili. Uç değerlerin olmaması, operasyonel işlerde güvenilir bir rutin vadeder.";
    }

    return insights.join(" ");
  }

  // --- RADAR CHART CALCULATIONS ---

  double _calculateTrustScore(List<Decision> decisions, List<ChapterMetric> metrics) {
    double score = 50.0;
    final d12 = decisions.where((d) => d.chapterId.contains('12')).firstOrNull;
    final d13 = decisions.where((d) => d.chapterId.contains('13')).firstOrNull;
    
    if (d12 != null && d12.choiceId.contains('pardon')) score += 25.0; // Hatayı tolere etme
    if (d13 != null && d13.choiceId.contains('delegate')) score += 25.0; // Yetki devri
    
    return score.clamp(0, 100);
  }

  double _calculateFeedbackScore(List<Decision> decisions, List<ChapterMetric> metrics) {
    double score = 40.0;
    final d11 = decisions.where((d) => d.chapterId.contains('11')).firstOrNull;
    final d9 = decisions.where((d) => d.chapterId.contains('9')).firstOrNull;
    
    if (d11 != null && d11.choiceId.contains('collaborative')) score += 30.0; // Diyaloga açıklık
    if (d9 != null && d9.choiceId.contains('internal')) score += 30.0; // Öz-eleştiri/Sorumluluk
    
    return score.clamp(0, 100);
  }

  double _calculateInitiativeScore(List<Decision> decisions, List<ChapterMetric> metrics) {
    double score = 30.0;
    final c1 = metrics.where((m) => m.chapterId.contains('1')).firstOrNull;
    final c8 = decisions.where((d) => d.chapterId.contains('8')).firstOrNull;
    
    if (c1 != null && c1.totalTimeMs < 8000) score += 35.0; // Erken aksiyon
    if (c8 != null && c8.choiceId.contains('mask')) score += 35.0; // Proaktif önlem
    
    return score.clamp(0, 100);
  }

  double _calculateTeamImpact(List<Decision> decisions, List<ChapterMetric> metrics) {
    double score = 35.0;
    final d10 = decisions.where((d) => d.chapterId.contains('10')).firstOrNull;
    final d13 = decisions.where((d) => d.chapterId.contains('13')).firstOrNull;
    
    if (d10 != null && (d10.choiceId.contains('elara') || d10.choiceId.contains('kael'))) score += 30.0; // Liderlik tercihi yapma
    if (d13 != null && d13.choiceId.contains('delegate')) score += 35.0; // Takımı güçlendirme
    
    return score.clamp(0, 100);
  }
}
