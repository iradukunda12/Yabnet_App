import 'package:flutter/material.dart';

class TypeStateProvider<D, T> {
  D? _state;
  final List<VoidCallback> _listeners = [];

  TypeStateProvider({D? initialState}) {
    this._state = initialState;
  }

  D? get currentState => _state;

  void changeState(D state) {
    if (_state != state) {
      _state = state;
      _notifyListeners();
    }
  }

  TypeStateProvider<D, T> cast() {
    return this;
  }

  T? get(Map<D, T> states, {T? defaultValue}) {
    return states[currentState] ?? defaultValue;
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  static TypeStateProvider<D, T> of<D, T>(BuildContext context) {
    final providerWidget = context
        .dependOnInheritedWidgetOfExactType<TypeStateProviderWidget<D, T>>();
    if (providerWidget == null) {
      throw FlutterError(
          'TypeStateProvider.of() called with a context that does not contain a TypeStateProvider.');
    }
    return providerWidget.provider;
  }
}

class TypeStateProviderWidget<D, T> extends InheritedWidget {
  final TypeStateProvider<D, T> provider;

  TypeStateProviderWidget(
      {Key? key, required this.provider, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(TypeStateProviderWidget<D, T> oldWidget) => true;
}

abstract class TypeStateProviderAwareState<T extends StatefulWidget>
    extends State<T> {
  List<TypeStateProvider<dynamic, dynamic>>? providers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    providers ??= [];
    providers!.clear(); // Clear existing providers
    providers!.addAll(retrieveProviders());
    providers!.forEach((provider) => provider.addListener(_onProviderUpdated));
    onProvidersUpdated();
  }

  @override
  void dispose() {
    providers
        ?.forEach((provider) => provider.removeListener(_onProviderUpdated));
    super.dispose();
  }

  void _onProviderUpdated() {
    if (shouldRebuildOnProviderUpdate()) {
      setState(onProvidersUpdated);
    }
  }

  bool shouldRebuildOnProviderUpdate() => true;

  void onProvidersUpdated() {}

  List<TypeStateProvider<dynamic, dynamic>> retrieveProviders();
}

class TestMyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TypeStateProviderWidget<String, Color>(
      provider: TypeStateProvider(),
      child: MaterialApp(
        title: 'Your App',
        home: TestHomePage(),
      ),
    );
  }
}

class TestHomePage extends StatefulWidget {
  @override
  _TestHomePageState createState() => _TestHomePageState();
}

class _TestHomePageState extends TypeStateProviderAwareState<TestHomePage> {
  TypeStateProvider<String, Color> get colorProvider =>
      TypeStateProvider.of(context);

  @override
  List<TypeStateProvider> retrieveProviders() {
    return [
      colorProvider,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.star,
              color: colorProvider
                  .get({"light": Colors.grey, "dark": Colors.white}),
            ),
            Icon(
              Icons.table_chart,
              color: colorProvider
                  .get({"light": Colors.black, "dark": Colors.blue}),
            ),
            Text(
              "My name is John",
              style: TextStyle(
                fontSize: 17,
                color: colorProvider
                    .get({"light": Colors.grey, "dark": Colors.white}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
