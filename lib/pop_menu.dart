////Author: Phlus.com
///
///
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Examples can assume:
// enum Commands { heroAndScholar, hurricaneCame }
// late bool _heroAndScholar;
// late dynamic _selection;
// late BuildContext context;
// void setState(VoidCallback fn) { }
// enum Menu { itemOne, itemTwo, itemThree, itemFour }

const Duration _kMenuDuration = Duration(milliseconds: 300);
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuDividerHeight = 16.0;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuVerticalPadding = 8.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuScreenPadding = 8.0;

/// Used to configure how the [CustomPopupMenuButton] positions its popup menu.
enum PopupMenuPosition {
  /// Menu is positioned over the anchor.
  over,

  /// Menu is positioned under the anchor.
  under,
}

/// A base class for entries in a Material Design popup menu.
///
/// The popup menu widget uses this interface to interact with the menu items.
/// To show a popup menu, use the [showMenu] function. To create a button that
/// shows a popup menu, consider using [CustomPopupMenuButton].
///
/// The type `T` is the type of the value(s) the entry represents. All the
/// entries in a given menu must represent values with consistent types.

/// See also:
///
///  * [CustomPopupMenuItem], a popup menu entry for a single value.
///  * [PopupMenuDivider], a popup menu entry that is just a horizontal line.
///  * [CheckedCustomPopupMenuItem], a popup menu item with a checkmark.
///  * [showMenu], a method to dynamically show a popup menu at a given location.
///  * [CustomPopupMenuButton], an [IconButton] that automatically shows a menu when
///    it is tapped.
abstract class PopupMenuEntry<T> extends StatefulWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const PopupMenuEntry({super.key});

  /// The amount of vertical space occupied by this entry.
  ///
  /// This value is used at the time the [showMenu] method is called, if the
  /// `initialValue` argument is provided, to determine the position of this
  /// entry when aligning the selected entry over the given `position`. It is
  /// otherwise ignored.
  double get height;

  /// Whether this entry represents a particular value.
  ///
  /// This method is used by [showMenu], when it is called, to align the entry
  /// representing the `initialValue`, if any, to the given `position`, and then
  /// later is called on each entry to determine if it should be highlighted (if
  /// the method returns true, the entry will have its background color set to
  /// the ambient [ThemeData.highlightColor]). If `initialValue` is null, then
  /// this method is not called.
  ///
  /// If the [PopupMenuEntry] represents a single value, this should return true
  /// if the argument matches that value. If it represents multiple values, it
  /// should return true if the argument matches any of them.
  bool represents(T? value);
}

/// A horizontal divider in a Material Design popup menu.
///
/// This widget adapts the [Divider] for use in popup menus.
///
/// See also:
///
///  * [CustomPopupMenuItem], for the kinds of items that this widget divides.
///  * [showMenu], a method to dynamically show a popup menu at a given location.
///  * [CustomPopupMenuButton], an [IconButton] that automatically shows a menu when
///    it is tapped.
class PopupMenuDivider extends PopupMenuEntry<Never> {
  /// Creates a horizontal divider for a popup menu.
  ///
  /// By default, the divider has a height of 16 logical pixels.
  const PopupMenuDivider({super.key, this.height = _kMenuDividerHeight});

  /// The height of the divider entry.
  ///
  /// Defaults to 16 pixels.
  @override
  final double height;

  @override
  bool represents(void value) => false;

  @override
  State<PopupMenuDivider> createState() => _PopupMenuDividerState();
}

class _PopupMenuDividerState extends State<PopupMenuDivider> {
  @override
  Widget build(BuildContext context) => Divider(height: widget.height);
}

// This widget only exists to enable _PopupMenuRoute to save the sizes of
// each menu item. The sizes are used by _PopupMenuRouteLayout to compute the
// y coordinate of the menu's origin so that the center of selected menu
// item lines up with the center of its CustomPopupMenuButton.
class _MenuItem extends SingleChildRenderObjectWidget {
  const _MenuItem({
    required this.onLayout,
    required super.child,
  });

