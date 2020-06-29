import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hacube/components/cube.dart';
import 'package:hacube/cube.dart';
import 'package:hacube/event.dart';
import 'package:hacube/screens/play.dart';

import 'components/button.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final cube = Cube();
  EventBus eventBus = EventBus();

  void autoPlayNavWrap(Future future) async {
    eventBus.fire(AutoPlayEvent(play: false));
    await future;
    eventBus.fire(AutoPlayEvent(play: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/glow.png"),
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: AutoPlayCubeWidget(cube: cube, eventBus: eventBus),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    CPButton(
                      onPressed: () async {
                        autoPlayNavWrap(Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PlayScreen()),
                        ));
                      },
                      padding: EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 8,
                      ),
                      child: Text("START"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
