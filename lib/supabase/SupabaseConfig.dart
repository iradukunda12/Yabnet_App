import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yabnet/components/CustomProject.dart';

class SupabaseConfig {
  static final SupabaseConfig instance = SupabaseConfig.internal();

  factory SupabaseConfig() => instance;

  SupabaseConfig.internal();

  List<dynamic> listOfEnsureDistinct = [];

  static const url = "https://wyathlairkdyweovncoq.supabase.co";
  static const apiKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5YXRobGFpcmtkeXdlb3ZuY29xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDYwMzYzODIsImV4cCI6MjAyMTYxMjM4Mn0.CWrY9FX9aaWmrTkwwr7HwXja-d-TpNEqP-vL93Ac5B0";
  static final initialize = Supabase.initialize(url: url, anonKey: apiKey);
  static final client = Supabase.instance.client;

  List<Map<String, dynamic>>? distinctByColumn<T>(
      List<Map<String, dynamic>>? data, String column) {
    List<Map<String, dynamic>> distinctList = [];

    List<dynamic>? mappedList = [];

    if (data == null) {
      return null;
    }

    for (var element in data) {
      dynamic mappedColumn = element[column];
      if (mappedList.contains(mappedColumn) == false) {
        mappedList.add(mappedColumn);
        distinctList.add(element);
      }
    }

    return distinctList;
  }

  String cleanFilterArray(List<dynamic> filter) {
    if (filter.every((element) => element is num)) {
      return filter.map((s) => '$s').join(',');
    } else {
      return filter.map((s) => '"$s"').join(',');
    }
  }

  String filtersIn(String column, List<dynamic> values) {
    return "${column}.in.(${cleanFilterArray(values)})";
  }

  String filtersNotIn(String column, List<dynamic> values) {
    return "${column}.not.in.(${cleanFilterArray(values)})";
  }

  Future<DateTime?> getDatabaseTime() {
    return client.rpc("get_database_time").then((value) {
      return DateTime.tryParse(value.toString());
    }).onError((error, stackTrace) {
      showDebug(msg: "$error $stackTrace");
      return null;
    });
  }
}

class SupabaseStreamPaginationOption {
  final int fetchCount;
  final double offsetFetch;
  final SupabaseStreamPaginationController supabaseStreamPaginationController;

  SupabaseStreamPaginationOption(
      this.fetchCount, this.supabaseStreamPaginationController,
      {this.offsetFetch = 0.5}) {
    supabaseStreamPaginationController.setFetchOption(this);
  }
}

class SupabaseStreamPaginationController<T> extends ChangeNotifier {
  int fetchBy = 0;
  List<T?> getKeys = [];
  SupabaseStreamPaginationOption? getSupabaseStreamPaginationOption;

  bool get hasFetchOption => getSupabaseStreamPaginationOption != null;

  void setFetchOption(
      SupabaseStreamPaginationOption supabaseStreamPaginationOption) {
    if (fetchBy == 0 && getSupabaseStreamPaginationOption == null) {
      getSupabaseStreamPaginationOption = supabaseStreamPaginationOption;
      fetchBy += getSupabaseStreamPaginationOption?.fetchCount ?? 0;
      notifyListeners();
    }
  }

  void updateKeys(List<T?> keys) {
    if (!hasFetchOption) {
      return;
    }
    getKeys = keys;
    notifyListeners();
  }

  void resetFetchBy() {
    if (!hasFetchOption) {
      return;
    }
    fetchBy = getSupabaseStreamPaginationOption?.fetchCount ?? 0;
    getKeys.clear();
    notifyListeners();
  }

  bool? increaseFetchBy(List<T?> keys, {double? thisOffset}) {
    if (!hasFetchOption) {
      return null;
    }
    int change = 0;

    change = getKeys.fold(0, (previousValue, element) {
      return keys.contains(element) ? previousValue + 0 : previousValue + 1;
    });

    if (keys.every((element) => getKeys.contains(element)) &&
        getKeys.isNotEmpty &&
        change == 0) {
      if (fetchBy <
          getKeys.length +
              (getSupabaseStreamPaginationOption?.fetchCount ?? 0)) {
        fetchBy = getKeys.length +
            (getSupabaseStreamPaginationOption?.fetchCount ?? 0) +
            (fetchBy - getKeys.length);
      }
      return !(fetchBy <
          getKeys.length +
              (getSupabaseStreamPaginationOption?.fetchCount ?? 0));
    }

    getKeys = keys;
    int keyLength = getKeys.length;

    if (keyLength == fetchBy) {
      fetchBy += getSupabaseStreamPaginationOption?.fetchCount ?? 0;
    } else {
      if (keys.isEmpty) {
        return null;
      }

      if (keyLength > fetchBy) {
        fetchBy += getSupabaseStreamPaginationOption?.fetchCount ??
            0 +
                ((fetchBy +
                        (getSupabaseStreamPaginationOption?.fetchCount ?? 0)) -
                    keyLength);
      } else {
        double offset = (fetchBy - keyLength) /
            (getSupabaseStreamPaginationOption?.fetchCount ?? 1);

        if (offset >
            (thisOffset ??
                (getSupabaseStreamPaginationOption?.offsetFetch ?? 0.5))) {
          fetchBy += getSupabaseStreamPaginationOption?.fetchCount ?? 0;
        }
      }
    }
    notifyListeners();
    return true;
  }
}
