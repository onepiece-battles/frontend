import 'package:web/web.dart' as web;

void configureApp() {
  // Inject the CSS style to disable overscroll behavior
  web.document.body?.style.setProperty('overscroll-behavior-x', 'none');

}
