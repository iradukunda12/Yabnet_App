import 'dart:math' as math;

import 'package:flutter/cupertino.dart' as c;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class NewCustomPage extends Widget {
  @override
  void layout(Context context, BoxConstraints constraints,
      {bool parentUsesSize = false}) {
    box = PdfRect.zero;
  }
}

// @immutable
class _CustomPageWidget {
  const _CustomPageWidget({
    required this.child,
    required this.constraints,
    required this.widgetContext,
  });

  final Widget child;
  final BoxConstraints constraints;
  final WidgetContext? widgetContext;
}

// @immutable
class _CustomPageInstance {
  _CustomPageInstance({
    required this.context,
    required this.constraints,
    required this.fullConstraints,
    required this.offsetStart,
  });

  final Context context;
  final BoxConstraints constraints;
  final BoxConstraints fullConstraints;
  final double? offsetStart;
  final List<_CustomPageWidget> widgets = <_CustomPageWidget>[];
}

class CustomPdfPage extends Page {
  CustomPdfPage({
    PageTheme? pageTheme,
    PdfPageFormat? pageFormat,
    required BuildListCallback build,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.header,
    this.footer,
    this.preFooter,
    ThemeData? theme,
    this.maxPages = 20,
    PageOrientation? orientation,
    EdgeInsets? margin,
    TextDirection? textDirection,
  })  : _buildList = build,
        assert(maxPages > 0),
        super(
          pageTheme: pageTheme,
          pageFormat: pageFormat,
          build: (_) => SizedBox(),
          margin: margin,
          theme: theme,
          orientation: orientation,
          textDirection: textDirection,
        );

  final BuildListCallback _buildList;

  /// How the children should be placed along the cross axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// A builder for the page header.
  final BuildCallback? header;

  /// A builder for the page footer.
  final BuildCallback? footer;

  /// Pre Page Footer
  final BuildCallback? preFooter;

  /// How the children should be placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  final List<_CustomPageInstance> _pages = <_CustomPageInstance>[];

  /// The maximum number of pages allowed before raising an error.
  /// This is not checked with a Release build.
  final int maxPages;

  void _paintChild(
      Context context, Widget child, double x, double y, double pageHeight) {
    if (mustRotate) {
      final newMargin = resolvedMargin!;
      context.canvas
        ..saveContext()
        ..setTransform(c.Matrix4.identity()
          ..rotateZ(-math.pi / 2)
          ..translate(
            x - pageHeight + newMargin.top - newMargin.left,
            y + newMargin.left - newMargin.bottom,
          ));
      child.paint(context);
      context.canvas.restoreContext();
    } else {
      child.box = PdfRect(x, y, child.box!.width, child.box!.height);
      child.paint(context);
    }
  }

