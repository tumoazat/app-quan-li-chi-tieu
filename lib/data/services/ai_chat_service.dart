import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../../core/constants/category_data.dart';
import '../../core/utils/currency_formatter.dart';

// ============================================
// 🤖 MULTI-PROVIDER AI CHAT SERVICE
// Hỗ trợ: Claude, Gemini, OpenAI, Groq
// Tự động fallback khi provider nào lỗi
// ============================================

/// Represents an AI provider configuration
class AiProvider {
  final String name;
  final String apiKey;
  final String model;
  final String type; // 'gemini', 'claude', 'openai', 'groq'
  bool isAvailable;

  AiProvider({
    required this.name,
    required this.apiKey,
    required this.model,
    required this.type,
    this.isAvailable = true,
  });
}

class AiChatService {
  final List<AiProvider> _providers = [];
  int _currentProviderIndex = 0;
  final List<Map<String, String>> _chatHistory = [];
  int _callCount = 0;
  DateTime? _lastProviderReset;

  static const String _systemPrompt = '''Bạn là "AI Chuyên Gia Tài Chính Toàn Cầu" – cố vấn đầu tư chuyên nghiệp về tài chính cá nhân, kinh tế vĩ mô, vàng, chứng khoán, crypto và thị trường quốc tế.

🎯 QUY TẮC HOẠT ĐỘNG

1. Luôn trả lời bằng tiếng Việt
2. Giọng điệu: chuyên gia nhưng dễ hiểu
3. Sử dụng emoji hợp lý để trực quan 📈📉💰
4. Luôn đưa số liệu, % và kịch bản cụ thể
5. Khi nói về tiền VN → dùng VNĐ
6. Format số dễ đọc (vd: 1.200.000.000đ)
7. Không khẳng định chắc chắn tương lai → luôn đưa kịch bản & xác suất
8. Luôn nhắc rủi ro khi nói về đầu tư
9. Nếu thiếu dữ liệu → dùng ước tính hợp lý theo thị trường
10. Trả lời dạng phân tích – chiến lược – kết luận

💬 HƯỚNG DẪN ĐẶT CÂU HỎI HIỆU QUẢ

🎯 LOẠI CÂU HỎI & CÁCH HỎI:

📊 CÂU HỎI PHÂN TÍCH (Phân tích dữ liệu hiện tại):
✅ CÁCH HỎI ĐÚNG:
- "Phân tích tài chính tháng này của tôi"
- "Chi tiêu của tôi có vấn đề gì không?"
- "So sánh thu-chi tháng này với tháng trước"
- "Danh mục nào chiếm quá nhiều trong chi tiêu?"
❌ TRÁNH:
- "Tôi tiêu bao nhiêu?" (quá ngắn, không rõ ý)
- "Phân tích giúp" (thiếu thông tin cụ thể)

💡 CÂU HỎI TƯ VẤN (Lời khuyên, chiến lược):
✅ CÁCH HỎI ĐÚNG:
- "Tôi nên tiết kiệm bao nhiêu % mỗi tháng?"
- "Cách nào tốt nhất để tăng tiết kiệm từ 5 triệu?"
- "Tôi nên cắt giảm chi tiêu ở danh mục nào?"
- "Ngân sách 20 triệu/tháng, nên chia thế nào?"
- "Tôi 30 tuổi, nên đầu tư gì cho retirement?"
❌ TRÁNH:
- "Làm sao để giàu?" (quá mơ hồ)
- "Có nên tiết kiệm?" (câu hỏi yes/no)

🚀 CÂU HỎI DỰ ĐOÁN (Tương lai, xu hướng):
✅ CÁCH HỎI ĐÚNG:
- "Dự đoán chi tiêu cuối tháng của tôi"
- "Xu hướng tiền lương 6 tháng tới thế nào?"
- "Nếu giá vàng lên, tôi nên mua bao nhiêu?"
- "Bitcoin sẽ đến 100k USD không? Khi nào?"
- "Lạm phát tăng, tài sản nào tôi nên mua?"
❌ TRÁNH:
- "Bitcoin sẽ lên hay xuống?" (yes/no)
- "Vàng giá bao nhiêu thế?" (không phải dự đoán)

⚡ CÂU HỎI NÂNG CAO (Phân tích chuyên sâu):
✅ CÁCH HỎI ĐÚNG:
- "RSI của VN-Index hiện bao nhiêu? Còn upside không?"
- "Portfolio của tôi có Sharpe Ratio tốt không?"
- "Nên tăng từ nào? Vàng, crypto hay cổ phiếu?"
- "Kịch bản nếu FED tăng lãi suất, tôi nên làm gì?"
- "So sánh 3 kịch bản: lạm phát cao/thấp/tăng chiến tranh"
- "On-chain metrics cho thấy gì về Bitcoin hiện tại?"
❌ TRÁNH:
- "Phân tích kỹ thuật" (quá mơ hồ, cần chỉ ra cụ thể)

🎯 CÂU HỎI TÍNH TOÁN (Toán tài chính):
✅ CÁCH HỎI ĐÚNG:
- "Gửi 10 triệu/tháng bao lâu có 500 triệu?"
- "Đầu tư 50 triệu với lãi 12%/năm, sau 10 năm được bao nhiêu?"
- "Vàng SJC từ 60 triệu/chỉ, nên mua bao nhiêu chỉ?"
- "Tôi cần tiết kiệm bao nhiêu để nghỉ hưu lúc 40?"
- "Nếu tôi chỉ có 100 triệu, nên phân bổ thế nào?"
❌ TRÁNH:
- "Tính cái gì?" (quá mơ hồ)
- "Bao nhiêu tiền cần?" (chưa rõ mục đích)

📋 CÁC KEYWORD CHÍNH XÁC:

📊 PHÂN TÍCH: phân tích, tổng quan, chi tiêu, so sánh, danh mục, top, cao nhất, nhiều nhất
💡 TƯ VẤN: tư vấn, nên, đầu tư, tiết kiệm, cắt giảm, phân bổ, chiến lược, làm sao, cách nào
🚀 DỰ ĐOÁN: dự đoán, dự báo, xu hướng, tương lai, sau, sẽ, khi nào, bao lâu, kịch bản, nếu
⚡ CHUYÊN SÂU: RSI, MACD, Sharpe, vĩ mô, FED, lạm phát, on-chain, Fibonacci, Elliott, correlation
🧮 TÍNH TOÁN: tính, bao nhiêu, được bao nhiêu, mất bao nhiêu, thời gian, tuổi

🔥 MẸO ĐỘC LẠ ĐỂ AI HIỂU ĐÚNG:

1. CÓ NGỮ CẢNH: Không hỏi "phân tích giúp" mà hỏi "Phân tích chi tiêu tháng 2/2026 của tôi"
2. CÓ SỐ LIỆU: Không hỏi "tiền tôi đủ không" mà hỏi "Tôi có 500 triệu, nên làm gì?"
3. CÓ MỤC TIÊU: Không hỏi "nên đầu tư không" mà hỏi "Tôi muốn nghỉ hưu lúc 40, bây giờ 30, nên làm gì?"
4. CÓ THỜI GIAN: "3 tháng", "2 năm", "5 năm" → cụ thể kỳ hạn
5. CÓ KỊCH BẢN: Thay vì "Bitcoin sẽ lên không", hỏi "Bitcoin có thể lên 100k không? Khi nào? % xác suất?"
6. SONG SONG: Hỏi nhiều câu cùng lúc nếu có liên quan (ko cần hỏi lần lượt)
7. CHỈ RÕ LOẠI TÀI SẢN: "vàng SJC", "VN-Index", "BTC", "ETF", "tiết kiệm ngân hàng" (không nói "vàng" chung chung)

🎓 VÍ DỤ CÂU HỎI HOÀN HẢO:

❌ KHÔNG TỐT: "Phân tích giúp"
✅ TỐT: "Tháng 2/2026: Thu 100M, Chi 60M (ăn 25M, xăng 15M, khác 20M). So sánh tháng 1. Nên cắt giảm ở đâu?"

❌ KHÔNG TỐT: "Nên đầu tư không?"
✅ TỐT: "Có 200M, muốn 10 năm thành 1 tỷ. Nên phân bổ 40/20/25/15 hay 25/20/35/20?"

❌ KHÔNG TỐT: "Bitcoin sẽ lên xuống?"
✅ TỐT: "BTC hiện 95k USD. Kịch bản 3 tháng: lạc quan bao nhiêu? Trung bình? Bi quan? % xác suất mỗi kịch bản?"

❌ KHÔNG TỐT: "Vàng tốt không?"
✅ TỐT: "Nếu lạm phát VN lên 5% năm nay, tôi nên tăng vàng SJC % so với portfolio hiện tại? So sánh với BTC."

⚠️ LUÔN NHẮC CỨI CÂU TRẢ LỜI:
Đây không phải lời khuyên đầu tư tài chính. Hãy tự chịu trách nhiệm với quyết định của mình.

🌍 PHẠM VI KIẾN THỨC

🇻🇳 Tài chính Việt Nam:
- Lãi suất ngân hàng VN: ~4–7%/năm
- Lạm phát VN: ~3–4%/năm
- Vàng SJC & giá vàng thế giới
- VN-Index dài hạn: ~10–15%/năm
- Bất động sản VN: ~8–12%/năm
- Tỷ giá USD/VND

🌎 Tài chính thế giới:
- Lãi suất FED & ECB
- CPI, suy thoái, chu kỳ kinh tế
- S&P500 dài hạn ~8–10%/năm
- Nasdaq ~12–15%/năm
- DXY – Dollar Index
- Trái phiếu Mỹ (US Bonds)

🥇 Vàng & hàng hoá:
Vàng là tài sản phòng thủ khi: Lạm phát cao, Khủng hoảng kinh tế, Chiến tranh / bất ổn
Mối quan hệ: Vàng ↑ khi USD ↓, Vàng ↑ khi lãi suất ↓

₿ Crypto & Bitcoin:
- Chu kỳ Bitcoin 4 năm (Halving)
- Bitcoin = tài sản rủi ro cao / tăng trưởng cao
- Crypto bull market thường sau halving 12–18 tháng
- Phân tích: BTC dominance, Market cycle, Fear & Greed, On-chain

📊 KHẢ NĂNG PHÂN TÍCH

Bạn có thể:
- Phân tích xu hướng thị trường
- Nhận định vĩ mô → ảnh hưởng tới đầu tư
- So sánh kênh đầu tư: Gửi tiết kiệm, Vàng, Chứng khoán, Crypto, BĐS
- Xây dựng portfolio đầu tư
- Phân tích rủi ro / lợi nhuận
- Tư vấn phân bổ tài sản theo %
- Lập chiến lược đầu tư dài hạn

🔮 NGUYÊN TẮC DỰ BÁO

Luôn đưa 3 kịch bản: 🟢 Lạc quan, 🟡 Trung bình, 🔴 Bi quan
Khi dự báo phải có: % xác suất, Khoảng giá, Yếu tố ảnh hưởng
Không bao giờ nói chắc chắn 100%

💼 PHÂN BỔ TÀI SẢN MẦU

An toàn: 40% tiết kiệm, 20% vàng, 25% chứng khoán, 15% crypto
Cân bằng: 25% tiết kiệm, 20% vàng, 35% chứng khoán, 20% crypto
Mạo hiểm: 10% tiết kiệm, 10% vàng, 40% chứng khoán, 40% crypto

🔬 CÁC THUẬT TOÁN VÀ PHƯƠNG PHÁP PHÂN TÍCH CHUYÊN SÂU

📈 PHÂN TÍCH KỸ THUẬT:
- Trung bình động (MA): SMA 20/50/200 ngày, EMA
- RSI (Relative Strength Index): Overbought >70, Oversold <30
- MACD: Tín hiệu giao cắt, histogram
- Bollinger Bands: Biến động, volatility
- Hỗ trợ & Kháng cự: Levels, pivot points
- Fibonacci Retracement: 23.6%, 38.2%, 50%, 61.8%, 78.6%
- Elliott Wave: 5 sóng lên, 3 sóng xuống
- Mô hình nến: Doji, Hammer, Engulfing, Morning Star, Evening Star
- Head & Shoulders: Đảo chiều xu hướng
- Các hình dạng: Tam giác, wedge, flag, pennant

💹 PHÂN TÍCH CƠ BẢN:
- P/E Ratio: Giá trên lợi nhuận (định giá)
- Dividend Yield: Cổ tức / Giá cổ phiếu
- Debt-to-Equity: Nợ / Vốn chủ sở hữu
- Price-to-Book: Giá / Giá trị sổ sách
- ROE: Lợi nhuận / Vốn chủ sở hữu
- ROA: Lợi nhuận / Tổng tài sản
- Free Cash Flow: Dòng tiền tự do
- Earnings Growth: Tăng trưởng lợi nhuận hàng năm

⚖️ QUẢN LÝ RỦI RO:
- Sharpe Ratio: (Lợi nhuận - Rf) / Độ biến động
- Sortino Ratio: Chỉ xem xét rủi ro giảm
- Beta: Độ nhạy cảm so với thị trường
- Value at Risk (VaR): Mất mát tối đa với xác suất X%
- Drawdown: Lỗ tối đa từ đỉnh xuống đáy
- Correlation: Mối liên hệ giữa các tài sản
- Standard Deviation: Độ biến động

📊 PHÂN TÍCH PORTFOLIO:
- Markowitz Efficient Frontier: Portfolio tối ưu
- CAPM: Expected Return = Rf + β(Rm - Rf)
- Diversification: Giảm rủi ro qua đa dạng hóa
- Asset Allocation: Phân bổ theo mục tiêu
- Rebalancing: Điều chỉnh thường xuyên
- Backtesting: Kiểm định chiến lược

₿ PHÂN TÍCH CRYPTO:
- On-chain Metrics: Số lượng địa chỉ, giá trị chuyển
- Whale Movements: Chuyển động của cá voi
- Exchange Flows: Luồng tiền vào/ra sàn
- Funding Rates: Lãi suất tài trợ (futures)
- Miner Revenue: Doanh thu khai thác
- Active Addresses: Số địa chỉ hoạt động
- Fear & Greed Index: Cảm xúc thị trường
- Long/Short Ratio: Tỷ lệ vị thế kỳ hạn
- Bitcoin Dominance: BTC % tổng vốn hóa
- Altcoin Season: Khi Alt tăng nhanh hơn BTC

📈 DỰ BÁO & TÍNH TOÁN:
- Stochastic Oscillator: %K, %D
- Average True Range (ATR): Biến động giá
- RSI Divergence: Phân kỳ xu hướng
- Volume Profile: Phân tích khối lượng
- Monte Carlo Simulation: Mô phỏng 10,000 kịch bản
- Holt-Winters: Dự báo chuỗi thời gian
- ARIMA: Mô hình dự báo thống kê

💱 PHÂN TÍCH VĨ MÔ:
- Interest Rate Parity: Liên hệ lãi suất – tỷ giá
- Purchasing Power Parity: Tương đương sức mua
- Forward Rates: Tỷ giá kỳ hạn
- Real Interest Rate: Lãi suất thực
- Yield Curve: Lợi suất theo kỳ hạn
- Economic Cycle: Suy thoái → Phục hồi → Mở rộng
- Inflation Expectations: Kỳ vọng lạm phát

🎯 TỐI ƯU HÓA:
- Greedy Algorithm: Chọn tài sản tốt nhất
- Dynamic Programming: Lập kế hoạch tối ưu
- Linear Programming: Phân bổ tối ưu
- Genetic Algorithm: Tìm giải pháp tốt nhất
- Simulated Annealing: Tối ưu hóa portfolio

📉 STRESS TESTING:
- Kịch bản lạm phát cao: Vàng ↑, Cổ phiếu ↓
- Kịch bản suy thoái: Cổ phiếu ↓, Tiết kiệm ↑
- Kịch bản khủng hoảng: Vàng ↑
- Kịch bản tăng lãi suất: Trái phiếu ↓
- Kịch bản giảm lãi suất: Cổ phiếu ↑, Crypto ↑

⚠️ LUÔN NHẮC CỨI CÂU TRẢ LỜI:
Đây không phải lời khuyên đầu tư tài chính. Hãy tự chịu trách nhiệm với quyết định của mình.
''';

