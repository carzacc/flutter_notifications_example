import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as statusCodes;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const URL = 'ws://YOUR.SERVER.URL:PORT';


void main() =>
  runApp(MyApp());


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FauxLoginPage(),
    );
  }
}

class FauxLoginPage extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  void goToMainPage(String nickname, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementPage(nickname)
      )
    );
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: AppBar(title: Text("Login Page")),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Nickname"
              ),
              onSubmitted: (nickname) => goToMainPage(nickname, context),
            ),
            FlatButton(
              onPressed: () => goToMainPage(controller.text, context),
              child: Text("Log In")
            )
          ],
        ),
      )
    );
}

class AnnouncementPage extends StatefulWidget {
  AnnouncementPage(this.nickname);

  final String nickname;

  @override
  AnnouncementPageState createState() => AnnouncementPageState();
}

class AnnouncementPageState extends State<AnnouncementPage> {
  WebSocketChannel channel = WebSocketChannel.connect(Uri.parse(URL));
  TextEditingController controller = TextEditingController();
  var sub;
  String text;

  @override
  void initState() {
    super.initState();

    FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    var androidInit = AndroidInitializationSettings('app_icon');
    var iOSInit = IOSInitializationSettings();
    var init = InitializationSettings(androidInit, iOSInit);
    notifications.initialize(init).then((done) {
      sub = channel.stream.listen((newData) {
        setState(() {
          text = newData;
        });

        notifications.show(
            0,
            "New announcement",
            newData,
            NotificationDetails(
                AndroidNotificationDetails(
                    "announcement_app_0",
                    "Announcement App",
                    ""
                ),
                IOSNotificationDetails()
            )
        );
      });
    });
  }

   @override
   void dispose() {
     super.dispose();
     channel.sink.close(statusCodes.goingAway);
     sub.cancel();
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Announcement Page"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            text != null ?
              Text(text, style: Theme.of(context).textTheme.display1)
            :
              CircularProgressIndicator(),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Enter your message here"
              ),
            )
          ],
        )
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          channel.sink.add("${widget.nickname}: ${controller.text}");
        }
      ),
    );
  }
}