  final ValueChanged<Size> onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMenuItem(onLayout);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMenuItem renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderMenuItem extends RenderShiftedBox {
  _RenderMenuItem(this.onLayout, [RenderBox? child]) : super(child);

  ValueChanged<Size> onLayout;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child == null) {
      return Size.zero;
    }
    return child!.getDryLayout(constraints);
  }

  @override
  void performLayout() {
    if (child == null) {
      size = Size.zero;
    } else {
      child!.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child!.size);
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = Offset.zero;
    }
    onLayout(size);
  }
}

class _PopupMenu<T> extends StatefulWidget {
  const _PopupMenu({
    super.key,
    required this.route,
    required this.semanticLabel,
    required this.onSelected,
    required this.children,
    this.constraints,
  });
  final _PopupMenuRoute<T> route;
  final String? semanticLabel;
  final BoxConstraints? constraints;

  /// Invoked upon user input.
  final ValueChanged<String> onSelected;
  final List<String> children;

  @override
  State<_PopupMenu> createState() => _PopupMenuState();
}

class _PopupMenuState extends State<_PopupMenu> {
  final TextEditingController fieldController = TextEditingController();

  List<String> languages = [];
  List<String> compared = [];

  @override
  void initState() {
    super.initState();
    languages = widget.children;
    compared = widget.children;
  }

  void searchBok(String q) {
    final suggestions = compared.where((language) {
      final bookTitle = language.toLowerCase();
      return bookTitle.contains(q.toLowerCase());
    }).toList();

    setState(() => languages = suggestions);
  }

  @override
  Widget build(BuildContext context) {
    final double unit = 1.0 /
        (languages.length +
            1.5); // 1.0 for the width and 0.5 for the last item's fade.
    final List<Widget> children = <Widget>[];
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    for (int i = 0; i < languages.length; i += 1) {
      final double start = (i + 1) * unit;
      final double end = clampDouble(start + 1.5 * unit, 0.0, 1.0);
      final CurvedAnimation opacity = CurvedAnimation(
        parent: widget.route.animation!,
        curve: Interval(start, end),
      );
      Widget item = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              languages[i],
              style: const TextStyle(overflow: TextOverflow.ellipsis),
            ),
          ),
          Icon(
            Icons.north_east,
            color: Colors.grey.shade500,
          ),
        ],
      );
      children.add(
        SliverToBoxAdapter(
          child: _MenuItem(
            onLayout: (Size size) {
              widget.route.itemSizes[i] = size;
            },
            child: FadeTransition(
              opacity: opacity,
              child: PopupMenuItem(
                onTap: () {
                  widget.onSelected(languages[i]);
                },
                child: item,
              ),
            ),
          ),
        ),
      );
    }

    final CurveTween opacity =
        CurveTween(curve: const Interval(0.0, 1.0 / 3.0));
    final CurveTween width = CurveTween(curve: Interval(0.0, unit));
    final CurveTween height =
        CurveTween(curve: Interval(0.0, unit * languages.length));

    final Widget child = ConstrainedBox(
      constraints: widget.constraints ??
          const BoxConstraints(
            minWidth: _kMenuMinWidth,
            maxWidth: _kMenuMaxWidth,
          ),
      child: IntrinsicWidth(
        stepWidth: _kMenuWidthStep,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: widget.semanticLabel,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                backgroundColor: Theme.of(context).cardColor,
                pinned: true,
                automaticallyImplyLeading: false,
                title: CupertinoSearchTextField(
                  controller: fieldController,
                  autofocus: true,
                  onChanged: searchBok,
                  prefixInsets: const EdgeInsets.only(left: 10),
                ),
              ),
              if (children.isEmpty)
                const SliverToBoxAdapter(
                  child: PopupMenuItem(
                      child: Center(child: Text('No items found'))),
                ),
              ...children
            ],
          ),
        ),
      ),
    );

    return AnimatedBuilder(
        animation: widget.route.animation!,
        builder: (BuildContext context, Widget? child) {
          return FadeTransition(
            opacity: opacity.animate(widget.route.animation!),
            child: Material(
              clipBehavior: Clip.hardEdge,
              shape: widget.route.shape ?? popupMenuTheme.shape,
              color: widget.route.color ?? popupMenuTheme.color,
              type: MaterialType.card,
              elevation:
                  widget.route.elevation ?? popupMenuTheme.elevation ?? 8.0,
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                widthFactor: width.evaluate(widget.route.animation!),
                heightFactor: height.evaluate(widget.route.animation!),
                child: child,
              ),
            ),
          );
        },
        child: child);
  }
}

