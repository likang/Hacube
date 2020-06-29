import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:hacube/components/button.dart';
import 'package:hacube/components/clock.dart';
import 'package:hacube/components/cube.dart';
import 'package:hacube/cube.dart';
import 'package:hacube/event.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class PlayScreen extends StatefulWidget {
  @override
  PlayScreenState createState() {
    return PlayScreenState();
  }
}

class PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  Cube cube;

  EventBus eventBus = EventBus();

  AnimationController shuffleController;

  bool inAnimation = false;
  double animationLastAngle;
  Vector3 animationAxis;
  List<CubePiece> animationPieces;

  bool waitInitShuffle = true;
  bool showFinished = false;

  @override
  void initState() {
    super.initState();

    shuffleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      upperBound: math.pi / 2,
      vsync: this,
    );
    shuffleController.addListener(() {
      setState(() {
        cube.rotatePieces(
          animationAxis,
          animationPieces,
          shuffleController.value - animationLastAngle,
        );
        animationLastAngle = shuffleController.value;
        // The state that has changed here is the animation object’s value.
      });
    });

    eventBus.on<CubeFinishedEvent>().listen((event) {
      setState(() {
        showFinished = true;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  void _afterLayout(_) async {
    Size screenSize = MediaQuery.of(context).size;
    double cubeSize = min(screenSize.width, screenSize.height) / 7;
    cube = Cube(pieceSize: cubeSize);

    setState(() {});

    await shuffle();

    setState(() {
      waitInitShuffle = false;
    });
  }

  Future<Null> shuffle([int steps = 20]) async {
    if (inAnimation) {
      return;
    }
    inAnimation = true;
    while (steps > 0) {
      steps--;

      final rng = math.Random();
      animationAxis = Vector3.all(0)..[rng.nextInt(3)] = 1;

      final corners = const [0, 2, 6, 8, 18, 20, 24, 26];
      final i = rng.nextInt(8);
      final piece = cube.positionMap[corners[i]];
      animationLastAngle = 0;
      animationPieces = cube.findPiecesOnSamePlane(piece, animationAxis);

      await shuffleController.forward(from: animationLastAngle);
      cube.rotatePiecePositions(animationAxis, 1, animationPieces);
    }
    inAnimation = false;
  }

  @override
  void dispose() {
    shuffleController.stop();
    shuffleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget cubeArea;
    if (showFinished) {
      cubeArea = Center(
        child: CPButton(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Text("Congradulations !"),
          onPressed: () {},
        ),
      );
    } else {
      if (cube != null) {
        cubeArea = PlayCubeWidget(
          cube: cube,
          touchable: !inAnimation,
          eventBus: eventBus,
        );
      }
    }

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
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            CPButton(
                              child: Text(
                                "  BACK  ",
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                Navigator.maybePop(context);
                              },
                            ),
                            Expanded(
                              flex: 1,
                              child: ClockWidget(
                                running: !waitInitShuffle && !showFinished,
                                eventBus: eventBus,
                              ),
                            ),
                            CPButton(
                              child: Text(
                                "RESTART",
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                if (inAnimation) {
                                  return;
                                }

                                cube.reset();

                                eventBus.fire(ClockResetEvent());
                                setState(() {
                                  waitInitShuffle = true;
                                  showFinished = false;
                                });
                                await shuffle();
                                setState(() {
                                  waitInitShuffle = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          child: cubeArea,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
