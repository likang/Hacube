import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart'
    show Vector3, Vector2, Matrix3, Matrix4;

enum FaceColor { YELLOW, GREEN, WHITE, BLUE, RED, ORANGE, BLACK }
enum Face { BACK, LEFT, TOP, FRONT, RIGHT, DOWN }
enum Corner { TL, BL, BR, TR }

class Cube {
  final double pieceSize;
  final double rotateRatio;

  Cube({this.pieceSize = 40.0})
      : rotateRatio = 2 * math.pi / (pieceSize * 3 * 4) {
    for (var i = 0; i < 27; i++) {
      final piece = CubePiece(this, i);
      pieces.add(piece);
      positionMap[piece.position] = piece;

      piece.surfaces.forEach((s) {
        if (piece.initPosition != 13) {
          orderedPaintSurfaces.add(s);
        }
      });
    }

    reset();
  }

  final Matrix4 cameraTransform = Matrix4.identity();
  final List<CubePiece> pieces = [];

  // surfaces in paint order, it does not include surfaces of center piece
  final List<PieceSurface> orderedPaintSurfaces = [];

  final Map<int, CubePiece> positionMap = Map();

  double rotatedOnX() {
    Vector3 r = cameraTransform.rotated3(axisX);
    return r.angleTo(axisX);
  }

  void reset() {
    cameraTransform.setIdentity();
    cameraTransform
      ..setIdentity()
      ..setEntry(3, 2, -0.0015)
      // from https://medium.com/flutter-io/perspective-on-flutter-6f832f4d912e
      ..rotate(Vector3(0.0, 1.0, 0.0), -math.pi / 4) // rotate left 45c
      ..rotate(Vector3(1.0, 0.0, -1.0), -math.pi / 8); // show the orange face
    pieces.forEach((p) {
      p.reset();
      positionMap[p.position] = p;
    });
    cameraChanged();
  }

  void cameraChanged() {
    pieces.forEach((p) => p.moved());
    reOrderPaintSurfaces();
  }

  void reOrderPaintSurfaces({Vector3 rotatingAxis}) {
    if (rotatingAxis == null) {
      orderedPaintSurfaces.sort((a, b) => a.origin.z.compareTo(b.origin.z));
      return;
    }

    // make 3 groups based on rotating axis
    int mainIndex = vectorMainIndex(rotatingAxis);
    List<PieceSurface> layerA = [];
    List<PieceSurface> layerB = [];
    List<PieceSurface> layerC = [];

    orderedPaintSurfaces.forEach((ps) {
      double pos = ps.piece.origin[mainIndex];
      if (almostZero(pos + pieceSize)) {
        layerA.add(ps);
      } else if (almostZero(pos - pieceSize)) {
        layerB.add(ps);
      } else {
        layerC.add(ps);
      }
    });

    // order every group
    layerA.sort((a, b) => a.origin.z.compareTo(b.origin.z));
    layerB.sort((a, b) => a.origin.z.compareTo(b.origin.z));
    layerC.sort((a, b) => a.origin.z.compareTo(b.origin.z));

    final originA = Vector3.zero()..[mainIndex] = -1;
    final originB = Vector3.zero()..[mainIndex] = 1;

    cameraTransform.perspectiveTransform(originA);
    cameraTransform.perspectiveTransform(originB);

    orderedPaintSurfaces.clear();

    if (originA.z < originB.z) {
      orderedPaintSurfaces.addAll(layerA);
      orderedPaintSurfaces.addAll(layerC);
      orderedPaintSurfaces.addAll(layerB);
    } else {
      orderedPaintSurfaces.addAll(layerB);
      orderedPaintSurfaces.addAll(layerC);
      orderedPaintSurfaces.addAll(layerA);
    }
  }

  List<PieceSurface> orderedTouchableSurfaces() {
    List<PieceSurface> result = [];
    pieces.forEach((p) {
      p.surfaces.forEach((s) {
        if (s.color != FaceColor.BLACK) {
          result.add(s);
        }
      });
    });

    result.sort((a, b) => b.origin.z.compareTo(a.origin.z));

    return result;
  }

  void cameraMoved(Vector3 axis, double angle) {
    cameraTransform.rotate(axis, angle);
    cameraChanged();
  }

  void cameraMovedOnRelative(Vector3 axis, double angle) {
    axis = axis.clone();
    axis.postmultiply(cameraTransform.getRotation());
    cameraMoved(axis, angle);
  }