// Positioning of the menu on the screen.
class _PopupMenuRouteLayout extends SingleChildLayoutDelegate {
  _PopupMenuRouteLayout(
    this.position,
    this.itemSizes,
    this.selectedItemIndex,
    this.textDirection,
    this.padding,
    this.avoidBounds,
  );

  // Rectangle of underlying button, relative to the overlay's dimensions.
  final RelativeRect position;

  // The sizes of each item are computed when the menu is laid out, and before
  // the route is laid out.
  List<Size?> itemSizes;

  // The index of the selected item, or null if CustomPopupMenuButton.initialValue
  // was not specified.
  final int? selectedItemIndex;

  // Whether to prefer going to the left or to the right.
  final TextDirection textDirection;

  // The padding of unsafe area.
  EdgeInsets padding;

  // List of rectangles that we should avoid overlapping. Unusable screen area.
  final Set<Rect> avoidBounds;

  // We put the child wherever position specifies, so long as it will fit within
  // the specified parent size padded (inset) by 8. If necessary, we adjust the
  // child's position so that it fits.

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus 8.0 pixels in each
    // direction.
    return BoxConstraints.loose(constraints.biggest).deflate(
      const EdgeInsets.all(_kMenuScreenPadding) + padding,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // size: The size of the overlay.
    // childSize: The size of the menu, when fully open, as determined by
    // getConstraintsForChild.

    final double buttonHeight = size.height - position.top - position.bottom;
    // Find the ideal vertical position.
    double y = position.top;
    if (selectedItemIndex != null) {
      double selectedItemOffset = _kMenuVerticalPadding;
      for (int index = 0; index < selectedItemIndex!; index += 1) {
        selectedItemOffset += itemSizes[index]!.height;
      }
      selectedItemOffset += itemSizes[selectedItemIndex!]!.height / 2;
      y = y + buttonHeight / 2.0 - selectedItemOffset;
    }

    // Find the ideal horizontal position.
    double x;
    if (position.left > position.right) {
      // Menu button is closer to the right edge, so grow to the left, aligned to the right edge.
      x = size.width - position.right - childSize.width;
    } else if (position.left < position.right) {
      // Menu button is closer to the left edge, so grow to the right, aligned to the left edge.
      x = position.left;
    } else {
      // Menu button is equidistant from both edges, so grow in reading direction.
      switch (textDirection) {
        case TextDirection.rtl:
          x = size.width - position.right - childSize.width;
          break;
        case TextDirection.ltr:
          x = position.left;
          break;
      }
    }
    final Offset wantedPosition = Offset(x, y);
    final Offset originCenter = position.toRect(Offset.zero & size).center;
    final Iterable<Rect> subScreens =
        DisplayFeatureSubScreen.subScreensInBounds(
            Offset.zero & size, avoidBounds);
    final Rect subScreen = _closestScreen(subScreens, originCenter);
    return _fitInsideScreen(subScreen, childSize, wantedPosition);
  }

  Rect _closestScreen(Iterable<Rect> screens, Offset point) {
    Rect closest = screens.first;
    for (final Rect screen in screens) {
      if ((screen.center - point).distance <
          (closest.center - point).distance) {
        closest = screen;
      }
    }
    return closest;
  }

