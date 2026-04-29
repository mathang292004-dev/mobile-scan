import 'dart:io';
import 'package:flutter/material.dart';

class SecurityTestPage extends StatelessWidget {
  const SecurityTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security Test")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // ❌ CRITICAL: Hardcoded secret
              const apiKey = "123456789-SECRET-KEY-DO-NOT-EXPOSE";
              print(apiKey);
            },
            child: const Text("Print Secret"),
          ),

          ElevatedButton(
            onPressed: () async {
              // ❌ HIGH: Insecure HTTP request
              HttpClient client = HttpClient();
              var request = await client.getUrl(Uri.parse("http://example.com/data"));
              var response = await request.close();
              print(response.statusCode);
            },
            child: const Text("Insecure HTTP"),
          ),

          ElevatedButton(
            onPressed: () {
              // ❌ HIGH: Path traversal risk
              String userInput = "../../etc/passwd";
              File file = File("/storage/emulated/0/" + userInput);
              file.readAsString().then((value) {
                print(value);
              });
            },
            child: const Text("Path Traversal"),
          ),

          ElevatedButton(
            onPressed: () {
              // ❌ MEDIUM: WebView unsafe JS enabled simulation
              print("WebView JavaScript enabled risk");
            },
            child: const Text("WebView Risk"),
          ),

          ElevatedButton(
            onPressed: () {
              // ❌ MEDIUM: Weak random usage
              var token = DateTime.now().millisecondsSinceEpoch.toString();
              print(token);
            },
            child: const Text("Weak Token"),
          ),
        ],
      ),
    );
  }
}
