import 'package:banana_escape/game/components/player_component.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('duplicate inward swipe does not skip the middle lane', () {
    final player = PlayerComponent(skin: BananaSkins.defaultSkin);
    player.configureLanes([100, 200, 300], 600);

    player.moveBy(1);
    for (var i = 0; i < 40; i++) {
      player.update(0.016);
    }
    expect(player.lane, 2);

    player.moveBy(-1);
    player.moveBy(-1);

    expect(player.targetLane, 1);

    for (var i = 0; i < 40; i++) {
      player.update(0.016);
    }

    expect(player.lane, 1);
  });
}
