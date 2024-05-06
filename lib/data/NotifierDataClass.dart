class _NotifierData<T, F> {
  final String identity;
  final F forWhich;
  final T data;

  _NotifierData(this.identity, this.forWhich, this.data);
}

class NotifierDataClass<T, F> {
  List<_NotifierData> _data = [];

  void addReplacementData(String identity, F forWhich, T data) {
    if (!containIdentity(identity, forWhich)) {
      _data.add(_NotifierData(identity, forWhich, data));
    }
  }

  T? getData(String identity, {F? forWhich}) {
    return _data
        .where((element) =>
            element.identity == identity && element.forWhich == forWhich)
        .toList()
        .map((e) => e.data)
        .toList()
        .singleOrNull;
  }

  bool containIdentity(String identity, F forWhich) {
    return _data
        .where((element) =>
            element.identity == identity && element.forWhich == forWhich)
        .isNotEmpty;
  }

  void removeWhere(bool Function(String key, F forWhich) param) {
    _data.removeWhere((element) => param(element.identity, element.forWhich));
  }

  List<_NotifierData> getDataList() {
    return _data;
  }
}