  Offset _fitInsideScreen(Rect screen, Size childSize, Offset wantedPosition) {
    double x = wantedPosition.dx;
    double y = wantedPosition.dy;
    // Avoid going outside an area defined as the rectangle 8.0 pixels from the
    // edge of the screen in every direction.
    if (x < screen.left + _kMenuScreenPadding + padding.left) {
      x = screen.left + _kMenuScreenPadding + padding.left;
    } else if (x + childSize.width >
        screen.right - _kMenuScreenPadding - padding.right) {
      x = screen.right - childSize.width - _kMenuScreenPadding - padding.right;
    }
    if (y < screen.top + _kMenuScreenPadding + padding.top) {
      y = _kMenuScreenPadding + padding.top;
    } else if (y + childSize.height >
        screen.bottom - _kMenuScreenPadding - padding.bottom) {
      y = screen.bottom -
          childSize.height -
          _kMenuScreenPadding -
          padding.bottom;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupMenuRouteLayout oldDelegate) {
    // If called when the old and new itemSizes have been initialized then
    // we expect them to have the same length because there's no practical
    // way to change length of the items list once the menu has been shown.
    assert(itemSizes.length == oldDelegate.itemSizes.length);

    return position != oldDelegate.position ||
        selectedItemIndex != oldDelegate.selectedItemIndex ||
        textDirection != oldDelegate.textDirection ||
        !listEquals(itemSizes, oldDelegate.itemSizes) ||
        padding != oldDelegate.padding ||
        !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }
}

class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    required this.position,
    this.elevation,
    required this.barrierLabel,
    required this.onSelected,
    required this.children,
    this.semanticLabel,
    this.shape,
    this.color,
    required this.capturedThemes,
    this.constraints,
  }) : itemSizes = List<Size?>.filled(children.length, null);

  final RelativeRect position;

  final List<Size?> itemSizes;
  final double? elevation;
  final String? semanticLabel;
  final ShapeBorder? shape;
  final Color? color;
  final CapturedThemes capturedThemes;
  final BoxConstraints? constraints;

  /// Invoked upon user input.
  final ValueChanged<String> onSelected;
  final List<String> children;

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linear,
      reverseCurve: const Interval(0.0, _kMenuCloseIntervalEnd),
    );
  }

  @override
  Duration get transitionDuration => _kMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    int? selectedItemIndex;

    final Widget menu = _PopupMenu<T>(
      route: this,
      semanticLabel: semanticLabel,
      constraints: constraints,
      onSelected: onSelected,
      children: children,
    );
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _PopupMenuRouteLayout(
              position,
              itemSizes,
              selectedItemIndex,
              Directionality.of(context),
              mediaQuery.padding,
              _avoidBounds(mediaQuery),
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }

  Set<Rect> _avoidBounds(MediaQueryData mediaQuery) {
    return DisplayFeatureSubScreen.avoidBounds(mediaQuery).toSet();
  }
}

