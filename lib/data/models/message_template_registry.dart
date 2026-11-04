import 'message_template.dart';

class MessageTemplateRegistry {
  static final Map<String, MessageTemplate> _templates = {};
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    registerAll(_defaultApprovedTemplates);
  }

  static void register(MessageTemplate template) {
    if (template.name.isNotEmpty) {
      _templates[template.name] = template;
    }
  }

  static void registerAll(Iterable<MessageTemplate> templates) {
    for (final t in templates) {
      register(t);
    }
  }

  static MessageTemplate? find(String? name) {
    ensureInitialized();
    if (name == null || name.isEmpty) return null;
    return _templates[name];
  }

  static MessageTemplate? findByContent(String? content) {
    ensureInitialized();
    if (content == null || content.trim().isEmpty) return null;
    final clean = content.trim();

    for (final tpl in _templates.values) {
      // 1. Check template name exact or partial
      if (clean.contains(tpl.name)) return tpl;
      // 2. Check header
      if (tpl.header != null && tpl.header!.isNotEmpty && clean.contains(tpl.header!)) {
        return tpl;
      }
      // 3. Check first 30 chars of body
      final snippet = tpl.body.trim();
      if (snippet.isNotEmpty) {
        final sub = snippet.substring(0, snippet.length > 25 ? 25 : snippet.length);
        if (clean.contains(sub)) return tpl;
      }
    }
    return null;
  }

  static List<TemplateButton> getButtonsForMessage({
    String? templateName,
    String? content,
    List<dynamic>? rawButtons,
  }) {
    ensureInitialized();

    // 1. If explicit buttons exist in content_attributes
    if (rawButtons != null && rawButtons.isNotEmpty) {
      final list = <TemplateButton>[];
      for (final b in rawButtons) {
        final tb = TemplateButton.from(b);
        if (tb.text.isNotEmpty) list.add(tb);
      }
      if (list.isNotEmpty) return list;
    }

    // 2. Look up template by name
    if (templateName != null && templateName.isNotEmpty) {
      final tpl = find(templateName);
      if (tpl != null && tpl.buttons.isNotEmpty) {
        return tpl.buttons;
      }
    }

    // 3. Fallback: match by content
    if (content != null && content.isNotEmpty) {
      final tpl = findByContent(content);
      if (tpl != null && tpl.buttons.isNotEmpty) {
        return tpl.buttons;
      }
    }

    return const [];
  }

  static List<MessageTemplate> getAllTemplates() {
    ensureInitialized();
    return _templates.values.toList();
  }

  static List<MessageTemplate> get approvedTemplates => getAllTemplates();

  static final List<MessageTemplate> _defaultApprovedTemplates = [
    MessageTemplate(
      id: 100,
      name: 'first_subscription_25_nov2026',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      header: 'خصم 25% لفترة محدودة',
      body: 'أهلًا 👋\nلسه بتفكّر تبدأ مع *Message Pro*؟\nابدأ دلوقتي ووفر *ربع قيمة أول اشتراك* 🎉\n\nاختار الاشتراك *الشهري أو النصف سنوي (6 شهور)* واستفيد بخصم *25% على أول اشتراك فقط*.\n\n⏳ اشترك لحد *1 نوفمبر* للاستفادة بالعرض.\n\nشوف الأسعار بعد الخصم، واختار الباقة المناسبة لشغلك 👇',
      buttons: const [
        TemplateButton(text: 'شوف الأسعار بعد الخصم', type: 'QUICK_REPLY'),
        TemplateButton(text: 'ساعدني أختار باقة', type: 'QUICK_REPLY'),
        TemplateButton(text: 'إيقاف العروض', type: 'QUICK_REPLY'),
      ],
      labels: const ['marketing', 'offers'],
    ),
    MessageTemplate(
      id: 99,
      name: 'messagepro_connection_check_20261027',
      category: 'UTILITY',
      language: 'ar_EG',
      status: 'APPROVED',
      body: 'هذه رسالة اختبار ربط واتساب التي طلبتها من Message Pro.\nمرجع الاختبار: MP-20261027.\nلا يلزم اتخاذ أي إجراء.',
      buttons: const [],
      labels: const ['system', 'test'],
    ),
    MessageTemplate(
      id: 68,
      name: 'messagepro_signup_welcome_7d_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      header: 'أهلًا بيك في مسج برو',
      body: 'حسابك اتسجّل بنجاح 🎉 ومعاك تجربة مجانية لمدة ٧ أيام.\n\nتقدر دلوقتي تربط أول قناة لاستقبال رسائل عملائك، تضيف فريقك، وتعمل أول AI Agent يساعدك في الرد.\n\nلو محتاج مساعدة في أي خطوة، ابعتلنا هنا وهنساعدك.',
      footer: 'فريق مسج برو',
      buttons: const [
        TemplateButton(
          text: 'ابدأ إعداد حسابك',
          type: 'URL',
          url: 'https://omni.message-pro.com/',
        ),
        TemplateButton(
          text: 'محتاج مساعدة',
          type: 'QUICK_REPLY',
        ),
      ],
      labels: const ['welcome'],
    ),
    MessageTemplate(
      id: 69,
      name: 'messagepro_first_channel_offer_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      header: 'عرض خاص ليك',
      body: 'مبروك ربط أول قناة 🎉\n\nتقدر تحصل على خصم *٢٠٪* على أول اشتراك في مسج برو لو اشتركت خلال *٧٢ ساعة* من دلوقتي. العرض متاح لغاية *٣٠ سبتمبر ٢٠٢٦ الساعة ١:٣٠ ظهرًا بتوقيت القاهرة*.\n\nحابب تستفيد من العرض؟ اضغط على «اطلب العرض» وهنساعدك تكمل.',
      footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
      buttons: const [
        TemplateButton(
          text: 'شوف الباقات',
          type: 'URL',
          url: 'https://message-pro.com/ar/pricing',
        ),
        TemplateButton(
          text: 'اطلب العرض',
          type: 'QUICK_REPLY',
        ),
      ],
      labels: const ['marketing', 'offers'],
    ),
    MessageTemplate(
      id: 66,
      name: 'messagepro_growth_advanced_25_48h_v3',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      header: 'خصم ٢٥٪ لمدة ٤٨ ساعة',
      body: 'عرض على باقتي *Growth* و*Advanced* من مسج برو.\n\nاجمع محادثات عملائك في مكان واحد، وخلّي فريقك عارف مين بيتابع كل عميل. سرّع الردود بالـAI والأتمتة، وابعت عروضك وتحديثاتك لعملائك بالرسائل الجماعية، وانقل البيزنس بتاعك لنقطة احترافية.\n\nاستخدم كود *MP25*\nقبل *٢٩ سبتمبر ٢٠٢٦ الساعة ٩ صباحًا بتوقيت القاهرة*.\n\nمستني إيه؟ ابدأ دلوقتي 👇',
      footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
      buttons: const [
        TemplateButton(
          text: 'سجّل الآن',
          type: 'URL',
          url: 'https://omni.message-pro.com/signup?utm_source=whatsapp&utm_medium=broadcast&utm_campaign=growth_advanced_25_48h',
        ),
        TemplateButton(text: 'طلب مكالمة', type: 'QUICK_REPLY'),
        TemplateButton(text: 'تفاصيل', type: 'QUICK_REPLY'),
      ],
      labels: const ['marketing'],
    ),
    MessageTemplate(
      id: 67,
      name: 'messagepro_pharmacies_followup_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      header: 'نظّم رسائل صيدليتك وفروعها',
      body: '💊 مع مسج برو، اجمع محادثات عملائك في مكان واحد، ووجّه كل محادثة للفرع أو الموظف المناسب. سواء فريقك بيرد من داخل الصيدلية أو من كول سنتر منفصل، تاريخ الكلام واضح والكل عارف مين بيتابع العميل، حتى لو الشفت اتغيّر.\n\nسرّع الردود بالـAI والأتمتة والردود الجاهزة، وابعت عروضك وتحديثاتك لعملائك بالرسائل الجماعية.\n\nحابب تشوف ده على شغل صيدليتك؟ اختار اللي يناسبك 👇',
      footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
      buttons: const [
        TemplateButton(
          text: 'تجربة مجانية',
          type: 'URL',
          url: 'https://omni.message-pro.com/signup?utm_source=whatsapp&utm_medium=broadcast&utm_campaign=pharmacies_followup',
        ),
        TemplateButton(text: 'احجز ديمو', type: 'QUICK_REPLY'),
        TemplateButton(text: 'اطلب مكالمة', type: 'QUICK_REPLY'),
        TemplateButton(text: 'تفاصيل أكتر', type: 'QUICK_REPLY'),
      ],
      labels: const ['pharmacies'],
    ),
    MessageTemplate(
      id: 70,
      name: 'messagepro_trial_ending_hours_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      header: 'تجربتك المجانية قربت تخلص',
      body: 'فاضل *٤٨ ساعة* على انتهاء تجربتك المجانية في مسج برو.\n\nلو محتاج مساعدة في ربط القنوات أو تجهيز الفريق والـAI Agent، ابعتلنا هنا. ولو جاهز تكمل استخدام مسج برو، تقدر تختار الباقة المناسبة ليك.',
      footer: 'فريق مسج برو',
      buttons: const [
        TemplateButton(
          text: 'شوف الباقات',
          type: 'URL',
          url: 'https://message-pro.com/ar/pricing',
        ),
        TemplateButton(text: 'محتاج مساعدة', type: 'QUICK_REPLY'),
      ],
      labels: const ['trial'],
    ),
    MessageTemplate(
      id: 71,
      name: 'messagepro_trial_expired_feedback_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      header: 'تجربتك المجانية انتهت',
      body: 'تجربتك المجانية في مسج برو انتهت. شكرًا إنك جرّبتنا 🙏\n\nحابين نسمع رأيك: إيه أكتر حاجة فادتك خلال التجربة، وإيه اللي تحب يكون أفضل؟ رد علينا هنا، ورأيك هيساعدنا نقدملك تجربة أنسب.\n\nولو حابب تكمل، تقدر تختار الباقة المناسبة ليك.',
      footer: 'فريق مسج برو',
      buttons: const [
        TemplateButton(
          text: 'شوف الباقات',
          type: 'URL',
          url: 'https://message-pro.com/ar/pricing',
        ),
        TemplateButton(text: 'شارك رأيك', type: 'QUICK_REPLY'),
      ],
      labels: const ['feedback'],
    ),
    MessageTemplate(
      id: 84,
      name: 'messagepro_requested_callback_utility_v1',
      category: 'UTILITY',
      language: 'ar_EG',
      status: 'APPROVED',
      body: 'أهلاً يا فندم، حاولنا نكلم حضرتك بخصوص المكالمة اللي طلبتها عن مسج برو. لو الوقت مش مناسب، ابعتلنا الوقت اللي يناسبك وهنكلمك 📞',
      buttons: const [],
      labels: const ['callbacks', 'support'],
    ),
    MessageTemplate(
      id: 64,
      name: 'messagepro_growth_advanced_25_48h',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      body: '🔥 *لمدة ٤٨ ساعة: خصم ٢٥٪ على Growth وAdvanced من Message Pro*\n\nاجمع محادثات عملائك في مكان واحد، وخلّي فريقك يعرف مين مسؤول عن كل محادثة وإيه الخطوة الجاية. ومع الأتمتة والـAI، تقدر تنظم الردود والمتابعة حسب طريقة شغلك.\n\nاستخدم كود *SAMPLE25* قبل *29 سبتمبر 2026 الساعة 6 مساءً بتوقيت القاهرة*.\n\n*رد «ابدأ»* وهنساعدك تختار الباقة وتجهّز حسابك. ولو عندك سؤال قبل الاشتراك، ابعته هنا.',
      footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
      buttons: const [],
      labels: const ['marketing'],
    ),
    MessageTemplate(
      id: 65,
      name: 'messagepro_growth_advanced_25_48h_v2',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      header: 'خصم ٢٥٪ لمدة ٤٨ ساعة',
      body: 'العرض على باقتي *Growth* و*Advanced* من Message Pro.\n\nاجمع محادثات عملائك في مكان واحد، وخلّي فريقك يعرف مين مسؤول عن كل محادثة وإيه الخطوة الجاية. ومع الأتمتة والـAI، تقدر تنظم الردود والمتابعة حسب طريقة شغلك.\n\nاستخدم كود *SAMPLE25* قبل *29 سبتمبر 2026 الساعة 6 مساءً بتوقيت القاهرة*.\n\n*رد «ابدأ»* وهنساعدك تختار الباقة وتجهّز حسابك. ولو عندك سؤال قبل الاشتراك، ابعته هنا.',
      footer: 'لإيقاف رسائل العروض، رد «إيقاف».',
      buttons: const [],
      labels: const ['marketing'],
    ),
    MessageTemplate(
      id: 82,
      name: 'messagepro_inquiry_received_utility_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      body: 'أهلًا يا فندم 👋 بنأكد استلام استفسارك عن مسج برو. هنرد عليك هنا، ولو في تفاصيل تحب تضيفها ابعتها في الشات.',
      buttons: const [],
      labels: const ['inquiry'],
    ),
    MessageTemplate(
      id: 74,
      name: 'messagepro_lead_followup_callback_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      body: 'أهلًا يا فندم، كنت بحاول أتواصل مع حضرتك بخصوص مسج برو. تحب أكلمك في وقت يناسبك تكون متاح فيه؟ 📞',
      buttons: const [],
      labels: const ['followup'],
    ),
    MessageTemplate(
      id: 73,
      name: 'messagepro_lead_followup_details_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      body: 'أهلًا يا فندم، هل التفاصيل واضحة لحضرتك؟ لو في أي سؤال أو حابب ندخل ميتنج نشرح فيه النظام، ابعتلنا هنا 📅',
      buttons: const [],
      labels: const ['followup'],
    ),
    MessageTemplate(
      id: 72,
      name: 'messagepro_lead_followup_interest_v1',
      category: 'MARKETING',
      language: 'ar_EG',
      status: 'APPROVED',
      body: 'أهلًا يا فندم 👋 حبيت أتابع مع حضرتك بخصوص مسج برو. هل لسه مناسب ليك نكمل الكلام عن الخدمة؟ لو عندك أي سؤال، ابعته هنا وهنرد عليك.',
      buttons: const [],
      labels: const ['followup'],
    ),
    MessageTemplate(
      id: 83,
      name: 'messagepro_requested_details_utility_v1',
      category: 'UTILITY',
      language: 'ar_EG',
      status: 'APPROVED',
      body: 'أهلًا يا فندم، التفاصيل اللي طلبتها عن مسج برو بعتناها لحضرتك. لو في أي نقطة محتاجة توضيح، ابعتلنا هنا وهنوضحها.',
      buttons: const [],
      labels: const ['details'],
    ),
  ];
}
