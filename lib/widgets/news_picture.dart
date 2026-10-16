import 'package:flutter/material.dart';

import '../models/news.dart';

class NewsPicture extends StatelessWidget {
  const NewsPicture(this.news, {super.key, this.height = 84});
  final NewsItem news;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: news.isDemo
          ? Semantics(
              label: '例文插画',
              child: CustomPaint(
                painter: _ScenePainter(news.illustration ?? 'sakura'),
              ),
            )
          : news.imageUrl != null
          ? Image.network(
              news.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xffe4e8f2),
                child: Icon(Icons.image_outlined),
              ),
            )
          : const ColoredBox(
              color: Color(0xffe4e8f2),
              child: Icon(Icons.image_outlined),
            ),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.scene);
  final String scene;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xffbddbe7));
    if (scene == 'sakura') {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * .7, size.width, size.height * .3),
        paint..color = const Color(0xffc3d4ba),
      );
      canvas.drawLine(
        Offset(-8, size.height),
        Offset(size.width + 8, 0),
        paint
          ..color = const Color(0xff74616c)
          ..strokeWidth = 5,
      );
      const positions = [
        Offset(.2, .25),
        Offset(.48, .18),
        Offset(.75, .28),
        Offset(.25, .6),
        Offset(.55, .56),
        Offset(.72, .7),
      ];
      for (var i = 0; i < positions.length; i++) {
        final p = positions[i];
        canvas.drawCircle(
          Offset(p.dx * size.width, p.dy * size.height),
          size.shortestSide * .13,
          paint
            ..color = i.isEven
                ? const Color(0xffedafc3)
                : const Color(0xfffbd9e3),
        );
      }
    } else if (scene == 'station') {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * .48, size.width, size.height * .52),
        paint..color = const Color(0xff92a5af),
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * .08,
          size.height * .38,
          size.width * .95,
          size.height * .4,
        ),
        paint..color = const Color(0xffe6ebed),
      );
      for (var i = 0; i < 7; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * (.12 + i * .14),
            size.height * .45,
            size.width * .09,
            size.height * .24,
          ),
          paint..color = const Color(0xff396276),
        );
      }
    } else {
      canvas.drawRect(
        Offset.zero & size,
        paint..color = const Color(0xff95b4c1),
      );
      canvas.drawArc(
        Rect.fromLTWH(
          size.width * .16,
          size.height * .25,
          size.width * .68,
          size.height * .55,
        ),
        3.14159,
        3.14159,
        true,
        paint..color = const Color(0xff617fa5),
      );
      canvas.drawLine(
        Offset(size.width * .5, size.height * .5),
        Offset(size.width * .5, size.height * .88),
        paint
          ..color = const Color(0xff42566e)
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => scene != oldDelegate.scene;
}