  List<CubePiece> findPiecesOnSamePlane(CubePiece piece, Vector3 axis) {
    ensurePureAxis(axis);

    int mi = vectorMainIndex(axis);
    double value = piece.origin[mi];
    List<CubePiece> result = [];

    pieces.forEach((p) {
      if (almostZero(p.origin[mi] - value)) {
        result.add(p);
      }
    });
    return result;
  }

  void rotatePieces(Vector3 axis, List<CubePiece> pieces, double angle) {
    ensurePureAxis(axis);

    pieces.forEach((p) {
      Vector3 newAxis = axis.clone();
      newAxis.postmultiply(p.transform.getRotation());
      p.rotate(newAxis, angle);
    });
    reOrderPaintSurfaces(rotatingAxis: axis);
  }

  List<CubePiece> rotateFromOnePiece(
      CubePiece piece, Vector3 axis, double angle) {
    ensurePureAxis(axis);
    final pieces = findPiecesOnSamePlane(piece, axis);
    rotatePieces(axis, pieces, angle);
    return pieces;
  }

  void rotatePiecePositions(Vector3 axis, int step, List<CubePiece> pieces) {
    ensurePureAxis(axis);

    int mi = vectorMainIndex(axis);
    if (almostZero(pieces[0].origin[mi])) {
      // if we want to rotate the center plane, reverse rotate two side planes
      List<CubePiece> firstBatch = [];
      List<CubePiece> secondBatch = [];
      this.pieces.forEach((p) {
        if (almostZero(p.origin[mi] + pieceSize)) {
          firstBatch.add(p);
        } else if (almostZero(p.origin[mi] - pieceSize)) {
          secondBatch.add(p);
        }
      });

      rotatePiecePositions(axis, -step, firstBatch);
      rotatePiecePositions(axis, -step, secondBatch);
      return;
    }

    // 9 pieces will rotate
    final clockwise = const [
      [-1, 1],
      [0, 1],
      [1, 1],
      [1, 0],
      [1, -1],
      [0, -1],
      [-1, -1],
      [-1, 0],
    ];
    int ia = 0, ib = 0;
    if (mi == 0) {
      // z, y
      ia = 2;
      ib = 1;
    } else if (mi == 1) {
      // x, z
      ib = 2;
    } else if (mi == 2) {
      // y, x
      ia = 1;
    }

    final positions =
        (isAxisUpright(axis) ^ (step > 0)) ? clockwise.reversed : clockwise;

    final List<CubePiece> ordered = [];
    pieces = pieces.sublist(0);

    positions.forEach((pc) {
      for (var p in pieces) {
        double a = p.origin[ia];
        double b = p.origin[ib];

        if (almostZero(pieceSize * pc[0] - a) &&
            almostZero(pieceSize * pc[1] - b)) {
          ordered.add(p);
          pieces.remove(p);
          break;
        }
      }
    });

    assert(ordered.length == 8, 'ordered length != 8');

    step = step.abs();
    while (step != 0) {
      step--;
      int c1 = ordered[0].position;
      int c2 = ordered[1].position;
      for (var i = 0; i < 6; i++) {
        ordered[i].position = ordered[i + 2].position;
      }
      ordered[6].position = c1;
      ordered[7].position = c2;
    }
    ordered.forEach((p) {
      positionMap[p.position] = p;
    });
  }

  bool isFinished() {
    for (var p in pieces) {
      if (!p.inRightPositionAndFace()) {
        return false;
      }
    }
    return true;
  }
}

class CubePiece {
  CubePiece(this.cube, this.initPosition)
      : initOrigin = getPieceOrigin(initPosition, cube.pieceSize) {
    origin = initOrigin.clone();
    transform = Matrix4.identity();
    position = this.initPosition;

    Face.values.forEach((f) {
      surfaces.add(PieceSurface(this, f));
    });
  }

  static final originRotation = Matrix3.identity();
  final Cube cube;
  final int initPosition; // 0-26 white front / orange up
  final List<PieceSurface> surfaces = [];
  final Vector3 initOrigin;

  Vector3 origin; // current origin
  Matrix4 transform; // transform between current origin and init origin
  int position;

  Matrix4 get cameraTransform => cube.cameraTransform;

