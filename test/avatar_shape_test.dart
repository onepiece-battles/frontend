import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';

void main() {
  testWidgets('avatars stay square in a fixed-height horizontal list',
      (tester) async {
    // The member row of a group card: 34 px tall, 3 px padding, 24 px avatars.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.all(3),
                child: ImageLazyLoader(
                    uriProvider: () => '',
                    width: 24,
                    borderWidth: 1.5,
                    borderRadios: 40),
              ),
            ],
          ),
        ),
      ),
    ));
    final frame = find.descendant(
        of: find.byType(ImageLazyLoader), matching: find.byType(Container));
    expect(tester.getSize(frame), const Size(24, 24));
  });
}