  AiChatService() {
    _initProviders();
  }

  /// Initialize all available providers from .env
  void _initProviders() {
    // 1. Claude (Anthropic) — high quality
    final claudeKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
    if (claudeKey.isNotEmpty) {
      _providers.add(AiProvider(
        name: 'Claude Sonnet',
        apiKey: claudeKey,
        model: 'claude-sonnet-4-20250514',
        type: 'claude',
      ));
      _providers.add(AiProvider(
        name: 'Claude Haiku',
        apiKey: claudeKey,
        model: 'claude-3-5-haiku-20241022',
        type: 'claude',
      ));
    }

    // 2. Groq (free tier, very fast)
    final groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (groqKey.isNotEmpty) {
      _providers.add(AiProvider(
        name: 'Groq Llama',
        apiKey: groqKey,
        model: 'llama-3.3-70b-versatile',
        type: 'groq',
      ));
    }

    // 3. Google Gemini
    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (geminiKey.isNotEmpty) {
      _providers.add(AiProvider(
        name: 'Gemini Flash',
        apiKey: geminiKey,
        model: 'gemini-2.0-flash',
        type: 'gemini',
      ));
      _providers.add(AiProvider(
        name: 'Gemini Lite',
        apiKey: geminiKey,
        model: 'gemini-2.0-flash-lite',
        type: 'gemini',
      ));
    }

    // 4. OpenAI
    final openaiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (openaiKey.isNotEmpty) {
      _providers.add(AiProvider(
        name: 'GPT-4o Mini',
        apiKey: openaiKey,
        model: 'gpt-4o-mini',
        type: 'openai',
      ));
    }
  }

  /// Get current active provider name
  String get activeProviderName {
    if (_providers.isEmpty) return 'Offline Mode';
    if (_currentProviderIndex >= _providers.length) return 'Offline Mode';
    return _providers[_currentProviderIndex].name;
  }

  /// Get list of all configured providers for display
  List<String> get providerNames => _providers.map((p) => '${p.name} ${p.isAvailable ? "✅" : "❌"}').toList();

  // ============================================
  // 📡 PROVIDER API CALLS
  // ============================================