  void reset() {
    origin.setFrom(initOrigin);
    transform.setIdentity();
    position = initPosition;

    surfaces.forEach((s) {
      s.reset();
    });
  }

  bool inRightPosition() {
    return position == initPosition;
  }

  bool inRightPositionAndFace() {
    if (position != initPosition) {
      return false;
    }

    final corners = const [0, 2, 6, 8, 18, 20, 24, 26];
    if (corners.contains(position)) {
      final rotation = transform.getRotation();
      for (var i in const [1, 3, 4, 5, 7]) {
        if (!almostZero(rotation[i] - originRotation[i])) {
          return false;
        }
      }
    }
    return true;
  }

  void rotate(Vector3 axis, double angle) {
    transform.rotate(axis, angle);
    transform.transformed3(initOrigin, origin);
    moved();
  }

  void moved() {
    surfaces.forEach((f) => f.moved());
  }

  @override
  String toString() {
    return 'Piece{IP: $initPosition P: $position}';
  }
}

class PieceSurface {
  PieceSurface(this.piece, this.face)
      : color = getColor(piece.initPosition, face),
        initNormal = getFaceNormal(face),
        initOrigin = getSurfaceOrigin(piece, face),
        initPlaneTL = getSurfaceVertex(piece, face, Corner.TL),
        initPlaneBL = getSurfaceVertex(piece, face, Corner.BL),
        initPlaneBR = getSurfaceVertex(piece, face, Corner.BR),
        initPlaneTR = getSurfaceVertex(piece, face, Corner.TR) {
    reset();

    canvasTransform.translate(initOrigin);

    switch (face) {
      case Face.BACK:
        canvasTransform.rotateY(math.pi);
        break;
      case Face.LEFT:
        canvasTransform.rotateY(math.pi / 2);
        break;
      case Face.RIGHT:
        canvasTransform.rotateY(-math.pi / 2);
        break;
      case Face.TOP:
        canvasTransform.rotateX(math.pi / 2);
        break;
      case Face.DOWN:
        canvasTransform.rotateX(-math.pi / 2);
        break;
      default:
        break;
    }
  }

  final CubePiece piece;
  final Face face;
  final FaceColor color;
  final Vector3 initNormal;
  final Vector3 initOrigin;
  final Vector3 initPlaneTL, initPlaneBL, initPlaneBR, initPlaneTR;

  final Matrix4 canvasTransform = Matrix4.identity();

  final Vector3 origin = Vector3.zero();
  final Vector3 planeTL = Vector3.zero();
  final Vector3 planeBL = Vector3.zero();
  final Vector3 planeBR = Vector3.zero();
  final Vector3 planeTR = Vector3.zero();

  void reset() {
    origin.setFrom(initOrigin);
    planeTL.setFrom(initPlaneTL);
    planeBL.setFrom(initPlaneBL);
    planeBR.setFrom(initPlaneBR);
    planeTR.setFrom(initPlaneTR);
  }

  void moved() {
    reset();
    final transform = piece.cameraTransform.multiplied(piece.transform);

    transform.perspectiveTransform(origin);
    transform.perspectiveTransform(planeTL);
    transform.perspectiveTransform(planeBL);
    transform.perspectiveTransform(planeBR);
    transform.perspectiveTransform(planeTR);
  }

  Vector3 currentNormal() {
    return piece.transform.transformed3(initNormal);
  }

  bool containsPoint(double x, double y) {
    final A = planeBL;
    final B = planeTL;
    final C = planeTR;
    final D = planeBR;
    final a = (B.x - A.x) * (y - A.y) - (B.y - A.y) * (x - A.x);
    final b = (C.x - B.x) * (y - B.y) - (C.y - B.y) * (x - B.x);
    final c = (D.x - C.x) * (y - C.y) - (D.y - C.y) * (x - C.x);
    final d = (A.x - D.x) * (y - D.y) - (A.y - D.y) * (x - D.x);
    if ((a > 0 && b > 0 && c > 0 && d > 0) ||
        (a < 0 && b < 0 && c < 0 && d < 0)) {
      return true;
    }
    return false;
  }
}

Vector3 getFaceNormal(Face face) {
  switch (face) {
    case Face.BACK:
      return Vector3(0, 0, -1);
    case Face.LEFT:
      return Vector3(-1, 0, 0);
    case Face.TOP:
      return Vector3(0, -1, 0);
    case Face.FRONT:
      return Vector3(0, 0, 1);
    case Face.RIGHT:
      return Vector3(1, 0, 0);
    case Face.DOWN:
      return Vector3(0, 1, 0);
    default:
      throw ArgumentError('unsupported face $face');
  }
}

