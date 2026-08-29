import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../providers/home_provider.dart';
import '../providers/session_provider.dart';

List<SingleChildWidget> get provider => [
      ChangeNotifierProvider(
        create: (_) => SessionProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => HomeProvider(),
      ),
    ];