  @override
  void generate(Document document, {bool insert = true, int? index}) {
    assert(pageFormat.width > 0 && pageFormat.width < double.infinity);
    assert(pageFormat.height > 0 && pageFormat.height < double.infinity);

    final newMargin = resolvedMargin;
    final canRotate = mustRotate;
    final pageHeight = canRotate ? pageFormat.width : pageFormat.height;
    final pageHeightMargin =
        canRotate ? newMargin!.horizontal : newMargin!.vertical;
    final constraints = BoxConstraints(
        maxWidth: canRotate
            ? (pageFormat.height - newMargin.vertical)
            : (pageFormat.width - newMargin.horizontal));
    final fullConstraints = canRotate
        ? BoxConstraints(
            maxWidth: pageFormat.height - newMargin.vertical,
            maxHeight: pageFormat.width - newMargin.horizontal)
        : BoxConstraints(
            maxWidth: pageFormat.width - newMargin.horizontal,
            maxHeight: pageFormat.height - newMargin.vertical);
    final calculatedTheme = theme ?? document.theme ?? ThemeData.base();
    Context? context;
    late double offsetEnd;
    late double offsetWithPreEnd;
    double difference = 0.0;
    double? offsetStart;
    var index0 = 0;
    var sameCount = 0;
    final baseContext =
        Context(document: document.document).inheritFromAll(<Inherited>[
      calculatedTheme,
      if (pageTheme.textDirection != null)
        InheritedDirectionality(pageTheme.textDirection),
    ]);
    final children = _buildList(baseContext);
    WidgetContext? widgetContext;

    while (index0 < children.length) {
      final child = children[index0];
      assert(() {
        // Detect too big widgets
        if (sameCount++ > maxPages) {
          throw Exception(
              'This widget created more than $maxPages pages. This may be an issue in the widget or the document. See https://pub.dev/documentation/pdf/latest/widgets/MultiPage-class.html');
        }
        return true;
      }());

      // Create a new page if we don't already have one
      if (context == null || child is NewCustomPage) {
        final pdfPage = PdfPage(
          document.document,
          pageFormat: pageFormat,
          index: index == null ? null : (index++),
        );
        final canvas = pdfPage.getGraphics();
        canvas.reset();
        context = baseContext.copyWith(page: pdfPage, canvas: canvas);

        assert(() {
          if (Document.debug) {
            debugPaint(context!);
          }
          return true;
        }());

        offsetStart = pageHeight -
            (canRotate ? pageHeightMargin - newMargin.bottom : newMargin.top);
        offsetEnd =
            canRotate ? pageHeightMargin - newMargin.left : newMargin.bottom;
        offsetWithPreEnd =
            canRotate ? pageHeightMargin - newMargin.left : newMargin.bottom;

        _pages.add(_CustomPageInstance(
          context: context,
          constraints: constraints,
          fullConstraints: fullConstraints,
          offsetStart: offsetStart,
        ));

        if (header != null) {
          final headerWidget = header!(context);

          headerWidget.layout(context, constraints, parentUsesSize: false);
          assert(headerWidget.box != null);
          offsetStart -= headerWidget.box!.height;
        }

        bool isLastPageOnNew = context.pageNumber == context.pagesCount;
        if (footer != null) {
          Widget? fullFooterWidget;
          final footerWidget = footer!(context);

          if (preFooter != null && isLastPageOnNew) {
            fullFooterWidget = Column(
                mainAxisSize: MainAxisSize.min,
                children: [preFooter!(context), footerWidget]);
          } else {
            fullFooterWidget = footerWidget;
          }

          fullFooterWidget.layout(context, constraints, parentUsesSize: false);
          assert(fullFooterWidget.box != null);
          offsetEnd += footerWidget.box!.height;
          offsetWithPreEnd += fullFooterWidget.box!.height;
          difference = offsetWithPreEnd - offsetEnd;
        }
      }

      // If we are processing a multi-page widget, we restore its context
      WidgetContext? savedContext;
      if (child is SpanningWidget && child.canSpan) {
        if (widgetContext != null) {
          child.restoreContext(widgetContext);
          widgetContext = null;
        }
        savedContext = child.cloneContext();
      }

      child.layout(context, constraints, parentUsesSize: false);
      assert(child.box != null);

      final canSpan = child is SpanningWidget && child.canSpan;

      // What to do if the widget is too big for the page?
      if (offsetStart! - child.box!.height < (offsetEnd + difference)) {
        // If it is not a multi-page widget and its height
        // is smaller than a full new page, we schedule a new page creation
        if (child.box!.height <= pageHeight - pageHeightMargin && !canSpan) {
          context = null;
          continue;
        }

        // Else we crash if the widget is too big and cannot be separated
        if (!canSpan) {
          throw Exception(
              'Widget won\'t fit into the page as its height (${child.box!.height}) '
              'exceed a page height (${pageHeight - pageHeightMargin}). '
              'You probably need a SpanningWidget or use a single page layout');
        }

        final span = child;

        if (savedContext != null) {
          // Restore saved context
          span.applyContext(savedContext);
        }

        final localConstraints =
            constraints.copyWith(maxHeight: offsetStart - offsetEnd);
        span.layout(context, localConstraints, parentUsesSize: false);
        assert(span.box != null);
        widgetContext = span.saveContext();
        _pages.last.widgets.add(
          _CustomPageWidget(
            child: span,
            constraints: localConstraints,
            widgetContext: widgetContext.clone(),
          ),
        );

        // Has it finished spanning?
        if (!span.hasMoreWidgets) {
          sameCount = 0;
          index0++;
        }

        // Schedule a new page
        context = null;
        continue;
      }

      _pages.last.widgets.add(
        _CustomPageWidget(
          child: child,
          constraints:
              constraints.copyWith(maxHeight: offsetStart - offsetWithPreEnd),
          widgetContext:
              child is SpanningWidget && canSpan ? child.cloneContext() : null,
        ),
      );

      offsetStart -= child.box!.height;
      sameCount = 0;
      index0++;
    }
  }

