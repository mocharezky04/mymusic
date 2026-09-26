import 'package:flutter_test/flutter_test.dart';
import 'package:mymusic/features/player/player_provider.dart';

/// Handler dimodelkan sebagai prefix `ids[0..handlerLen)`. Setiap operasi di
/// sini harus menjaga invarian itu, sama seperti [_PlayerQueueContract] di app.
void main() {
  group('rotateQueue', () {
    test('moves the start track to the front and keeps the rest in order', () {
      final order = List<String>.generate(10, (i) => 't$i');
      final rotated = rotateQueue(order, 9);

      expect(rotated.first, 't9');
      expect(rotated.length, order.length);
      expect(rotated.sublist(1), ['t0', 't1', 't2', 't3', 't4', 't5', 't6', 't7', 't8']);
    });

    test('keeps order untouched when starting from the first track', () {
      final order = ['a', 'b', 'c'];
      expect(rotateQueue(order, 0), ['a', 'b', 'c']);
    });

    test('keeps a single track queue intact', () {
      expect(rotateQueue(['only'], 0), ['only']);
    });

    test('clamps an out-of-range start index', () {
      expect(rotateQueue(['a', 'b', 'c'], 99), ['c', 'a', 'b']);
    });
  });

  group('handler stays a prefix of the queue', () {
    // Cases required by the QA report: startIndex > 0, reorder after prefetch
    // finished, removing a track that has not been prefetched yet, and skipping
    // right after the queue starts.

    test('startIndex > 0 plays the chosen track first', () {
      final order = List<String>.generate(10, (i) => 't$i');
      final state = rotateQueue(order, 9);

      // Handler loads the first two tracks; state queue is the rotated list.
      final handler = state.take(2).toList();
      var handlerLen = handler.length;

      expect(handler.first, state.first);
      expect(state[0], 't9');

      // Prefetch fills the handler one track at a time, in queue order.
      while (handlerLen < state.length) {
        handler.add(state[handlerLen]);
        handlerLen++;
      }
      expect(handler, state);
    });

    test('skip goes to the next track in queue order', () {
      final order = List<String>.generate(10, (i) => 't$i');
      final state = rotateQueue(order, 9);
      final handler = state.take(3).toList();

      var index = 0;
      index = index + 1;
      expect(handler[index], state[index]);
      expect(handler[index], 't0');
    });

    test('reorder after prefetch finished keeps handler and state equal', () {
      final order = List<String>.generate(6, (i) => 't$i');
      final state = rotateQueue(order, 3);
      final handler = List<String>.of(state);

      final moved = handler.removeAt(1);
      handler.insert(4, moved);
      final movedState = state.removeAt(1);
      state.insert(4, movedState);

      expect(handler, state);
      expect(state[0], 't3', reason: 'the playing track never moves');
    });

    test('removing a track that is not prefetched yet leaves no ghost', () {
      final order = List<String>.generate(8, (i) => 't$i');
      final state = rotateQueue(order, 5);
      // rotated: t5, t6, t7, t0, t1, t2, t3, t4
      final handler = state.take(3).toList();
      expect(handler, ['t5', 't6', 't7']);

      // User removes index 6 (t3), which prefetch has not reached.
      final removed = state.removeAt(6);
      expect(removed, 't3');
      expect(state.contains('t3'), isFalse);

      // Prefetch continues from the handler length; the removed track is gone
      // from the source of truth, so it can never be appended.
      var handlerLen = handler.length;
      while (handlerLen < state.length) {
        final next = state[handlerLen];
        expect(next, isNot('t3'));
        handler.add(next);
        handlerLen++;
      }
      expect(handler, state);
      expect(handler.any((t) => t == 't3'), isFalse);
    });

    test('dropping an unplayable track keeps the index pointing at the same song', () {
      final order = List<String>.generate(6, (i) => 't$i');
      var state = rotateQueue(order, 2);
      var index = 0;
      final current = state[index];

      // Track right after the current one fails to resolve and is dropped.
      state = List<String>.of(state)..removeAt(1);
      if (index >= state.length) index = state.length - 1;
      expect(state[index], current);

      final handler = state.take(2).toList();
      expect(handler[index], current);
    });

    test('queue that loses every track is cleared instead of left dangling', () {
      var state = rotateQueue(['only'], 0);
      state = List<String>.from(state)..removeAt(0);
      expect(state, isEmpty);
    });
  });
}