Vector3 getSurfaceOffset(Face face, double pieceSize) {
  switch (face) {
    case Face.BACK:
      return Vector3(0.0, 0.0, -pieceSize / 2);
    case Face.LEFT:
      return Vector3(-pieceSize / 2, 0.0, 0.0);
    case Face.TOP:
      return Vector3(0.0, -pieceSize / 2, 0.0);
    case Face.FRONT:
      return Vector3(0.0, 0.0, pieceSize / 2);
    case Face.RIGHT:
      return Vector3(pieceSize / 2, 0.0, 0.0);
    case Face.DOWN:
      return Vector3(0.0, pieceSize / 2, 0.0);
    default:
      throw ArgumentError('unkown face: $face');
  }
}

Vector2 getVertexOffset(Corner corner, double pieceSize) {
  switch (corner) {
    case Corner.TL:
      return Vector2(-pieceSize / 2, -pieceSize / 2);
    case Corner.BL:
      return Vector2(-pieceSize / 2, pieceSize / 2);
    case Corner.BR:
      return Vector2(pieceSize / 2, pieceSize / 2);
    case Corner.TR:
      return Vector2(pieceSize / 2, -pieceSize / 2);
    default:
      throw ArgumentError('unkown corner: $corner');
  }
}

Vector3 getPieceOrigin(int position, double pieceSize) {
  return Vector3(
    position % 3 - 1.0,
    position % 9 ~/ 3 - 1.0,
    1.0 - position ~/ 9,
  )..scale(pieceSize);
}

Vector3 getSurfaceOrigin(CubePiece piece, Face face) {
  Vector3 pieceOrigin =
      getPieceOrigin(piece.initPosition, piece.cube.pieceSize);
  return pieceOrigin..add(getSurfaceOffset(face, piece.cube.pieceSize));
}

Vector3 getSurfaceVertex(CubePiece piece, Face face, Corner corner) {
  Vector3 faceOrigin = getSurfaceOrigin(piece, face);

  Vector3 v3 = Vector3.zero();
  Vector2 v2 = getVertexOffset(corner, piece.cube.pieceSize);
  switch (face) {
    case Face.BACK:
    case Face.FRONT:
      v3.xy = v2;
      break;
    case Face.LEFT:
    case Face.RIGHT:
      v3.yz = v2;
      break;
    case Face.TOP:
    case Face.DOWN:
      v3.xz = v2;
      break;
  }
  return faceOrigin..add(v3);
}

FaceColor getColor(int position, Face face) {
  if (position > 17 && face == Face.BACK) {
    return FaceColor.ORANGE;
  }
  if (position % 3 == 0 && face == Face.LEFT) {
    return FaceColor.GREEN;
  }
  if (position % 9 < 3 && face == Face.TOP) {
    return FaceColor.WHITE;
  }
  if (position < 9 && face == Face.FRONT) {
    return FaceColor.RED;
  }
  if (position % 3 == 2 && face == Face.RIGHT) {
    return FaceColor.BLUE;
  }
  if (position % 9 > 5 && face == Face.DOWN) {
    return FaceColor.YELLOW;
  }

  return FaceColor.BLACK;
}

int vectorMainIndex(Vector3 axis) {
  for (var i = 0; i < 3; i++) {
    if (axis[i] != 0) {
      return i;
    }
  }
  throw ArgumentError('Invalid axis');
}

bool isAxisUpright(Vector3 axis) {
  for (var i = 0; i < 3; i++) {
    if (axis[i] != 0) {
      return axis[i] > 0;
    }
  }
  throw ArgumentError('Invalid axis');
}

void ensurePureAxis(Vector3 axis) {
  int count = 0;
  for (var i = 0; i < 3; i++) {
    if (axis[i] == 0) {
      count++;
    }
  }
  if (count != 2) {
    throw ArgumentError('Invalid piece rotation axis: $axis');
  }
}

bool almostZero(double value) {
  const EQUAL_MARGIN = 0.001;
  return value.abs() < EQUAL_MARGIN;
}

final axisX = Vector3(1, 0, 0);
final axisY = Vector3(0, 1, 0);
final axisZ = Vector3(0, 0, 1);
