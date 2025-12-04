import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../main.dart';

class MedAssistHomePage extends StatefulWidget {
  const MedAssistHomePage({super.key});

  @override
  State<MedAssistHomePage> createState() => _MedAssistHomePageState();
}

class _MedAssistHomePageState extends State<MedAssistHomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isModelInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  Future<void> _initGemini() async {
    try {
      final List<String> filePaths = [
        'data/KZ.2.I15_ekspozycja_zawodowa_zasady_postepowania.txt',
        'data/OP.2I1_postepowanie_z_pacjentem_szczegolnym_NN_bez_kontaktu_bez_adresu.txt',
        'data/OP.3_profilaktyka_i_leczenie_odlezyn.txt',
      ];

      StringBuffer allProceduresBuffer = StringBuffer();

      for (String path in filePaths) {
        try {
          final String content = await rootBundle.loadString(path);
          allProceduresBuffer.writeln("\n--- BEGIN PROCEDURE: $path ---");
          allProceduresBuffer.writeln(content);
          allProceduresBuffer.writeln("--- END PROCEDURE ---\n");
        } catch (e) {
          debugPrint(
            "Warning: Procedure file not found: $path. AI will run without it. Error: $e",
          );
        }
      }

      final basePrompt =
          dotenv.env['SYSTEM_PROMPT'] ?? "You are a helpful assistant.";

      final combinedSystemPrompt =
          """
      $basePrompt

      ${allProceduresBuffer.toString()}
      """;

      debugPrint("Combined System Prompt:\n $combinedSystemPrompt");

      _model = GenerativeModel(
        model: 'gemini-2.5-pro',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        systemInstruction: Content.system(combinedSystemPrompt),
      );

      _chat = _model.startChat();

      if (mounted) {
        setState(() {
          _isModelInitialized = true;
        });
      }

      debugPrint(
        "Gemini initialized with context length: ${allProceduresBuffer.length}",
      );
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': "System Error: Failed to initialize AI. \n$e",
          });
        });
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    if (!_isModelInitialized) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              "Error: API Key not set or model failed to initialize. Please check your code.",
        });
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final responseText = response.text;

      if (mounted && responseText != null) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': responseText});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                "Error: $e\n\n(If you see a 404, try changing the model name in the code to 'gemini-pro')",
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset("assets/icon/icon.png", width: 32, height: 32),
            const SizedBox(width: 8),
            Text(
              'MediOrange',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeView(theme)
                : _buildChatList(theme),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(77),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/icon/icon.png",
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Witamy w MediOrange',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Twój asystent AI wspomagający procedury medyczne i protokoły. Zapytaj o wytyczne kliniczne, najlepsze praktyki lub kroki proceduralne.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildSuggestionCard(
              theme,
              "Zgłosił się pacjent NN na Szpitalny Oddział Ratunkowy. Jakie są kroki postępowania z takim pacjentem?",
              Icons.monitor_heart,
            ),
            const SizedBox(height: 16),
            _buildSuggestionCard(
              theme,
              "Zakułam się igłą z krwią pacjenta. Co mam robić?",
              Icons.monitor_heart,
            ),
            const SizedBox(height: 16),
            _buildSuggestionCard(
              theme,
              "Zauważyłam odleżynę u pacjenta. Co mam robić?",
              Icons.monitor_heart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(ThemeData theme, String text, IconData icon) {
    return InkWell(
      onTap: () => _sendMessage(text),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(
                  20,
                ).copyWith(bottomLeft: Radius.zero),
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: LoadingAnimationWidget.waveDots(
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 24,
                ),
              ),
            ),
          );
        }

        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.userMessage
                  : theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isUser ? Radius.zero : null,
                bottomLeft: !isUser ? Radius.zero : null,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MarkdownBody(
                  data: msg['content']!,
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyLarge?.copyWith(
                      color: isUser
                          ? AppColors.textOnPrimary
                          : theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg['content']!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Skopiowano do schowka'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: isUser
                          ? AppColors.textOnPrimary.withAlpha(179)
                          : theme.colorScheme.onSecondaryContainer.withAlpha(
                              179,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Zapytaj o procedurę medyczną...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _sendMessage(_controller.text),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.sendButton,
              foregroundColor: AppColors.textOnPrimary,
            ),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
