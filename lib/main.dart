// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'ChatGPT';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            _title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const ChatScreen(),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final int id = DateTime.now().millisecondsSinceEpoch;
  static const interVal = 12.0;
  static const avatarRadius = 20.0;
  bool isResponsing = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Divider(
          height: 1,
        ),
        Expanded(
          child: Container(
            alignment: Alignment.topCenter,
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                ChatMessage chatMessage = _messages[index];
                return chatMessage.isUserMessage
                    ? Container(
                        padding: const EdgeInsets.all(interVal),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //镜像填充头像
                            const SizedBox(
                              width: 2 * avatarRadius,
                            ),
                            //文本内容
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                    margin: const EdgeInsets.only(
                                        left: interVal, right: interVal),
                                    padding: const EdgeInsets.only(
                                        left: interVal,
                                        right: interVal - 2,
                                        top: interVal - 4,
                                        bottom: interVal - 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.blue[100],
                                    ),
                                    child: SelectableText(chatMessage.text,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Roboto',
                                        ))),
                              ),
                            ),
                            //头像容器
                            Container(
                              width: 2 * avatarRadius,
                              height: 2 * avatarRadius,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: AssetImage('images/user_avatar.jpg'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(interVal),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //头像容器
                            Container(
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: AssetImage('images/gpt_avatar.png'),
                                ),
                              ),
                            ),
                            //文本内容
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      left: interVal, right: interVal),
                                  padding: const EdgeInsets.only(
                                      left: interVal,
                                      right: interVal - 2,
                                      top: interVal - 4,
                                      bottom: interVal - 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.green[100],
                                  ),
                                  child: SelectableText(chatMessage.text,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Roboto',
                                      )),
                                ),
                              ),
                            ),
                            //镜像填充头像
                            const SizedBox(
                              width: 2 * avatarRadius,
                            ),
                          ],
                        ),
                      );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(
            left: 8,
            right: 1,
            top: 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[200], // 输入框背景色
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  // 嵌套一个Container来设置输入框样式
                  decoration: BoxDecoration(
                    color: Colors.white, // 输入框内部背景色，可以和外部容器的背景有所区别
                    borderRadius: BorderRadius.circular(50), // 圆角边框
                  ),
                  child: TextField(
                      controller: _textEditingController,
                      onSubmitted: _handleSubmitted,
                      maxLines: null, // 允许输入框换行
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: '请输入你的问题',
                        border: InputBorder.none, // 移除默认边框
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8), // 内容边距
                      ),
                      onTap: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                iconSize: 35,
                color: Colors.lightBlue,
                onPressed: () => _handleSubmitted(_textEditingController.text),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _handleSubmitted(String text) {
    // 空判断
    if (text.isEmpty) {
      return;
    }
    if (isResponsing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ChatGPT正在回复中...'),
        ),
      );
      return;
    }

    //滚动
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    isResponsing = true;
    _textEditingController.clear();

    //用户消息
    ChatMessage userMessage = ChatMessage(
      isUserMessage: true,
      text: text,
    );
    setState(() {
      _messages.insert(0, userMessage);
    });

    //gpt消息
    ChatMessage gptMessage = ChatMessage(
      isUserMessage: false,
      text: '',
    );
    setState(() {
      _messages.insert(0, gptMessage);
    });

    //获取GPT响应
    _sendRequest(text);
  }

  void _sendRequest(String text) async {
    final Dio dio = Dio();
    try {
      final response = await dio.post(
        '您的服务器地址/streamChatWithUser',
        data: text,
        queryParameters: {'user': 'User$id'},
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      Stream<List<int>> stream = response.data.stream;

      //监听数据流
      stream.listen(
        (List<int> data) => setState(() {
          _messages[0].text += utf8.decoder.convert(data);
        }),
        onDone: () => isResponsing = false,
      );
    } catch (error) {
      // 重新发送请求
      _sendRequest(text);
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  bool isUserMessage;
  String text;
  ChatMessage({required this.isUserMessage, required this.text});
}
