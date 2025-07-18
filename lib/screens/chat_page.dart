import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/services.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({Key? key}) : super(key: key);

  @override
  _AIChatPageState createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _selectedEndpoint = 'chat';
  final String _baseApiUrl = "http://192.168.0.105:8000";

  final List<Map<String, dynamic>> _endpoints = [
    {'value': 'chat', 'label': 'Qwen Developer Mode'},
    {'value': 'summarise', 'label': 'BART Quick Summary'},
  ];

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final String userText = _controller.text.trim();

    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: userText,
          isUser: true,
          timestamp: DateTime.now(),
          endpoint: _selectedEndpoint,
        ),
      );
      _isLoading = true;
      _controller.clear();
    });

    try {
      final apiUrl = '$_baseApiUrl/$_selectedEndpoint';
      final Map<String, dynamic> requestBody = {'message': userText};

      if (_selectedEndpoint == 'chat') {
        requestBody['max_length'] = 200;
        requestBody['temperature'] = 0.7;
      } else {
        requestBody['text'] = userText;
        requestBody['max_length'] = 100;
        requestBody['temperature'] = 0.3;
      }

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: data[_selectedEndpoint == 'chat' ? 'reply' : 'summary'],
              isUser: false,
              timestamp: DateTime.now(),
              endpoint: _selectedEndpoint,
            ),
          );
        });
      } else {
        throw Exception("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: "Error: ${e.toString().replaceAll("Exception: ", "")}",
            isUser: false,
            isError: true,
            timestamp: DateTime.now(),
            endpoint: _selectedEndpoint,
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.android, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Evos",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Online",
                  style: TextStyle(color: Colors.green[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildEndpointSelector(),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0 && _isLoading) return _buildTypingIndicator();
                return _buildMessageBubble(
                  _messages[index - (_isLoading ? 1 : 0)],
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEndpointSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DropdownButtonFormField2<String>(
        isExpanded: true,

        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        hint: const Text('Select Mode', style: TextStyle(fontSize: 16)),

        // ✅ Move icon here instead of inside ButtonStyleData
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
        ),

        buttonStyleData: const ButtonStyleData(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white),
          // ❌ Remove `icon:` from here
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(15)),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black12,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        items: _endpoints
            .map(
              (endpoint) => DropdownMenuItem<String>(
                value: endpoint['value'],
                child: Text(
                  endpoint['label'],
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            )
            .toList(),
        value: _selectedEndpoint,
        onChanged: (value) {
          setState(() {
            _selectedEndpoint = value!;
          });
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,

                style: const TextStyle(fontSize: 16, color: Colors.black),

                decoration: const InputDecoration.collapsed(
                  hintText: "Message Evos...",
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF10A37F)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final color = isUser ? const Color(0xFF10A37F) : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(message.text, style: TextStyle(color: textColor)),
                if (!isUser) // 👈 Show copy button only for AI messages
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 18,
                        color: Colors.grey,
                      ),
                      tooltip: "Copy",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text("Evos is typing..."),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final DateTime timestamp;
  final String endpoint;

  ChatMessage({
    required this.text,
    this.isUser = false,
    this.isError = false,
    required this.timestamp,
    required this.endpoint,
  });
}
