import 'package:provider/provider.dart';

import '../providers/home_provider.dart';
import '../providers/session_provider.dart';

final provider = [
  ChangeNotifierProvider(
    create: (_) => SessionProvider(),
  ),
  ChangeNotifierProvider(
    create: (_) => HomeProvider(),
  ),
];