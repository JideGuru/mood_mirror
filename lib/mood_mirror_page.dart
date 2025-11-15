import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class MoodMirrorPage extends StatefulWidget {
  const MoodMirrorPage({super.key});

  @override
  State<MoodMirrorPage> createState() => _MoodMirrorPageState();
}

class _MoodMirrorPageState extends State<MoodMirrorPage> {
  final TextEditingController _moodController = TextEditingController();
  bool _isInstallingModel = true;
  bool _isLoading = false;

  String _detectedMood = '—';
  String _message = '—';

  @override
  void initState() {
    super.initState();
    _installModel();
  }

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _analyzeMood() async {
    final input = _moodController.value.text.trim();
    if (input.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _detectedMood = '—';
      _message = '—';
    });

    try {
      final inferenceModel = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.gpu,
      );

      final chat = await inferenceModel.createChat();
      // Add system message to set the context
      await chat.addQueryChunk(
        Message.text(
          text: """
You are an emotion-analysis assistant.
Your job is to read the user's message and output ONLY valid JSON.

STRICT FORMAT:
{
  "mood": "<ONE_WORD>",
  "message": "<SHORT_SUPPORTIVE_MESSAGE_UNDER_15_WORDS>"
}

Rules:
- "mood" MUST be exactly one word (e.g., calm, anxious, happy).
- "message" MUST be a short supportive sentence under 15 words.
- NO explanation, NO reasoning, NO text outside the JSON.
""",
        ),
      );

      // Add the user's actual input
      await chat.addQueryChunk(
        Message.text(
          text:
              """
      $input
      
      Remember:
      Respond ONLY with JSON in the required format.
      """,
          isUser: true,
        ),
      );

      // Generate the response
      final response = await chat.generateChatResponse();

      String fullResponse = '';
      if (response is TextResponse) {
        fullResponse = response.token.trim();
      }

      print('fullResponse: $fullResponse');
      // Parse JSON response
      String mood = '-';
      String message = '-';

      try {
        // Remove markdown code blocks if present
        final cleanedResponse = fullResponse
            .replaceAll(RegExp(r'```json', caseSensitive: false), '')
            .replaceAll(RegExp(r'```'), '')
            .trim();

        final Map<String, dynamic> jsonResponse = jsonDecode(cleanedResponse);

        mood = jsonResponse['mood']?.toString() ?? 'Unknown';
        message =
            jsonResponse['message']?.toString() ?? 'Take care of yourself!';
      } catch (e) {
        print('Error parsing JSON: $e');
        // Fallback to defaults
      }

      setState(() {
        _detectedMood = mood;
        _message = message;
        _isLoading = false;
      });

      chat.clearHistory();
    } catch (e) {
      setState(() {
        _detectedMood = 'Error';
        _message = 'Sorry, something went wrong. Please try again.';
        _isLoading = false;
      });
      print('Error analyzing mood: $e');
    }
  }

  Future<void> _installModel() async {
    setState(() {
      _isInstallingModel = true;
    });

    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromAsset('assets/models/gemma3-1B-it-int4.task')
        .withProgress((progress) => print('$progress%'))
        .install();

    setState(() {
      _isInstallingModel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _isInstallingModel
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: kToolbarHeight),
                  // Intro text
                  const SizedBox(height: 8),
                  const Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your thoughts and let\'s analyze your mood',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF718096),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Text input area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _moodController,
                      maxLines: 5,
                      minLines: 5,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF2D3748),
                      ),
                      decoration: InputDecoration(
                        hintText: 'I feel...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Analyze button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, Colors.purple],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _analyzeMood,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white.withValues(
                                  alpha: _isLoading ? 0.5 : 1,
                                ),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Analyze Mood',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(
                                    alpha: _isLoading ? 0.5 : 1,
                                  ),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Loading indicator
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Analyzing your mood...',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Result section
                  if (!_isLoading && _detectedMood != '—')
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      Colors.purple,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_emotions,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Analysis Results',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3748),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Detected mood
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Mood:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _detectedMood,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Message
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.message_outlined,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Message:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF718096),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _message,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF4A5568),
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