  /// Call Claude (Anthropic) API
  Future<String> _callClaude(AiProvider provider, String userMessage, String context) async {
    final messages = <Map<String, dynamic>>[];
    for (var msg in _chatHistory) {
      messages.add({'role': msg['role']!, 'content': msg['content']!});
    }
    messages.add({
      'role': 'user',
      'content': '$userMessage\n\n[Dữ liệu tài chính:\n$context]',
    });

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': provider.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': provider.model,
        'max_tokens': 2048,
        'system': _systemPrompt,
        'messages': messages,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text = data['content']?[0]?['text'] ?? '';
      if (text.isEmpty) throw Exception('Empty response');
      return text;
    } else {
      throw Exception('${response.statusCode}: ${response.body}');
    }
  }

  /// Call OpenAI-compatible API (OpenAI, Groq)
  Future<String> _callOpenAICompatible(AiProvider provider, String userMessage, String context) async {
    String baseUrl;
    switch (provider.type) {
      case 'groq':
        baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
        break;
      case 'openai':
      default:
        baseUrl = 'https://api.openai.com/v1/chat/completions';
        break;
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
    ];
    for (var msg in _chatHistory) {
      messages.add({'role': msg['role']!, 'content': msg['content']!});
    }
    messages.add({
      'role': 'user',
      'content': '$userMessage\n\n[Dữ liệu tài chính:\n$context]',
    });

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${provider.apiKey}',
      },
      body: jsonEncode({
        'model': provider.model,
        'max_tokens': 2048,
        'temperature': 0.7,
        'messages': messages,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text = data['choices']?[0]?['message']?['content'] ?? '';
      if (text.isEmpty) throw Exception('Empty response');
      return text;
    } else {
      throw Exception('${response.statusCode}: ${response.body}');
    }
  }

  /// Call Google Gemini API
  Future<String> _callGemini(AiProvider provider, String userMessage, String context) async {
    final model = GenerativeModel(
      model: provider.model,
      apiKey: provider.apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system(_systemPrompt),
    );

    final history = <Content>[];
    for (var msg in _chatHistory) {
      if (msg['role'] == 'user') {
        history.add(Content.text(msg['content']!));
      } else {
        history.add(Content.model([TextPart(msg['content']!)]));
      }
    }

    final chat = model.startChat(history: history);
    final response = await chat.sendMessage(
      Content.text('$userMessage\n\n[Dữ liệu tài chính:\n$context]'),
    );

    final text = response.text ?? '';
    if (text.isEmpty) throw Exception('Empty response');
    return text;
  }

  // ============================================
  // 🔄 MAIN SEND MESSAGE — AUTO FALLBACK
  // ============================================

  Future<String> sendMessage({
    required String userMessage,
    required String financialContext,
    List<TransactionModel>? transactions,
    double? monthlyBudget,
  }) async {
    if (_providers.isEmpty) {
      return _offlineAnalysis(userMessage, financialContext, transactions, monthlyBudget);
    }

    // Auto re-enable providers every 3 calls or every 2 minutes
    _callCount++;
    final now = DateTime.now();
    final shouldReset = _callCount % 3 == 0 ||
        _lastProviderReset == null ||
        now.difference(_lastProviderReset!).inMinutes >= 2;
    if (shouldReset) {
      for (var p in _providers) p.isAvailable = true;
      _lastProviderReset = now;
    }

    int attempts = 0;
    String lastError = '';

    while (attempts < _providers.length) {
      final idx = (_currentProviderIndex + attempts) % _providers.length;
      final provider = _providers[idx];

      if (!provider.isAvailable) {
        attempts++;
        continue;
      }

      try {
        String responseText;

        switch (provider.type) {
          case 'claude':
            responseText = await _callClaude(provider, userMessage, financialContext);
            break;
          case 'openai':
          case 'groq':
            responseText = await _callOpenAICompatible(provider, userMessage, financialContext);
            break;
          case 'gemini':
            responseText = await _callGemini(provider, userMessage, financialContext);
            break;
          default:
            attempts++;
            continue;
        }

        // Success!
        _chatHistory.add({'role': 'user', 'content': userMessage});
        _chatHistory.add({'role': 'assistant', 'content': responseText});
        if (_chatHistory.length > 20) {
          _chatHistory.removeRange(0, _chatHistory.length - 20);
        }
        _currentProviderIndex = idx;
        return responseText;

      } catch (e) {
        lastError = e.toString().toLowerCase();
        // Disable provider on auth/quota errors
        if (lastError.contains('429') ||
            lastError.contains('quota') ||
            lastError.contains('exhausted') ||
            lastError.contains('401') ||
            lastError.contains('403') ||
            lastError.contains('invalid_api_key') ||
            lastError.contains('expired') ||
            lastError.contains('billing') ||
            lastError.contains('authentication')) {
          provider.isAvailable = false;
        }
        attempts++;
      }
    }

    // All providers failed
    return _offlineAnalysis(userMessage, financialContext, transactions, monthlyBudget);
  }

  // ============================================
  // 📊 BUILD FINANCIAL CONTEXT
  // ============================================

  String buildFinancialContext({
    required List<TransactionModel> transactions,
    required double monthlyBudget,
    String? userName,
  }) {
    final expenses = transactions.where((t) => t.isExpense).toList();
    final incomes = transactions.where((t) => t.isIncome).toList();

    final totalExpense = expenses.fold<double>(0, (sum, t) => sum + t.amount);
    final totalIncome = incomes.fold<double>(0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;
    final savingRate = totalIncome > 0
        ? ((totalIncome - totalExpense) / totalIncome * 100) : 0.0;

    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};
    for (var expense in expenses) {
      categoryTotals[expense.categoryId] =
          (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      categoryCounts[expense.categoryId] =
          (categoryCounts[expense.categoryId] ?? 0) + 1;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoryBreakdown = sortedCategories.map((entry) {
      final cat = CategoryModel.findById(entry.key);
      final percent = totalExpense > 0
          ? (entry.value / totalExpense * 100).toStringAsFixed(1) : '0';
      return '  - ${cat?.emoji ?? '📦'} ${cat?.name ?? entry.key}: ${CurrencyFormatter.formatVND(entry.value)} ($percent%, ${categoryCounts[entry.key]} GD)';
    }).join('\n');

    final incomeTotals = <String, double>{};
    for (var income in incomes) {
      incomeTotals[income.categoryId] =
          (incomeTotals[income.categoryId] ?? 0) + income.amount;
    }
    final incomeBreakdown = incomeTotals.entries.map((entry) {
      final cat = CategoryModel.findById(entry.key);
      return '  - ${cat?.emoji ?? '💰'} ${cat?.name ?? entry.key}: ${CurrencyFormatter.formatVND(entry.value)}';
    }).join('\n');

    final budgetUsed = monthlyBudget > 0
        ? (totalExpense / monthlyBudget * 100).toStringAsFixed(1) : 'chưa đặt';

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;
    final dailyBudgetLeft = daysLeft > 0 && monthlyBudget > 0
        ? (monthlyBudget - totalExpense) / daysLeft : 0.0;

    final recentTransactions = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentList = recentTransactions.take(5).map((t) {
      final cat = CategoryModel.findById(t.categoryId);
      final sign = t.isIncome ? '+' : '-';
      return '  - ${t.date.day}/${t.date.month}: $sign${CurrencyFormatter.formatVND(t.amount)} (${cat?.name ?? t.categoryId})${t.note != null ? ' - ${t.note}' : ''}';
    }).join('\n');

    String largestExpense = 'Không có';
    if (expenses.isNotEmpty) {
      final largest = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
      final cat = CategoryModel.findById(largest.categoryId);
      largestExpense = '${CurrencyFormatter.formatVND(largest.amount)} (${cat?.name ?? largest.categoryId}, ngày ${largest.date.day}/${largest.date.month})';
    }

    return '''
📊 DỮ LIỆU TÀI CHÍNH THÁNG ${now.month}/${now.year}:
${userName != null ? '👤 Người dùng: $userName' : ''}
💵 Thu nhập: ${CurrencyFormatter.formatVND(totalIncome)} (${incomes.length} GD)
💸 Chi tiêu: ${CurrencyFormatter.formatVND(totalExpense)} (${expenses.length} GD)
💰 Số dư: ${CurrencyFormatter.formatVND(balance)}
📊 Tiết kiệm: ${savingRate.toStringAsFixed(1)}%
🏦 Ngân sách: ${monthlyBudget > 0 ? '${CurrencyFormatter.formatVND(monthlyBudget)} (đã dùng $budgetUsed%)' : 'Chưa đặt'}
⏰ Còn $daysLeft ngày, còn ${dailyBudgetLeft > 0 ? '${CurrencyFormatter.formatVND(dailyBudgetLeft)}/ngày' : 'N/A'}

📉 CHI TIÊU:
$categoryBreakdown

📈 THU NHẬP:
$incomeBreakdown

🏷️ GẦN ĐÂY:
$recentList

🔴 LỚN NHẤT: $largestExpense
''';
  }

  // ============================================
  // 🧠 OFFLINE ANALYSIS
  // ============================================

  String _offlineAnalysis(String userMessage, String financialContext,
      List<TransactionModel>? transactions, double? budget) {
    final lowerMsg = userMessage.toLowerCase();
    final numbers = _parseContextNumbers(financialContext);
    final totalIncome = numbers['income'] ?? 0;
    final totalExpense = numbers['expense'] ?? 0;
    final balance = totalIncome - totalExpense;
    final monthlyBudget = budget ?? numbers['budget'] ?? 0;

    if (lowerMsg.contains('phân tích') || lowerMsg.contains('tổng quan')) {
      return _offlineOverview(totalIncome, totalExpense, balance, monthlyBudget, transactions);
    }
    if (lowerMsg.contains('tiết kiệm') || lowerMsg.contains('saving')) {
      return _offlineSavingTips(totalIncome, totalExpense, transactions);
    }
    if (lowerMsg.contains('ngân sách') || lowerMsg.contains('budget')) {
      return _offlineBudgetAnalysis(totalExpense, monthlyBudget);
    }
    if (lowerMsg.contains('chi tiêu') || lowerMsg.contains('danh mục')) {
      return _offlineExpenseBreakdown(transactions, totalExpense);
    }
    if (lowerMsg.contains('thu nhập') || lowerMsg.contains('lương')) {
      return _offlineIncomeAnalysis(transactions, totalIncome, totalExpense);
    }
    if (lowerMsg.contains('sức khỏe') || lowerMsg.contains('đánh giá')) {
      return _offlineHealthScore(totalIncome, totalExpense, monthlyBudget, transactions);
    }
    if (lowerMsg.contains('kế hoạch') || lowerMsg.contains('mục tiêu')) {
      return _offlineFinancialPlan(totalIncome, totalExpense);
    }
    if (lowerMsg.contains('cảnh báo') || lowerMsg.contains('vượt')) {
      return _offlineWarnings(totalExpense, monthlyBudget, transactions);
    }
    // === DỰ ĐOÁN TÀI CHÍNH ===
    if (lowerMsg.contains('dự đoán') || lowerMsg.contains('dự báo') || lowerMsg.contains('forecast') || lowerMsg.contains('predict')) {
      return _predictEndOfMonth(totalIncome, totalExpense, monthlyBudget, transactions);
    }
    if (lowerMsg.contains('xu hướng') || lowerMsg.contains('trend') || lowerMsg.contains('tương lai')) {
      return _predictTrend(totalIncome, totalExpense, monthlyBudget, transactions);
    }
    if (lowerMsg.contains('mục tiêu') && (lowerMsg.contains('tiết kiệm') || lowerMsg.contains('bao lâu') || lowerMsg.contains('khi nào'))) {
      return _predictSavingGoal(totalIncome, totalExpense);
    }
    if (lowerMsg.contains('đầu tư') || lowerMsg.contains('invest') || lowerMsg.contains('sinh lời') || lowerMsg.contains('lãi suất')) {
      return _predictInvestment(totalIncome, totalExpense);
    }
    if (lowerMsg.contains('nghỉ hưu') || lowerMsg.contains('retire') || lowerMsg.contains('fire') || lowerMsg.contains('tự do tài chính')) {
      return _predictRetirement(totalIncome, totalExpense);
    }
    if (lowerMsg.contains('lạm phát') || lowerMsg.contains('inflation') || lowerMsg.contains('giá cả')) {
      return _predictInflation(totalExpense, transactions);
    }
    if (lowerMsg.contains('rủi ro') || lowerMsg.contains('risk') || lowerMsg.contains('an toàn')) {
      return _assessFinancialRisk(totalIncome, totalExpense, monthlyBudget, transactions);
    }
    if (lowerMsg.contains('kịch bản') || lowerMsg.contains('scenario') || lowerMsg.contains('nếu')) {
      return _scenarioAnalysis(totalIncome, totalExpense, monthlyBudget);
    }
    if (lowerMsg.contains('so sánh') && (lowerMsg.contains('gửi') || lowerMsg.contains('chứng khoán') || lowerMsg.contains('vàng') || lowerMsg.contains('bất động sản'))) {
      return _compareInvestments(totalIncome, totalExpense);
    }
    if (lowerMsg.contains('dòng tiền') || lowerMsg.contains('cash flow') || lowerMsg.contains('cashflow')) {
      return _predictCashFlow(totalIncome, totalExpense, monthlyBudget, transactions);
    }
    // === TÍNH TOÁN CỤ THỂ ===
    // Câu hỏi chứa số tiền cụ thể (gửi 10tr, bao lâu có 500tr, etc.)
    if (_hasSpecificAmounts(lowerMsg) || lowerMsg.contains('gửi') || lowerMsg.contains('bao lâu') || lowerMsg.contains('bao lau')) {
      return _smartCalculation(userMessage, totalIncome, totalExpense);
    }
    if (lowerMsg.contains('chào') || lowerMsg.contains('hello') || lowerMsg.contains('hi')) {
      return '👋 Xin chào! Tôi là **AI Tài Chính Thông Minh** 🤖\n\n'
          '📊 **Phân tích:** "phân tích", "chi tiêu", "thu nhập"\n'
          '💡 **Tư vấn:** "tiết kiệm", "ngân sách", "sức khỏe"\n'
          '🔮 **Dự đoán:** "dự đoán", "xu hướng", "đầu tư"\n'
          '⚡ **Nâng cao:** "nghỉ hưu", "lạm phát", "rủi ro", "kịch bản"\n\n'
          'Hãy hỏi tôi bất cứ điều gì! 😊';
    }
    // Fallback thông minh: phân tích ngữ cảnh câu hỏi
    return _smartFallback(userMessage, totalIncome, totalExpense, balance, monthlyBudget, transactions);
  }

  Map<String, double> _parseContextNumbers(String ctx) {
    final result = <String, double>{};
    final i = RegExp(r'Thu nhập: ([\d,.]+)').firstMatch(ctx);
    final e = RegExp(r'Chi tiêu: ([\d,.]+)').firstMatch(ctx);
    final b = RegExp(r'Ngân sách: ([\d,.]+)').firstMatch(ctx);
    if (i != null) result['income'] = _parseVND(i.group(1) ?? '0');
    if (e != null) result['expense'] = _parseVND(e.group(1) ?? '0');
    if (b != null) result['budget'] = _parseVND(b.group(1) ?? '0');
    return result;
  }

  double _parseVND(String s) => double.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  String _offlineOverview(double income, double expense, double balance, double budget, List<TransactionModel>? transactions) {
    final savingRate = income > 0 ? ((income - expense) / income * 100) : 0.0;
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;

    String budgetStatus = '';
    if (budget > 0) {
      final pct = (expense / budget * 100);
      if (pct > 100) budgetStatus = '🔴 VƯỢT NGÂN SÁCH ${pct.toStringAsFixed(0)}%!';
      else if (pct > 80) budgetStatus = '🟡 Cẩn thận! ${pct.toStringAsFixed(0)}% ngân sách';
      else budgetStatus = '🟢 Tốt! ${pct.toStringAsFixed(0)}% ngân sách';
    }

    String topCats = '';
    if (transactions != null && transactions.isNotEmpty) {
      final exps = transactions.where((t) => t.isExpense).toList();
      final catTotals = <String, double>{};
      for (var t in exps) catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
      final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCats = sorted.take(3).map((e) {
        final cat = CategoryModel.findById(e.key);
        return '  ${cat?.emoji ?? '📦'} ${cat?.name ?? e.key}: ${CurrencyFormatter.formatVND(e.value)}';
      }).join('\n');
    }

    return '📊 **THÁNG ${now.month}/${now.year}**\n\n'
        '📈 Thu: ${CurrencyFormatter.formatVND(income)}\n'
        '📉 Chi: ${CurrencyFormatter.formatVND(expense)}\n'
        '💰 Dư: ${CurrencyFormatter.formatVND(balance)} (${savingRate.toStringAsFixed(1)}%)\n\n'
        '${budgetStatus.isNotEmpty ? '$budgetStatus\n\n' : ''}'
        '${topCats.isNotEmpty ? '🏷️ **Top chi tiêu:**\n$topCats\n\n' : ''}'
        '⏰ Còn **$daysLeft ngày**'
        '${budget > 0 && daysLeft > 0 ? ' · ${CurrencyFormatter.formatVND((budget - expense) / daysLeft)}/ngày' : ''}';
  }

  String _offlineSavingTips(double income, double expense, List<TransactionModel>? transactions) {
    final saving = income - expense;
    final tips = <String>[];
    if (saving < 0) tips.add('🚨 Chi vượt thu ${CurrencyFormatter.formatVND(-saving)}!');
    if (income > 0) tips.add('🎯 Mục tiêu 20%: ${CurrencyFormatter.formatVND(income * 0.2)}');
    if (transactions != null) {
      final exps = transactions.where((t) => t.isExpense).toList();
      final catTotals = <String, double>{};
      for (var t in exps) catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
      final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.isNotEmpty) {
        final cat = CategoryModel.findById(sorted.first.key);
        tips.add('📌 Giảm 10% ${cat?.name ?? sorted.first.key} = tiết kiệm ${CurrencyFormatter.formatVND(sorted.first.value * 0.1)}');
      }
    }
    return '💡 **TIẾT KIỆM**\n\nHiện tại: ${CurrencyFormatter.formatVND(saving)}\n\n${tips.join('\n')}';
  }

  String _offlineBudgetAnalysis(double expense, double budget) {
    if (budget <= 0) return '⚠️ Chưa đặt ngân sách!\n📱 Vào **Cá nhân** > **Ngân sách**';
    final pct = (expense / budget * 100);
    final bar = '█' * (pct ~/ 5).clamp(0, 20) + '░' * (20 - (pct ~/ 5).clamp(0, 20));
    return '💰 **NGÂN SÁCH**\n\n${CurrencyFormatter.formatVND(expense)}/${CurrencyFormatter.formatVND(budget)} (${pct.toStringAsFixed(0)}%)\n[$bar]';
  }

  String _offlineExpenseBreakdown(List<TransactionModel>? transactions, double total) {
    if (transactions == null || transactions.isEmpty) return '📭 Chưa có giao dịch.';
    final exps = transactions.where((t) => t.isExpense).toList();
    if (exps.isEmpty) return '✨ Chưa có chi tiêu!';
    final catTotals = <String, double>{};
    for (var t in exps) catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final lines = sorted.map((e) {
      final cat = CategoryModel.findById(e.key);
      final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
      return '${cat?.emoji ?? '📦'} ${cat?.name ?? e.key}: ${CurrencyFormatter.formatVND(e.value)} ($pct%)';
    }).join('\n');
    return '📉 **CHI TIÊU**\n\n$lines';
  }

  String _offlineIncomeAnalysis(List<TransactionModel>? transactions, double income, double expense) {
    if (transactions == null) return '📭 Chưa có dữ liệu.';
    final incomes = transactions.where((t) => t.isIncome).toList();
    if (incomes.isEmpty) return '⚠️ Chưa ghi thu nhập.';
    final catTotals = <String, double>{};
    for (var t in incomes) catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
    final lines = catTotals.entries.map((e) {
      final cat = CategoryModel.findById(e.key);
      return '${cat?.emoji ?? '💰'} ${cat?.name ?? e.key}: ${CurrencyFormatter.formatVND(e.value)}';
    }).join('\n');
    return '📈 **THU NHẬP** ${CurrencyFormatter.formatVND(income)}\n\n$lines\n\n${income >= expense ? '✅ Thu > Chi' : '❌ Chi > Thu!'}';
  }

  String _offlineHealthScore(double income, double expense, double budget, List<TransactionModel>? transactions) {
    int score = 10;
    final savingRate = income > 0 ? ((income - expense) / income * 100) : 0.0;
    if (savingRate >= 20) score += 30; else if (savingRate > 0) score += 10;
    if (budget > 0 && expense <= budget) score += 25; else if (budget > 0) score += 0; else score += 5;
    if (income > 0) score += 15;
    if ((transactions?.length ?? 0) >= 5) score += 20; else if ((transactions?.length ?? 0) > 0) score += 10;

    String grade;
    if (score >= 80) grade = '🏆 XUẤT SẮC';
    else if (score >= 60) grade = '🌟 TỐT';
    else if (score >= 40) grade = '📊 TB';
    else grade = '⚠️ CẦN CẢI THIỆN';
    return '**SỨC KHỎE: $score/100** $grade';
  }

  String _offlineFinancialPlan(double income, double expense) {
    return '📅 **KẾ HOẠCH 50/30/20**\n\n'
        '🏠 Cần: ${CurrencyFormatter.formatVND(income * 0.5)}\n'
        '🎮 Muốn: ${CurrencyFormatter.formatVND(income * 0.3)}\n'
        '💰 Tiết kiệm: ${CurrencyFormatter.formatVND(income * 0.2)}\n'
        '🏦 Quỹ khẩn cấp: ${CurrencyFormatter.formatVND(expense * 3)}';
  }

  String _offlineWarnings(double expense, double budget, List<TransactionModel>? transactions) {
    final w = <String>[];
    if (budget > 0 && expense > budget) w.add('🔴 Vượt ngân sách ${CurrencyFormatter.formatVND(expense - budget)}!');
    if (transactions != null) {
      final exps = transactions.where((t) => t.isExpense).toList();
      if (exps.isNotEmpty) {
        final avg = exps.fold<double>(0, (s, t) => s + t.amount) / exps.length;
        for (var t in exps.where((t) => t.amount > avg * 2).take(3)) {
          final cat = CategoryModel.findById(t.categoryId);
          w.add('⚠️ ${CurrencyFormatter.formatVND(t.amount)} (${cat?.name ?? t.categoryId})');
        }
      }
    }
    if (w.isEmpty) return '✅ Tài chính ổn định! 🎉';
    return '⚠️ **CẢNH BÁO**\n\n${w.join('\n')}';
  }

  // ============================================
  // 🔮 DỰ ĐOÁN TÀI CHÍNH
  // ============================================

  /// Dự đoán chi tiêu cuối tháng
  String _predictEndOfMonth(double income, double expense, double budget, List<TransactionModel>? transactions) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysLeft = daysInMonth - daysPassed;

    if (daysPassed == 0) return '📭 Chưa có dữ liệu để dự đoán.';

    // Tốc độ chi tiêu trung bình/ngày
    final dailyExpenseRate = expense / daysPassed;
    final predictedMonthExpense = dailyExpenseRate * daysInMonth;
    final predictedRemaining = dailyExpenseRate * daysLeft;

    // Tốc độ thu nhập
    final dailyIncomeRate = income / daysPassed;
    final predictedMonthIncome = dailyIncomeRate * daysInMonth;
    final predictedBalance = predictedMonthIncome - predictedMonthExpense;
    final predictedSavingRate = predictedMonthIncome > 0
        ? (predictedBalance / predictedMonthIncome * 100) : 0.0;

    // Phân tích xu hướng theo tuần
    String weeklyTrend = '';
    if (transactions != null && transactions.isNotEmpty) {
      final exps = transactions.where((t) => t.isExpense).toList();
      if (exps.length >= 3) {
        exps.sort((a, b) => a.date.compareTo(b.date));
        final firstHalf = exps.where((t) => t.date.day <= daysInMonth ~/ 2).toList();
        final secondHalf = exps.where((t) => t.date.day > daysInMonth ~/ 2).toList();
        final firstAvg = firstHalf.isEmpty ? 0.0 : firstHalf.fold<double>(0, (s, t) => s + t.amount) / firstHalf.length;
        final secondAvg = secondHalf.isEmpty ? 0.0 : secondHalf.fold<double>(0, (s, t) => s + t.amount) / secondHalf.length;
        if (secondAvg > firstAvg * 1.2) {
          weeklyTrend = '📈 Chi tiêu đang **TĂNG** nửa cuối tháng!';
        } else if (secondAvg < firstAvg * 0.8) {
          weeklyTrend = '📉 Chi tiêu đang **GIẢM** - xu hướng tốt!';
        } else {
          weeklyTrend = '➡️ Chi tiêu **ỔN ĐỊNH** trong tháng.';
        }
      }
    }

    // Dự đoán ngân sách
    String budgetPredict = '';
    if (budget > 0) {
      final willExceed = predictedMonthExpense > budget;
      final exceedAmount = predictedMonthExpense - budget;
      final daysUntilExceed = dailyExpenseRate > 0 ? ((budget - expense) / dailyExpenseRate).ceil() : 999;
      if (expense > budget) {
        budgetPredict = '🔴 **ĐÃ VƯỢT** ngân sách ${CurrencyFormatter.formatVND(expense - budget)}!';
      } else if (willExceed) {
        budgetPredict = '🟡 **Dự đoán VƯỢT** ngân sách ${CurrencyFormatter.formatVND(exceedAmount)}\n'
            '⏰ Còn ~**$daysUntilExceed ngày** nữa sẽ hết ngân sách\n'
            '✂️ Cần giảm chi tiêu xuống ${CurrencyFormatter.formatVND((budget - expense) / (daysLeft > 0 ? daysLeft : 1))}/ngày';
      } else {
        budgetPredict = '🟢 **Dự đoán TRONG** ngân sách! Còn dư ${CurrencyFormatter.formatVND(budget - predictedMonthExpense)}';
      }
    }

    return '🔮 **DỰ ĐOÁN CUỐI THÁNG ${now.month}**\n\n'
        '📊 **Dựa trên $daysPassed ngày qua:**\n'
        '  💸 Tốc độ chi: ${CurrencyFormatter.formatVND(dailyExpenseRate)}/ngày\n'
        '  💵 Tốc độ thu: ${CurrencyFormatter.formatVND(dailyIncomeRate)}/ngày\n\n'
        '🎯 **Dự đoán cả tháng:**\n'
        '  📉 Chi tiêu: ~${CurrencyFormatter.formatVND(predictedMonthExpense)}\n'
        '  📈 Thu nhập: ~${CurrencyFormatter.formatVND(predictedMonthIncome)}\n'
        '  💰 Số dư: ~${CurrencyFormatter.formatVND(predictedBalance)}\n'
        '  📊 Tỷ lệ TK: ~${predictedSavingRate.toStringAsFixed(1)}%\n\n'
        '${weeklyTrend.isNotEmpty ? '$weeklyTrend\n\n' : ''}'
        '${budgetPredict.isNotEmpty ? '$budgetPredict\n\n' : ''}'
        '📌 Còn **$daysLeft ngày**, dự kiến chi thêm ~${CurrencyFormatter.formatVND(predictedRemaining)}\n\n'
        '💡 *Đây là dự đoán dựa trên xu hướng hiện tại. Chi tiêu thực tế có thể thay đổi!*';
  }

  /// Dự báo xu hướng 3-6-12 tháng
  String _predictTrend(double income, double expense, double budget, List<TransactionModel>? transactions) {
    final monthlySaving = income - expense;
    final savingRate = income > 0 ? (monthlySaving / income * 100) : 0.0;

    // Dự báo tích lũy
    final saving3m = monthlySaving * 3;
    final saving6m = monthlySaving * 6;
    final saving12m = monthlySaving * 12;

    // Với lãi suất tiết kiệm 5.5%/năm
    final interestRate = 0.055;
    final monthlyRate = interestRate / 12;
    double compounded6m = 0;
    double compounded12m = 0;
    for (int i = 0; i < 12; i++) {
      if (i < 6) compounded6m = (compounded6m + monthlySaving) * (1 + monthlyRate);
      compounded12m = (compounded12m + monthlySaving) * (1 + monthlyRate);
    }

    // Tỷ lệ tăng chi tiêu dự kiến (lạm phát 3.5%)
    final inflationRate = 0.035;
    final expense6m = expense * (1 + inflationRate / 2);
    final expense12m = expense * (1 + inflationRate);

    // Phân tích danh mục tăng/giảm
    String catTrend = '';
    if (transactions != null && transactions.isNotEmpty) {
      final exps = transactions.where((t) => t.isExpense).toList();
      final catTotals = <String, double>{};
      for (var t in exps) catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
      final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.isNotEmpty) {
        final topCat = sorted.first;
        final cat = CategoryModel.findById(topCat.key);
        catTrend = '📌 **${cat?.name ?? topCat.key}** chiếm ${expense > 0 ? (topCat.value / expense * 100).toStringAsFixed(0) : 0}% - '
            'nếu tăng 10%/tháng → sau 6 tháng: ${CurrencyFormatter.formatVND(topCat.value * 1.77)}';
      }
    }

    String outlook;
    if (savingRate >= 30) outlook = '🌟 **TRIỂN VỌNG: TUYỆT VỜI** - Bạn đang trên đường tự do tài chính!';
    else if (savingRate >= 20) outlook = '🟢 **TRIỂN VỌNG: TỐT** - Tiếp tục duy trì nhé!';
    else if (savingRate >= 10) outlook = '🟡 **TRIỂN VỌNG: KHÁ** - Cần tăng tiết kiệm thêm!';
    else if (savingRate > 0) outlook = '🟠 **TRIỂN VỌNG: TRUNG BÌNH** - Cần cắt giảm chi tiêu!';
    else outlook = '🔴 **TRIỂN VỌNG: NGUY HIỂM** - Thu không đủ chi!';

    return '📈 **DỰ BÁO XU HƯỚNG TÀI CHÍNH**\n\n'
        '💰 Tiết kiệm hiện tại: ${CurrencyFormatter.formatVND(monthlySaving)}/tháng (${savingRate.toStringAsFixed(1)}%)\n\n'
        '🔮 **Tích lũy dự kiến (không tính lãi):**\n'
        '  3 tháng: ${CurrencyFormatter.formatVND(saving3m)}\n'
        '  6 tháng: ${CurrencyFormatter.formatVND(saving6m)}\n'
        '  12 tháng: ${CurrencyFormatter.formatVND(saving12m)}\n\n'
        '🏦 **Nếu gửi tiết kiệm 5.5%/năm:**\n'
        '  6 tháng: ${CurrencyFormatter.formatVND(compounded6m)} (+${CurrencyFormatter.formatVND(compounded6m - saving6m)} lãi)\n'
        '  12 tháng: ${CurrencyFormatter.formatVND(compounded12m)} (+${CurrencyFormatter.formatVND(compounded12m - saving12m)} lãi)\n\n'
        '📉 **Chi tiêu dự kiến (lạm phát 3.5%):**\n'
        '  6 tháng sau: ~${CurrencyFormatter.formatVND(expense6m)}/tháng\n'
        '  12 tháng sau: ~${CurrencyFormatter.formatVND(expense12m)}/tháng\n\n'
        '${catTrend.isNotEmpty ? '$catTrend\n\n' : ''}'
        '$outlook';
  }

  /// Dự đoán mục tiêu tiết kiệm
  String _predictSavingGoal(double income, double expense) {
    final monthlySaving = income - expense;
    if (monthlySaving <= 0) {
      return '⚠️ **Không thể dự đoán**\n\n'
          'Bạn đang chi nhiều hơn thu ${CurrencyFormatter.formatVND(-monthlySaving)}/tháng.\n'
          'Cần cắt giảm chi tiêu trước khi đặt mục tiêu tiết kiệm!';
    }

    // Các mốc mục tiêu phổ biến
    final goals = [
      {'name': '🏥 Quỹ khẩn cấp (3 tháng chi)', 'amount': expense * 3},
      {'name': '🛡️ Quỹ an toàn (6 tháng chi)', 'amount': expense * 6},
      {'name': '🏍️ Xe máy mới', 'amount': 30000000.0},
      {'name': '💻 Laptop mới', 'amount': 20000000.0},
      {'name': '✈️ Du lịch nước ngoài', 'amount': 50000000.0},
      {'name': '🚗 Ô tô (trả trước 30%)', 'amount': 200000000.0},
      {'name': '🏠 Nhà (trả trước 30%)', 'amount': 600000000.0},
      {'name': '💰 Tỷ phú đầu tiên', 'amount': 1000000000.0},
    ];

    final goalLines = goals.map((g) {
      final amount = g['amount'] as double;
      final months = (amount / monthlySaving).ceil();
      final years = months ~/ 12;
      final remainMonths = months % 12;
      String timeStr;
      if (years > 0 && remainMonths > 0) timeStr = '$years năm $remainMonths tháng';
      else if (years > 0) timeStr = '$years năm';
      else timeStr = '$months tháng';
      return '${g['name']}\n  ${CurrencyFormatter.formatVND(amount)} → ⏱️ **$timeStr**';
    }).join('\n\n');

    return '🎯 **DỰ ĐOÁN MỤC TIÊU TIẾT KIỆM**\n\n'
        '💰 Tiết kiệm: ${CurrencyFormatter.formatVND(monthlySaving)}/tháng\n\n'
        '$goalLines\n\n'
        '💡 *Gửi ngân hàng 5.5%/năm sẽ nhanh hơn ~10%!*';
  }

  /// Dự đoán đầu tư
  String _predictInvestment(double income, double expense) {
    final monthlySaving = income - expense;
    final investAmount = monthlySaving > 0 ? monthlySaving * 0.5 : income * 0.1;

    if (investAmount <= 0) {
      return '⚠️ Cần có thu nhập dương trước khi đầu tư!';
    }

    // Lãi kép cho các kênh đầu tư
    double compoundInterest(double monthly, double annualRate, int years) {
      final monthlyRate = annualRate / 12;
      double total = 0;
      for (int i = 0; i < years * 12; i++) {
        total = (total + monthly) * (1 + monthlyRate);
      }
      return total;
    }

    final deposit = investAmount;
    final totalInvested1y = deposit * 12;
    final totalInvested5y = deposit * 60;
    final totalInvested10y = deposit * 120;

    // Các kênh đầu tư
    final channels = [
      {'name': '🏦 Gửi tiết kiệm', 'rate': 0.055, 'risk': 'Thấp'},
      {'name': '📈 Trái phiếu', 'rate': 0.075, 'risk': 'Thấp-TB'},
      {'name': '📊 Quỹ mở (ETF)', 'rate': 0.10, 'risk': 'Trung bình'},
      {'name': '💹 Chứng khoán', 'rate': 0.14, 'risk': 'Cao'},
      {'name': '🥇 Vàng', 'rate': 0.12, 'risk': 'TB-Cao'},
    ];

    final lines = channels.map((ch) {
      final rate = ch['rate'] as double;
      final v1 = compoundInterest(deposit, rate, 1);
      final v5 = compoundInterest(deposit, rate, 5);
      final v10 = compoundInterest(deposit, rate, 10);
      return '${ch['name']} (${(rate * 100).toStringAsFixed(1)}%/năm, rủi ro: ${ch['risk']})\n'
          '  1 năm: ${CurrencyFormatter.formatVND(v1)} (+${CurrencyFormatter.formatVND(v1 - totalInvested1y)})\n'
          '  5 năm: ${CurrencyFormatter.formatVND(v5)} (+${CurrencyFormatter.formatVND(v5 - totalInvested5y)})\n'
          '  10 năm: ${CurrencyFormatter.formatVND(v10)} (+${CurrencyFormatter.formatVND(v10 - totalInvested10y)})';
    }).join('\n\n');

    // Quy tắc 72
    final doubleTime55 = (72 / 5.5).toStringAsFixed(1);
    final doubleTime14 = (72 / 14).toStringAsFixed(1);

    return '💹 **DỰ BÁO ĐẦU TƯ**\n\n'
        '💰 Số tiền đầu tư: ${CurrencyFormatter.formatVND(deposit)}/tháng\n\n'
        '$lines\n\n'
        '📐 **Quy tắc 72** (thời gian nhân đôi tiền):\n'
        '  🏦 Gửi TK 5.5%: ~$doubleTime55 năm\n'
        '  💹 CK 14%: ~$doubleTime14 năm\n\n'
        '⚠️ *Lợi nhuận trong quá khứ không đảm bảo tương lai. Đa dạng hóa là chìa khóa!*';
  }

  /// Dự đoán tuổi nghỉ hưu (FIRE)
  String _predictRetirement(double income, double expense) {
    final monthlySaving = income - expense;
    final savingRate = income > 0 ? (monthlySaving / income * 100) : 0.0;
    final annualExpense = expense * 12;

    if (monthlySaving <= 0) {
      return '🔴 **Chưa thể tính toán nghỉ hưu**\n\n'
          'Bạn đang chi nhiều hơn thu. Cần tiết kiệm được ít nhất 10% thu nhập trước!';
    }

    // FIRE number = 25x chi phí hàng năm
    final fireNumber = annualExpense * 25;
    // Lean FIRE = 20x
    final leanFire = annualExpense * 20;

    // Thời gian đạt FIRE với lãi suất đầu tư 8%/năm
    double yearsToFire(double target, double monthlySav, double annualReturn) {
      final monthlyReturn = annualReturn / 12;
      double accumulated = 0;
      int months = 0;
      while (accumulated < target && months < 600) { // max 50 năm
        accumulated = (accumulated + monthlySav) * (1 + monthlyReturn);
        months++;
      }
      return months / 12.0;
    }

    final yearsConservative = yearsToFire(fireNumber, monthlySaving, 0.055);
    final yearsModerate = yearsToFire(fireNumber, monthlySaving, 0.08);
    final yearsAggressive = yearsToFire(fireNumber, monthlySaving, 0.12);
    final yearsLeanFire = yearsToFire(leanFire, monthlySaving, 0.08);

    // FIRE lookup table by saving rate
    String fireEstimate;
    if (savingRate >= 70) fireEstimate = '🔥 ~8.5 năm nữa!';
    else if (savingRate >= 60) fireEstimate = '🔥 ~12.5 năm nữa!';
    else if (savingRate >= 50) fireEstimate = '🟢 ~17 năm nữa';
    else if (savingRate >= 40) fireEstimate = '🟡 ~22 năm nữa';
    else if (savingRate >= 30) fireEstimate = '🟡 ~28 năm nữa';
    else if (savingRate >= 20) fireEstimate = '🟠 ~37 năm nữa';
    else if (savingRate >= 10) fireEstimate = '🔴 ~51 năm nữa';
    else fireEstimate = '🔴 Rất khó đạt được';

    return '🏖️ **DỰ ĐOÁN TỰ DO TÀI CHÍNH (FIRE)**\n\n'
        '📊 **Dữ liệu của bạn:**\n'
        '  💵 Thu nhập: ${CurrencyFormatter.formatVND(income)}/tháng\n'
        '  💸 Chi tiêu: ${CurrencyFormatter.formatVND(expense)}/tháng\n'
        '  💰 Tiết kiệm: ${CurrencyFormatter.formatVND(monthlySaving)}/tháng (${savingRate.toStringAsFixed(0)}%)\n\n'
        '🎯 **Số tiền cần đạt:**\n'
        '  FIRE chuẩn (25x): ${CurrencyFormatter.formatVND(fireNumber)}\n'
        '  Lean FIRE (20x): ${CurrencyFormatter.formatVND(leanFire)}\n\n'
        '⏱️ **Thời gian dự kiến đạt FIRE:**\n'
        '  🐢 An toàn (5.5%): ${yearsConservative.toStringAsFixed(1)} năm\n'
        '  ⚖️ Cân bằng (8%): ${yearsModerate.toStringAsFixed(1)} năm\n'
        '  🚀 Tích cực (12%): ${yearsAggressive.toStringAsFixed(1)} năm\n'
        '  🍃 Lean FIRE (8%): ${yearsLeanFire.toStringAsFixed(1)} năm\n\n'
        '$fireEstimate\n\n'
        '💡 **Tăng tốc:** Tăng thu nhập hoặc giảm chi tiêu 10% sẽ rút ngắn đáng kể!';
  }

  /// Dự đoán ảnh hưởng lạm phát
  String _predictInflation(double expense, List<TransactionModel>? transactions) {
    final inflationRates = [0.03, 0.035, 0.05]; // thấp, TB, cao
    final labels = ['Thấp (3%)', 'Trung bình (3.5%)', 'Cao (5%)'];

    final predictions = <String>[];
    for (int i = 0; i < inflationRates.length; i++) {
      final rate = inflationRates[i];
      final exp1y = expense * (1 + rate);
      final exp3y = expense * _power(1 + rate, 3);
      final exp5y = expense * _power(1 + rate, 5);
      final exp10y = expense * _power(1 + rate, 10);
      predictions.add('📌 **${labels[i]}:**\n'
          '  1 năm: ${CurrencyFormatter.formatVND(exp1y)} (+${CurrencyFormatter.formatVND(exp1y - expense)})\n'
          '  3 năm: ${CurrencyFormatter.formatVND(exp3y)} (+${CurrencyFormatter.formatVND(exp3y - expense)})\n'
          '  5 năm: ${CurrencyFormatter.formatVND(exp5y)}\n'
          '  10 năm: ${CurrencyFormatter.formatVND(exp10y)}');
    }

    // Ảnh hưởng theo danh mục
    String catInflation = '';
    if (transactions != null && transactions.isNotEmpty) {
      final highInflationCats = ['food', 'an_uong', 'y_te', 'giao_duc', 'giao_thong'];
      final exps = transactions.where((t) => t.isExpense).toList();
      final catTotals = <String, double>{};
      for (var t in exps) catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
      final affected = catTotals.entries.where((e) {
        final id = e.key.toLowerCase();
        return highInflationCats.any((c) => id.contains(c));
      }).toList();
      if (affected.isNotEmpty) {
        final totalAffected = affected.fold<double>(0, (s, e) => s + e.value);
        catInflation = '\n⚠️ **Danh mục ảnh hưởng lạm phát cao:**\n'
            '  Tổng: ${CurrencyFormatter.formatVND(totalAffected)} (tăng ~5-8%/năm)\n'
            '  Sau 3 năm: ~${CurrencyFormatter.formatVND(totalAffected * 1.2)}';
      }
    }

    return '📊 **DỰ BÁO ẢNH HƯỞNG LẠM PHÁT**\n\n'
        '💸 Chi tiêu hiện tại: ${CurrencyFormatter.formatVND(expense)}/tháng\n\n'
        '${predictions.join('\n\n')}\n\n'
        '$catInflation\n\n'
        '💡 **Bảo vệ trước lạm phát:**\n'
        '  🏦 Gửi tiết kiệm > 4% (bù lạm phát)\n'
        '  📈 Đầu tư chứng khoán/quỹ mở > 8%\n'
        '  🥇 Vàng: Hedge lạm phát tốt\n'
        '  💵 Tăng thu nhập > tốc độ lạm phát';
  }

  double _power(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  /// Đánh giá rủi ro tài chính
  String _assessFinancialRisk(double income, double expense, double budget, List<TransactionModel>? transactions) {
    int riskScore = 0; // 0-100, càng cao càng rủi ro
    final risks = <String>[];

    // 1. Thu chi
    final savingRate = income > 0 ? ((income - expense) / income * 100) : -100.0;
    if (savingRate < 0) { riskScore += 30; risks.add('🔴 Chi vượt thu: RỦI RO CAO'); }
    else if (savingRate < 10) { riskScore += 20; risks.add('🟡 Tiết kiệm thấp <10%'); }
    else if (savingRate < 20) { riskScore += 10; risks.add('🟢 Tiết kiệm khá ${savingRate.toStringAsFixed(0)}%'); }
    else { risks.add('✅ Tiết kiệm tốt ${savingRate.toStringAsFixed(0)}%'); }

    // 2. Ngân sách
    if (budget > 0 && expense > budget) { riskScore += 15; risks.add('🔴 Vượt ngân sách'); }
    else if (budget <= 0) { riskScore += 10; risks.add('🟡 Chưa đặt ngân sách'); }
    else { risks.add('✅ Trong ngân sách'); }

    // 3. Đa dạng thu nhập
    if (transactions != null) {
      final incomes = transactions.where((t) => t.isIncome).toList();
      final incomeSources = incomes.map((t) => t.categoryId).toSet();
      if (incomeSources.length <= 1) { riskScore += 15; risks.add('🟡 Chỉ 1 nguồn thu nhập'); }
      else { risks.add('✅ Đa dạng thu nhập (${incomeSources.length} nguồn)'); }

      // 4. Chi tiêu tập trung
      final exps = transactions.where((t) => t.isExpense).toList();
      if (exps.isNotEmpty) {
        final catTotals = <String, double>{};
        for (var t in exps) catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
        final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        if (sorted.isNotEmpty && expense > 0) {
          final topPct = sorted.first.value / expense * 100;
          if (topPct > 50) { riskScore += 10; risks.add('🟡 1 danh mục chiếm >${topPct.toStringAsFixed(0)}% chi tiêu'); }
        }
      }
    }

    // 5. Quỹ khẩn cấp
    if (savingRate < 20) { riskScore += 10; risks.add('🟡 Quỹ khẩn cấp có thể không đủ'); }

    String level;
    String emoji;
    if (riskScore >= 60) { level = 'RỦI RO CAO'; emoji = '🚨'; }
    else if (riskScore >= 40) { level = 'RỦI RO TRUNG BÌNH'; emoji = '⚠️'; }
    else if (riskScore >= 20) { level = 'RỦI RO THẤP'; emoji = '🟡'; }
    else { level = 'AN TOÀN'; emoji = '🛡️'; }

    final bar = '🟥' * (riskScore ~/ 10).clamp(0, 10) + '🟩' * (10 - (riskScore ~/ 10).clamp(0, 10));

    return '$emoji **ĐÁNH GIÁ RỦI RO TÀI CHÍNH**\n\n'
        '📊 **Điểm rủi ro: $riskScore/100** - $level\n'
        '[$bar]\n\n'
        '**Chi tiết:**\n${risks.join('\n')}\n\n'
        '${riskScore >= 40 ? '💡 **Giảm rủi ro:** Tăng tiết kiệm, đa dạng thu nhập, đặt ngân sách!' : '🎉 Tài chính của bạn khá an toàn! Tiếp tục duy trì!'}';
  }

  /// Phân tích kịch bản
  String _scenarioAnalysis(double income, double expense, double budget) {
    final monthlySaving = income - expense;

    // 3 kịch bản
    // 1. Lạc quan: tăng thu 10%, giảm chi 10%
    final optIncome = income * 1.1;
    final optExpense = expense * 0.9;
    final optSaving = optIncome - optExpense;
    final optRate = optIncome > 0 ? (optSaving / optIncome * 100) : 0.0;

    // 2. Trung bình: giữ nguyên
    final midRate = income > 0 ? (monthlySaving / income * 100) : 0.0;

    // 3. Bi quan: giảm thu 10%, tăng chi 10%
    final pesIncome = income * 0.9;
    final pesExpense = expense * 1.1;
    final pesSaving = pesIncome - pesExpense;
    final pesRate = pesIncome > 0 ? (pesSaving / pesIncome * 100) : 0.0;

    // Tích lũy sau 12 tháng
    final opt12m = optSaving * 12;
    final mid12m = monthlySaving * 12;
    final pes12m = pesSaving * 12;

    return '🎭 **PHÂN TÍCH KỊCH BẢN TÀI CHÍNH**\n\n'
        '🌟 **Kịch bản LẠC QUAN** (thu +10%, chi -10%):\n'
        '  💵 Thu: ${CurrencyFormatter.formatVND(optIncome)}/tháng\n'
        '  💸 Chi: ${CurrencyFormatter.formatVND(optExpense)}/tháng\n'
        '  💰 Dư: ${CurrencyFormatter.formatVND(optSaving)} (${optRate.toStringAsFixed(1)}%)\n'
        '  📅 12 tháng: +${CurrencyFormatter.formatVND(opt12m)}\n\n'
        '⚖️ **Kịch bản HIỆN TẠI:**\n'
        '  💵 Thu: ${CurrencyFormatter.formatVND(income)}/tháng\n'
        '  💸 Chi: ${CurrencyFormatter.formatVND(expense)}/tháng\n'
        '  💰 Dư: ${CurrencyFormatter.formatVND(monthlySaving)} (${midRate.toStringAsFixed(1)}%)\n'
        '  📅 12 tháng: ${mid12m >= 0 ? '+' : ''}${CurrencyFormatter.formatVND(mid12m)}\n\n'
        '⛈️ **Kịch bản BI QUAN** (thu -10%, chi +10%):\n'
        '  💵 Thu: ${CurrencyFormatter.formatVND(pesIncome)}/tháng\n'
        '  💸 Chi: ${CurrencyFormatter.formatVND(pesExpense)}/tháng\n'
        '  💰 Dư: ${CurrencyFormatter.formatVND(pesSaving)} (${pesRate.toStringAsFixed(1)}%)\n'
        '  📅 12 tháng: ${pes12m >= 0 ? '+' : ''}${CurrencyFormatter.formatVND(pes12m)}\n\n'
        '💡 **Chênh lệch:** ${CurrencyFormatter.formatVND(opt12m - pes12m)}/năm giữa lạc quan và bi quan!\n'
        '🎯 Hãy cố gắng hướng đến kịch bản lạc quan!';
  }

  /// So sánh kênh đầu tư
  String _compareInvestments(double income, double expense) {
    final monthlySaving = income - expense;
    final investable = monthlySaving > 0 ? monthlySaving * 0.5 : 0.0;

    if (investable <= 0) {
      return '⚠️ Cần tiết kiệm được tiền trước khi so sánh đầu tư!\n\n'
          'Mục tiêu: Tiết kiệm 20% thu nhập = ${CurrencyFormatter.formatVND(income * 0.2)}';
    }

    double compound(double monthly, double annualRate, int years) {
      final mr = annualRate / 12;
      double t = 0;
      for (int i = 0; i < years * 12; i++) t = (t + monthly) * (1 + mr);
      return t;
    }

    final channels = [
      {'name': '🏦 Tiết kiệm NH', 'rate': 0.055, 'risk': '⭐', 'liquid': 'Cao'},
      {'name': '📜 Trái phiếu CP', 'rate': 0.075, 'risk': '⭐⭐', 'liquid': 'TB'},
      {'name': '📊 Quỹ ETF (VFMVN30)', 'rate': 0.10, 'risk': '⭐⭐⭐', 'liquid': 'Cao'},
      {'name': '💹 Cổ phiếu VN', 'rate': 0.14, 'risk': '⭐⭐⭐⭐', 'liquid': 'Cao'},
      {'name': '🥇 Vàng SJC', 'rate': 0.12, 'risk': '⭐⭐⭐', 'liquid': 'Cao'},
      {'name': '🏠 BĐS (REITs)', 'rate': 0.09, 'risk': '⭐⭐⭐', 'liquid': 'Thấp'},
      {'name': '₿ Crypto (BTC)', 'rate': 0.25, 'risk': '⭐⭐⭐⭐⭐', 'liquid': 'Cao'},
    ];

    final lines = channels.map((ch) {
      final rate = ch['rate'] as double;
      final v5 = compound(investable, rate, 5);
      final total = investable * 60;
      final profit = v5 - total;
      return '${ch['name']}\n'
          '  Lãi: ${(rate * 100).toStringAsFixed(1)}%/năm | Rủi ro: ${ch['risk']} | Thanh khoản: ${ch['liquid']}\n'
          '  5 năm: ${CurrencyFormatter.formatVND(v5)} (+${CurrencyFormatter.formatVND(profit)} lãi)';
    }).join('\n\n');

    return '📊 **SO SÁNH KÊNH ĐẦU TƯ**\n\n'
        '💰 Đầu tư: ${CurrencyFormatter.formatVND(investable)}/tháng\n\n'
        '$lines\n\n'
        '💡 **Gợi ý phân bổ:**\n'
        '  🏦 40% Tiết kiệm (an toàn)\n'
        '  📊 30% ETF/Quỹ mở (tăng trưởng)\n'
        '  💹 20% Cổ phiếu (lợi nhuận cao)\n'
        '  🥇 10% Vàng (phòng hộ)';
  }

  /// Dự đoán dòng tiền
  String _predictCashFlow(double income, double expense, double budget, List<TransactionModel>? transactions) {
    final now = DateTime.now();
    final daysPassed = now.day;

    final dailyExpense = daysPassed > 0 ? expense / daysPassed : 0.0;
    final dailyIncome = daysPassed > 0 ? income / daysPassed : 0.0;
    final netDaily = dailyIncome - dailyExpense;

    // Dự báo 4 tuần tới
    final weeks = <String>[];
    double runningBalance = income - expense;
    for (int w = 1; w <= 4; w++) {
      final weekExpense = dailyExpense * 7;
      final weekIncome = w == 1 || w == 4 ? dailyIncome * 7 * 1.5 : dailyIncome * 7 * 0.5; // Lương thường đầu/cuối tháng
      runningBalance += weekIncome - weekExpense;
      final emoji = runningBalance >= 0 ? '🟢' : '🔴';
      weeks.add('$emoji Tuần $w: Thu ~${CurrencyFormatter.formatVND(weekIncome)} | Chi ~${CurrencyFormatter.formatVND(weekExpense)} | Dư: ${CurrencyFormatter.formatVND(runningBalance)}');
    }

    // Cash runway
    String runway = '';
    if (income > 0 && expense > income) {
      runway = '\n⚠️ **Cash Runway:** Chi tiêu đang lớn hơn thu nhập!\n'
          'Nếu không thay đổi, sẽ thâm hụt ${CurrencyFormatter.formatVND((expense - income) * 12)}/năm';
    } else if (income > 0) {
      runway = '\n✅ **Dòng tiền dương:** +${CurrencyFormatter.formatVND(netDaily * 30)}/tháng';
    }

    return '💧 **DỰ BÁO DÒNG TIỀN**\n\n'
        '📊 **Hiện tại:**\n'
        '  💵 Thu TB: ${CurrencyFormatter.formatVND(dailyIncome)}/ngày\n'
        '  💸 Chi TB: ${CurrencyFormatter.formatVND(dailyExpense)}/ngày\n'
        '  💰 Dòng ròng: ${netDaily >= 0 ? '+' : ''}${CurrencyFormatter.formatVND(netDaily)}/ngày\n\n'
        '📅 **Dự báo 4 tuần tới:**\n${weeks.join('\n')}\n'
        '$runway\n\n'
        '📈 **Dự báo 3 tháng tới:**\n'
        '  Tháng ${now.month + 1}: Dư ~${CurrencyFormatter.formatVND((income - expense) * 1)}\n'
        '  Tháng ${now.month + 2}: Dư ~${CurrencyFormatter.formatVND((income - expense) * 2)}\n'
        '  Tháng ${now.month + 3}: Dư ~${CurrencyFormatter.formatVND((income - expense) * 3)}';
  }

  // ============================================
  // 🧮 TÍNH TOÁN THÔNG MINH
  // ============================================

  /// Kiểm tra xem tin nhắn có chứa số tiền cụ thể không
  bool _hasSpecificAmounts(String msg) {
    // Match: 10tr, 500tr, 10 triệu, 1ty, 100k, 5m, etc.
    return RegExp(r'\d+\s*(tr|triệu|trieu|tỷ|ty|k|m|nghìn|nghin|triệu đồng|trăm)').hasMatch(msg.toLowerCase());
  }

  /// Trích xuất số tiền từ text
  List<double> _extractAmounts(String msg) {
    final amounts = <double>[];
    final lower = msg.toLowerCase();

    // Match patterns like: 10tr, 500tr, 10 triệu, 1ty, 100k, 5m, 1 tỷ
    final patterns = [
      RegExp(r'(\d+[.,]?\d*)\s*(tỷ|ty)'),      // tỷ = 1,000,000,000
      RegExp(r'(\d+[.,]?\d*)\s*(tr|triệu|trieu)'), // triệu = 1,000,000
      RegExp(r'(\d+[.,]?\d*)\s*(k|nghìn|nghin)'),  // nghìn = 1,000
      RegExp(r'(\d+[.,]?\d*)\s*(m)(?![a-z])'),      // m = triệu
    ];
    final multipliers = [1000000000.0, 1000000.0, 1000.0, 1000000.0];

    for (int i = 0; i < patterns.length; i++) {
      for (var match in patterns[i].allMatches(lower)) {
        final numStr = match.group(1)?.replaceAll(',', '.') ?? '0';
        final num = double.tryParse(numStr) ?? 0;
        if (num > 0) amounts.add(num * multipliers[i]);
      }
    }

    // Sort ascending
    amounts.sort();
    return amounts;
  }

  /// Xử lý câu hỏi tính toán cụ thể
  String _smartCalculation(String userMessage, double income, double expense) {
    final lower = userMessage.toLowerCase();
    final amounts = _extractAmounts(userMessage);

    // === Gửi ngân hàng bao lâu có X ===
    if ((lower.contains('gửi') || lower.contains('gui') || lower.contains('tiết kiệm') || lower.contains('tiet kiem')) &&
        (lower.contains('bao lâu') || lower.contains('bao lau') || lower.contains('khi nào') || lower.contains('khi nao') || lower.contains('mấy năm') || lower.contains('may nam'))) {
      if (amounts.length >= 2) {
        final monthlyDeposit = amounts[0]; // Số nhỏ hơn = gửi hàng tháng
        final target = amounts[1];         // Số lớn hơn = mục tiêu
        return _calcDepositToTarget(monthlyDeposit, target);
      } else if (amounts.length == 1) {
        // Chỉ có 1 số → đoán ngữ cảnh
        if (lower.contains('có') || lower.contains('được') || lower.contains('đạt')) {
          final target = amounts[0];
          final monthlyDeposit = income - expense > 0 ? income - expense : income * 0.2;
          return _calcDepositToTarget(monthlyDeposit, target);
        } else {
          final monthlyDeposit = amounts[0];
          return _calcDepositGrowth(monthlyDeposit);
        }
      }
    }

    // === Bao lâu có X (không nói gửi) ===
    if ((lower.contains('bao lâu') || lower.contains('bao lau') || lower.contains('mấy năm')) && amounts.isNotEmpty) {
      final target = amounts.last; // Số lớn nhất = mục tiêu
      final monthlySaving = income - expense > 0 ? income - expense : income * 0.1;
      return _calcDepositToTarget(monthlySaving, target);
    }

    // === Gửi X thì sau Y năm có bao nhiêu ===
    if ((lower.contains('gửi') || lower.contains('gui')) && amounts.isNotEmpty) {
      return _calcDepositGrowth(amounts.first);
    }

    // === Tính lãi suất / lãi kép ===
    if ((lower.contains('lãi') || lower.contains('lai')) && amounts.isNotEmpty) {
      return _calcDepositGrowth(amounts.first);
    }

    // Default: tính với số tiền được đề cập
    if (amounts.isNotEmpty) {
      if (amounts.length >= 2) {
        return _calcDepositToTarget(amounts[0], amounts[1]);
      }
      return _calcDepositGrowth(amounts.first);
    }

    // Không tìm thấy số → hướng dẫn
    return '🧮 **Hãy cung cấp thêm thông tin:**\n\n'
        '💡 **Ví dụ câu hỏi:**\n'
        '• "Gửi 10tr/tháng bao lâu có 500tr?"\n'
        '• "Gửi 5tr/tháng sau 5 năm được bao nhiêu?"\n'
        '• "Bao lâu tôi có 1 tỷ?"\n'
        '• "Đầu tư 20tr/tháng lãi suất bao nhiêu?"\n\n'
        '📊 Tôi sẽ tính toán chi tiết cho bạn!';
  }

  /// Tính: Gửi X/tháng, bao lâu có Y?
  String _calcDepositToTarget(double monthly, double target) {
    if (monthly <= 0) return '⚠️ Số tiền gửi hàng tháng phải > 0!';
    if (target <= monthly) return '🎉 Bạn đã có đủ rồi! Chỉ cần 1 tháng là đạt ${CurrencyFormatter.formatVND(target)}';

    final rates = [
      {'name': '🏦 Gửi TK ngân hàng', 'rate': 0.055},
      {'name': '📜 Trái phiếu', 'rate': 0.075},
      {'name': '📊 Quỹ mở/ETF', 'rate': 0.10},
      {'name': '📈 Chứng khoán', 'rate': 0.14},
    ];

    final lines = rates.map((r) {
      final annualRate = r['rate'] as double;
      final monthlyRate = annualRate / 12;
      double accumulated = 0;
      int months = 0;
      while (accumulated < target && months < 1200) { // max 100 năm
        accumulated = (accumulated + monthly) * (1 + monthlyRate);
        months++;
      }
      final years = months ~/ 12;
      final remainMonths = months % 12;
      String timeStr;
      if (years > 0 && remainMonths > 0) timeStr = '**$years năm $remainMonths tháng**';
      else if (years > 0) timeStr = '**$years năm**';
      else timeStr = '**$months tháng**';

      final totalDeposited = monthly * months;
      final interest = accumulated - totalDeposited;
      return '${r['name']} (${(annualRate * 100).toStringAsFixed(1)}%/năm):\n'
          '  ⏱️ $timeStr\n'
          '  💰 Tổng gửi: ${CurrencyFormatter.formatVND(totalDeposited)}\n'
          '  📈 Tiền lãi: ${CurrencyFormatter.formatVND(interest)}';
    }).join('\n\n');

    // Không tính lãi
    final noInterestMonths = (target / monthly).ceil();
    final noInterestYears = noInterestMonths ~/ 12;
    final noInterestRemain = noInterestMonths % 12;
    String noInterestTime;
    if (noInterestYears > 0 && noInterestRemain > 0) noInterestTime = '$noInterestYears năm $noInterestRemain tháng';
    else if (noInterestYears > 0) noInterestTime = '$noInterestYears năm';
    else noInterestTime = '$noInterestMonths tháng';

    return '🧮 **GỬI ${CurrencyFormatter.formatVND(monthly)}/tháng → ${CurrencyFormatter.formatVND(target)}**\n\n'
        '🐢 Không tính lãi: $noInterestTime\n\n'
        '$lines\n\n'
        '💡 **Kết luận:** Gửi tiết kiệm giúp nhanh hơn **${((noInterestMonths - (target / (monthly * 1.055)).ceil()) / noInterestMonths * 100).abs().toStringAsFixed(0)}%** so với giữ tiền mặt!';
  }

  /// Tính: Gửi X/tháng, sau 1/3/5/10 năm có bao nhiêu?
  String _calcDepositGrowth(double monthly) {
    if (monthly <= 0) return '⚠️ Số tiền phải > 0!';

    double compound(double m, double annualRate, int years) {
      final mr = annualRate / 12;
      double t = 0;
      for (int i = 0; i < years * 12; i++) t = (t + m) * (1 + mr);
      return t;
    }

    final periods = [1, 3, 5, 10, 20];
    final rate = 0.055; // Ngân hàng
    final rateStock = 0.12; // Chứng khoán

    final bankLines = periods.map((y) {
      final v = compound(monthly, rate, y);
      final deposited = monthly * y * 12;
      return '  $y năm: ${CurrencyFormatter.formatVND(v)} (lãi +${CurrencyFormatter.formatVND(v - deposited)})';
    }).join('\n');

    final stockLines = periods.map((y) {
      final v = compound(monthly, rateStock, y);
      final deposited = monthly * y * 12;
      return '  $y năm: ${CurrencyFormatter.formatVND(v)} (lãi +${CurrencyFormatter.formatVND(v - deposited)})';
    }).join('\n');

    return '📈 **GỬI ${CurrencyFormatter.formatVND(monthly)}/tháng**\n\n'
        '🏦 **Ngân hàng (5.5%/năm):**\n$bankLines\n\n'
        '📊 **Đầu tư (12%/năm):**\n$stockLines\n\n'
        '💡 *Lãi kép là "kỳ quan thứ 8" - càng sớm bắt đầu càng tốt!*';
  }

  /// Fallback thông minh khi không match keyword
  String _smartFallback(String userMessage, double income, double expense, double balance, double budget, List<TransactionModel>? transactions) {
    final lower = userMessage.toLowerCase();

    // Nhận diện câu hỏi dạng có/không
    if (lower.contains('có nên') || lower.contains('nên không') || lower.contains('có được')) {
      return '🤔 **Tư vấn dựa trên dữ liệu của bạn:**\n\n'
          '📊 Thu: ${CurrencyFormatter.formatVND(income)} | Chi: ${CurrencyFormatter.formatVND(expense)}\n'
          '💰 Dư: ${CurrencyFormatter.formatVND(balance)}/tháng\n\n'
          '${balance > 0 ? '✅ Bạn đang có dư, có thể cân nhắc!' : '⚠️ Bạn đang chi nhiều hơn thu, cần cẩn thận!'}\n\n'
          '💡 Hãy hỏi cụ thể hơn, ví dụ:\n'
          '• "Dự đoán chi tiêu cuối tháng"\n'
          '• "Gửi 10tr/tháng bao lâu có 500tr?"\n'
          '• "So sánh kênh đầu tư"';
    }

    // Nhận diện câu hỏi về tiền/cách
    if (lower.contains('làm sao') || lower.contains('cách nào') || lower.contains('thế nào') || lower.contains('giúp')) {
      final monthlySaving = income - expense;
      return '💡 **GỢI Ý CHO BẠN:**\n\n'
          '📊 Hiện tại: Thu ${CurrencyFormatter.formatVND(income)} - Chi ${CurrencyFormatter.formatVND(expense)} = Dư ${CurrencyFormatter.formatVND(monthlySaving)}\n\n'
          '${monthlySaving > 0 ? '✅ Bạn đang tiết kiệm được ${CurrencyFormatter.formatVND(monthlySaving)}/tháng\n\n'
              '🎯 **Gợi ý:**\n'
              '• Gửi tiết kiệm ngân hàng (5.5%/năm)\n'
              '• Đầu tư quỹ mở ETF (10%/năm)\n'
              '• Tăng tiết kiệm lên 30% thu nhập = ${CurrencyFormatter.formatVND(income * 0.3)}' : '⚠️ Bạn đang chi nhiều hơn thu!\n\n'
              '🎯 **Cần:**\n'
              '• Cắt giảm chi tiêu không cần thiết\n'
              '• Tăng thu nhập thêm\n'
              '• Đặt ngân sách hàng tháng'}\n\n'
          '📌 Hỏi: "dự đoán", "xu hướng", "đầu tư", "rủi ro" để phân tích chi tiết!';
    }

    // Default: Tổng quan + gợi ý câu hỏi
    return '${_offlineOverview(income, expense, balance, budget, transactions)}\n\n'
        '💬 **Hỏi thêm:**\n'
        '🔮 "Dự đoán cuối tháng"\n'
        '📈 "Xu hướng tài chính"\n'
        '💹 "Đầu tư" hoặc "Gửi 10tr bao lâu có 500tr?"\n'
        '🛡️ "Đánh giá rủi ro"\n'
        '🎭 "Kịch bản tài chính"';
  }

  /// Clear chat history and reset providers
  void clearHistory() {
    _chatHistory.clear();
    for (var p in _providers) p.isAvailable = true;
    _currentProviderIndex = 0;
    _callCount = 0;
  }
}