  @override
  void postProcess(Document document) {
    final newMargin = resolvedMargin;
    final canRotate = mustRotate;
    final pageHeight = canRotate ? pageFormat.width : pageFormat.height;
    final pageWidth = canRotate ? pageFormat.height : pageFormat.width;
    final pageHeightMargin =
        canRotate ? newMargin!.horizontal : newMargin!.vertical;
    final pageWidthMargin =
        canRotate ? newMargin.vertical : newMargin.horizontal;
    final availableWidth = pageWidth - pageWidthMargin;

    for (final page in _pages) {
      var offsetStart = pageHeight -
          (canRotate ? pageHeightMargin - newMargin.bottom : newMargin.top);
      var offsetEnd =
          canRotate ? pageHeightMargin - newMargin.left : newMargin.bottom;

      if (pageTheme.buildBackground != null) {
        final child = pageTheme.buildBackground!(page.context);

        child.layout(page.context, page.fullConstraints, parentUsesSize: false);
        assert(child.box != null);
        _paintChild(page.context, child, newMargin.left, newMargin.bottom,
            pageFormat.height);
      }

      var totalFlex = 0;
      var allocatedSize = 0.0;
      Widget? lastFlexChild;
      for (final widget in page.widgets) {
        final child = widget.child;
        final flex = child is Flexible ? child.flex : 0;
        if (flex > 0) {
          totalFlex += flex;
          lastFlexChild = child;
        } else {
          if (child is SpanningWidget && child.canSpan) {
            child.applyContext(widget.widgetContext!);
          }

          child.layout(page.context, widget.constraints, parentUsesSize: false);
          assert(child.box != null);
          allocatedSize += child.box!.height;
        }
      }

      if (header != null) {
        final headerWidget = header!(page.context);

        headerWidget.layout(page.context, page.constraints,
            parentUsesSize: false);
        assert(headerWidget.box != null);
        offsetStart -= headerWidget.box!.height;
        _paintChild(page.context, headerWidget, newMargin.left,
            page.offsetStart! - headerWidget.box!.height, pageFormat.height);
      }

      if (footer != null) {
        // final footerWidget = footer!(page.context);

        Widget? fullFooterWidget;
        final footerWidget = footer!(page.context);

        bool isLastPage = page.context.pageNumber == page.context.pagesCount;
        if (preFooter != null && isLastPage) {
          fullFooterWidget = Column(
              mainAxisSize: MainAxisSize.min,
              children: [preFooter!(page.context), footerWidget]);
        } else {
          fullFooterWidget = footerWidget;
        }

        fullFooterWidget.layout(page.context, page.constraints,
            parentUsesSize: false);

        assert(fullFooterWidget.box != null && footerWidget.box != null);

        offsetEnd += fullFooterWidget.box!.height;
        _paintChild(page.context, fullFooterWidget, newMargin.left,
            newMargin.bottom, pageFormat.height);
      }

      final freeSpace = math.max(0.0, offsetStart - offsetEnd - allocatedSize);

      final spacePerFlex = totalFlex > 0 ? (freeSpace / totalFlex) : double.nan;
      var allocatedFlexSpace = 0.0;

      var leadingSpace = 0.0;
      var betweenSpace = 0.0;

      if (totalFlex == 0) {
        final totalChildren = page.widgets.length;

        switch (mainAxisAlignment) {
          case MainAxisAlignment.start:
            leadingSpace = 0.0;
            betweenSpace = 0.0;
            break;
          case MainAxisAlignment.end:
            leadingSpace = freeSpace;
            betweenSpace = 0.0;
            break;
          case MainAxisAlignment.center:
            leadingSpace = freeSpace / 2.0;
            betweenSpace = 0.0;
            break;
          case MainAxisAlignment.spaceBetween:
            leadingSpace = 0.0;
            betweenSpace =
                totalChildren > 1 ? freeSpace / (totalChildren - 1) : 0.0;
            break;
          case MainAxisAlignment.spaceAround:
            betweenSpace = totalChildren > 0 ? freeSpace / totalChildren : 0.0;
            leadingSpace = betweenSpace / 2.0;
            break;
          case MainAxisAlignment.spaceEvenly:
            betweenSpace =
                totalChildren > 0 ? freeSpace / (totalChildren + 1) : 0.0;
            leadingSpace = betweenSpace;
            break;
        }
      }

      for (final widget in page.widgets) {
        final child = widget.child;

        final flex = child is Flexible ? child.flex : 0;
        final fit = child is Flexible ? child.fit : FlexFit.loose;
        if (flex > 0) {
          assert(child is! SpanningWidget || child.canSpan == false,
              'Cannot have a spanning widget flexible');
          final maxChildExtent = child == lastFlexChild
              ? (freeSpace - allocatedFlexSpace)
              : spacePerFlex * flex;
          late double minChildExtent;
          switch (fit) {
            case FlexFit.tight:
              assert(maxChildExtent < double.infinity);
              minChildExtent = maxChildExtent;
              break;
            case FlexFit.loose:
              minChildExtent = 0.0;
              break;
          }

          final innerConstraints = BoxConstraints(
              minWidth: widget.constraints.maxWidth,
              maxWidth: widget.constraints.maxWidth,
              minHeight: minChildExtent,
              maxHeight: maxChildExtent);

          child.layout(page.context, innerConstraints, parentUsesSize: false);
          assert(child.box != null);
          final childSize = child.box!.height;
          assert(childSize <= maxChildExtent);
          allocatedSize += childSize;
          allocatedFlexSpace += maxChildExtent;
        }
      }

      var pos = offsetStart - leadingSpace;
      for (final widget in page.widgets) {
        pos -= widget.child.box!.height;
        late double x;
        switch (crossAxisAlignment) {
          case CrossAxisAlignment.start:
            x = 0;
            break;
          case CrossAxisAlignment.end:
            x = availableWidth - widget.child.box!.width;
            break;
          case CrossAxisAlignment.center:
            x = availableWidth / 2 - widget.child.box!.width / 2;
            break;
          case CrossAxisAlignment.stretch:
            x = 0;
            break;
        }
        final child = widget.child;
        if (child is SpanningWidget && child.canSpan) {
          child.applyContext(widget.widgetContext!);
        }
        _paintChild(page.context, widget.child, newMargin.left + x, pos,
            pageFormat.height);
        pos -= betweenSpace;
      }

      if (pageTheme.buildForeground != null) {
        final child = pageTheme.buildForeground!(page.context);

        child.layout(page.context, page.fullConstraints, parentUsesSize: false);
        assert(child.box != null);
        _paintChild(page.context, child, newMargin.left, newMargin.bottom,
            pageFormat.height);
      }
    }
  }
}