/// Show a popup menu that contains the `items` at `position`.
///
/// `items` should be non-null and not empty.
///
/// If `initialValue` is specified then the first item with a matching value
/// will be highlighted and the value of `position` gives the rectangle whose
/// vertical center will be aligned with the vertical center of the highlighted
/// item (when possible).
///
/// If `initialValue` is not specified then the top of the menu will be aligned
/// with the top of the `position` rectangle.
///
/// In both cases, the menu position will be adjusted if necessary to fit on the
/// screen.
///
/// Horizontally, the menu is positioned so that it grows in the direction that
/// has the most room. For example, if the `position` describes a rectangle on
/// the left edge of the screen, then the left edge of the menu is aligned with
/// the left edge of the `position`, and the menu grows to the right. If both
/// edges of the `position` are equidistant from the opposite edge of the
/// screen, then the ambient [Directionality] is used as a tie-breaker,
/// preferring to grow in the reading direction.
///
/// The positioning of the `initialValue` at the `position` is implemented by
/// iterating over the `items` to find the first whose
/// [PopupMenuEntry.represents] method returns true for `initialValue`, and then
/// summing the values of [PopupMenuEntry.height] for all the preceding widgets
/// in the list.
///
/// The `elevation` argument specifies the z-coordinate at which to place the
/// menu. The elevation defaults to 8, the appropriate elevation for popup
/// menus.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the menu. It is only used when the method is called. Its corresponding
/// widget can be safely removed from the tree before the popup menu is closed.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// menu to the [Navigator] furthest from or nearest to the given `context`. It
/// is `false` by default.
///
/// The `semanticLabel` argument is used by accessibility frameworks to
/// announce screen transitions when the menu is opened and closed. If this
/// label is not provided, it will default to
/// [MaterialLocalizations.popupMenuLabel].
///
/// See also:
///
///  * [CustomPopupMenuItem], a popup menu entry for a single value.
///  * [PopupMenuDivider], a popup menu entry that is just a horizontal line.
///  * [CheckedCustomPopupMenuItem], a popup menu item with a checkmark.
///  * [CustomPopupMenuButton], which provides an [IconButton] that shows a menu by
///    calling this method automatically.
///  * [SemanticsConfiguration.namesRoute], for a description of edge triggered
///    semantics.
Future<T?> showMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
  double? elevation,
  String? semanticLabel,
  ShapeBorder? shape,
  Color? color,
  bool useRootNavigator = false,
  BoxConstraints? constraints,

  /// Invoked upon user input.
  required ValueChanged<String> onSelected,
  required List<String> children,
}) {
  assert(children.isNotEmpty);
  assert(debugCheckHasMaterialLocalizations(context));

  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      break;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      semanticLabel ??= MaterialLocalizations.of(context).popupMenuLabel;
  }

  final NavigatorState navigator =
      Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(_PopupMenuRoute<T>(
    position: position,
    elevation: elevation,
    semanticLabel: semanticLabel,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    shape: shape,
    color: color,
    onSelected: onSelected,
    children: children,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    constraints: constraints,
  ));
}

typedef CustomPopupMenuItemSelected<T> = void Function(T value);

/// Signature for the callback invoked when a [CustomPopupMenuButton] is dismissed
/// without selecting an item.
///
/// Used by [CustomPopupMenuButton.onCanceled].
typedef PopupMenuCanceled = void Function();

/// One of [child] or [icon] may be provided, but not both. If [icon] is provided,
/// then [CustomPopupMenuButton] behaves like an [IconButton].
///
/// If both are null, then a standard overflow icon is created (depending on the
/// platform).
///
/// {@tool dartpad}
/// This example shows a menu with four items, selecting between an enum's
/// values and setting a `_selectedMenu` field based on the selection
///
/// ** See code in examples/api/lib/material/popupmenu/popupmenu.0.dart **
/// {@end-tool}
///
/// See also:

class CustomPopupMenuButton<T> extends StatefulWidget {
  /// Creates a button that shows a popup menu.
  ///
  /// The [itemBuilder] argument must not be null.
  const CustomPopupMenuButton({
    super.key,
    this.tooltip,
    this.elevation,
    this.padding = const EdgeInsets.all(8.0),
    this.child,
    this.splashRadius,
    this.icon,
    this.iconSize,
    this.offset = Offset.zero,
    this.enabled = true,
    this.shape,
    this.color,
    required this.onSelected,
    required this.children,
    this.enableFeedback,
    this.constraints,
    this.position = PopupMenuPosition.over,
  }) : assert(
          !(child != null && icon != null),
          'You can only pass [child] or [icon], not both.',
        );

  /// Invoked upon user input.
  final ValueChanged<String> onSelected;
  final List<String> children;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String? tooltip;

  /// The z-coordinate at which to place the menu when open. This controls the
  /// size of the shadow below the menu.
  ///
  /// Defaults to 8, the appropriate elevation for popup menus.
  final double? elevation;

  /// Matches IconButton's 8 dps padding by default. In some cases, notably where
  /// this button appears as the trailing element of a list item, it's useful to be able
  /// to set the padding to zero.
  final EdgeInsetsGeometry padding;

  /// The splash radius.
  ///
  /// If null, default splash radius of [InkWell] or [IconButton] is used.
  final double? splashRadius;

  /// If provided, [child] is the widget used for this button
  /// and the button will utilize an [InkWell] for taps.
  final Widget? child;

  /// If provided, the [icon] is used for this button
  /// and the button will behave like an [IconButton].
  final Widget? icon;

