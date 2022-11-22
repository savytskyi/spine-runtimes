import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:esotericsoftware_spine_flutter/spine_flutter.dart';

class SpineComponent extends PositionComponent {
  final BoundsProvider _boundsProvider;
  final SkeletonDrawable _drawable;
  late final Bounds _bounds;
  final bool _ownsDrawable;

  SpineComponent(this._drawable, {
        bool ownsDrawable = false,
        BoundsProvider boundsProvider = const SetupPoseBounds(),
        super.position,
        super.scale,
        double super.angle = 0.0,
        Anchor super.anchor = Anchor.topLeft,
        super.children,
        super.priority,
      }) :
        _ownsDrawable = ownsDrawable,
        _boundsProvider = boundsProvider {
    _drawable.update(0);
    _bounds = _boundsProvider.computeBounds(_drawable);
    size = Vector2(_bounds.width, _bounds.height);
  }

  static Future<SpineComponent> fromAssets(String atlasFile, String skeletonFile, {
        AssetBundle? bundle, BoundsProvider boundsProvider = const SetupPoseBounds(),
        Vector2? position,
        Vector2? scale,
        double angle = 0.0,
        Anchor anchor = Anchor.topLeft,
        Iterable<Component>? children,
        int? priority,
      }) async {
    final drawable = await SkeletonDrawable.fromAsset(atlasFile, skeletonFile, bundle: bundle);
    return SpineComponent(
        drawable,
        ownsDrawable: true,
        boundsProvider: boundsProvider,
        position: position,
        scale: scale,
        angle: angle,
        anchor: anchor,
        children: children,
        priority: priority);
  }

  @override
  void onRemove() {
    if (_ownsDrawable) _drawable.dispose();
  }
  
  @override
  void update(double dt) {
    _drawable.update(dt);
  }
  
  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(-_bounds.x, -_bounds.y);
    _drawable.renderToCanvas(canvas);
    canvas.restore();
  }

  get animationState => _drawable.animationState;
  get animationStateData => _drawable.animationStateData;
  get skeleton => _drawable.skeleton;
}

class SimpleFlameExample extends FlameGame {
  late final SpineComponent spineboy;

  @override
  Future<void> onLoad() async {
    // Load the Spineboy atlas and skeleton data from asset files
    // and create a SpineComponent from them, scaled down and
    // centered on the screen
    spineboy = await SpineComponent.fromAssets(
        "assets/spineboy.atlas", "assets/spineboy-pro.skel",
        scale: Vector2(0.4, 0.4),
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y / 2)
    );

    // Set the "walk" animation on track 0 in looping mode
    spineboy.animationState.setAnimationByName(0, "walk", true);
    await add(spineboy);
  }
}

class PreloadAndShareSpineDataExample extends FlameGame {
  late final SkeletonData cachedSkeletonData;
  late final Atlas cachedAtlas;
  late final List<SpineComponent> spineboys;

  @override
  Future<void> onLoad() async {
    // Pre-load the atlas and skeleton data once.
    cachedAtlas = await Atlas.fromAsset("assets/spineboy.atlas");
    cachedSkeletonData = await SkeletonData.fromAsset(cachedAtlas, "assets/spineboy-pro.skel");

    // Instantiate many spineboys from the pre-loaded data. Each SpineComponent
    // gets their own SkeletonDrawable copy derived from the cached data. The
    // SkeletonDrawable copies do not own the underlying skeleton data and atlas.
    final rng = Random();
    for (int i = 0; i < 100; i++) {
      final drawable = SkeletonDrawable(cachedAtlas, cachedSkeletonData, false);
      final scale = 0.1 + rng.nextDouble() * 0.2;
      final position = Vector2(rng.nextDouble() * size.x, rng.nextDouble() * size.y);
      final spineboy = SpineComponent(
          drawable,
          scale: Vector2(scale, scale),
          position: position
      );
      spineboy.animationState.setAnimationByName(0, "walk", true);
      await add(spineboy);
    }
  }

  @override
  void onRemove() {
    // Dispose the pre-loaded atlas and skeleton data when the game/scene is removed
    cachedAtlas.dispose();
    cachedSkeletonData.dispose();
  }
}

class SpineFlameGameWidget extends StatelessWidget {
  final FlameGame game;
  const SpineFlameGameWidget(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flame Integration')),
      body: GameWidget(game: game)
    );
  }
}