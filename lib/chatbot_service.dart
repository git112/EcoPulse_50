import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  static Future<String> getAIResponse(String query) async {
    String apiKey = "YOUR_OPENAI_API_KEY";  // Replace with your API key
    String apiUrl = "https://api.openai.com/v1/chat/completions";

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": "You are an AI assistant."},
          {"role": "user", "content": query}
        ]
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"];
    } else {
      return "Error: Unable to fetch response.";
    }
  }
}