  /// The offset is applied relative to the initial position
  /// set by the [position].
  ///
  /// When not set, the offset defaults to [Offset.zero].
  final Offset offset;

  /// This can be useful in situations where the app needs to show the button,
  /// but doesn't currently have anything to show in the menu.
  final bool enabled;

  /// If provided, the shape used for the menu.
  ///
  /// If this property is null, then [PopupMenuThemeData.shape] is used.
  /// If [PopupMenuThemeData.shape] is also null, then the default shape for
  /// [MaterialType.card] is used. This default shape is a rectangle with
  /// rounded edges of BorderRadius.circular(2.0).
  final ShapeBorder? shape;

  /// If provided, the background color used for the menu.
  ///
  /// If this property is null, then [PopupMenuThemeData.color] is used.
  /// If [PopupMenuThemeData.color] is also null, then
  /// Theme.of(context).cardColor is used.
  final Color? color;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// If provided, the size of the [Icon].
  ///
  /// If this property is null, then [IconThemeData.size] is used.
  /// If [IconThemeData.size] is also null, then
  /// default size is 24.0 pixels.
  final double? iconSize;

  /// Optional size constraints for the menu.
  ///
  /// When unspecified, defaults to:
  /// ```dart
  /// const BoxConstraints(
  ///   minWidth: 2.0 * 56.0,
  ///   maxWidth: 5.0 * 56.0,
  /// )
  /// ```
  ///
  /// The default constraints ensure that the menu width matches maximum width
  /// recommended by the Material Design guidelines.
  /// Specifying this parameter enables creation of menu wider than
  /// the default maximum width.
  final BoxConstraints? constraints;

  /// Whether the popup menu is positioned over or under the popup menu button.
  ///
  /// [offset] is used to change the position of the popup menu relative to the
  /// position set by this parameter.
  ///
  /// When not set, the position defaults to [PopupMenuPosition.over] which makes the
  /// popup menu appear directly over the button that was used to create it.
  final PopupMenuPosition position;

  @override
  CustomPopupMenuButtonState<T> createState() =>
      CustomPopupMenuButtonState<T>();
}

/// The [State] for a [CustomPopupMenuButton].
///
/// See [showButtonMenu] for a way to programmatically open the popup menu
/// of your button state.
class CustomPopupMenuButtonState<T> extends State<CustomPopupMenuButton<T>> {
  /// By default, it is called when the user taps the button and [CustomPopupMenuButton.enabled]
  /// is set to `true`. Moreover, you can open the button by calling the method manually.
  ///
  /// You would access your [CustomPopupMenuButtonState] using a [GlobalKey] and
  /// show the menu of the button with `globalKey.currentState.showButtonMenu`.
  void showButtonMenu() {
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final Offset offset;
    switch (widget.position) {
      case PopupMenuPosition.over:
        offset = widget.offset;
        break;
      case PopupMenuPosition.under:
        offset =
            Offset(0.0, button.size.height - (widget.padding.vertical / 2)) +
                widget.offset;
        break;
    }
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset,
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    // Only show the menu if there is something to show

    showMenu<T?>(
      context: context,
      elevation: widget.elevation ?? popupMenuTheme.elevation,
      items: [],
      position: position,
      shape: widget.shape ?? popupMenuTheme.shape,
      color: widget.color ?? popupMenuTheme.color,
      constraints: widget.constraints,
      onSelected: widget.onSelected,
      children: widget.children,
    );
  }

  bool get _canRequestFocus {
    final NavigationMode mode = MediaQuery.maybeOf(context)?.navigationMode ??
        NavigationMode.traditional;
    switch (mode) {
      case NavigationMode.traditional:
        return widget.enabled;
      case NavigationMode.directional:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enableFeedback = widget.enableFeedback ??
        PopupMenuTheme.of(context).enableFeedback ??
        true;

    assert(debugCheckHasMaterialLocalizations(context));
    return InkWell(
      onTap: widget.enabled ? showButtonMenu : null,
      canRequestFocus: _canRequestFocus,
      radius: widget.splashRadius,
      enableFeedback: enableFeedback,
      child: widget.child,
    );
  }
}
