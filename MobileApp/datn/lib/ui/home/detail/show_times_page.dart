import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_loader/stream_loader.dart';
import 'package:tuple/tuple.dart';

import '../../../domain/model/city.dart';
import '../../../domain/model/theatre_and_show_times.dart';
import '../../../domain/repository/city_repository.dart';
import '../../../domain/repository/movie_repository.dart';
import '../../../utils/date_time.dart';
import '../../../utils/error.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';

class ShowTimesPage extends StatefulWidget {
  final String movieId;

  const ShowTimesPage({Key key, @required this.movieId}) : super(key: key);

  @override
  _ShowTimesPageState createState() => _ShowTimesPageState();
}

class _ShowTimesPageState extends State<ShowTimesPage>
    with AutomaticKeepAliveClientMixin<ShowTimesPage> {
  final dateFormat = DateFormat('dd/MM');
  final fullDateFormat = DateFormat.yMMMd();
  final showTimeDateFormat = DateFormat('hh:mm a');

  final startDay = startOfDay(DateTime.now());
  List<DateTime> days;
  BehaviorSubject<DateTime> selectedDayS;
  LoaderBloc<BuiltList<TheatreAndShowTimes>> bloc;

  @override
  void initState() {
    super.initState();

    selectedDayS = BehaviorSubject.seeded(startDay);
    days = [for (var i = 0; i <= 4; i++) startDay.add(Duration(days: i))];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bloc ??= () {
      final cityRepo = Provider.of<CityRepository>(context);
      final movieRepo = Provider.of<MovieRepository>(context);

      final emptyList = <TheatreAndShowTimes>[].build();
      final emptyMap = <DateTime, BuiltList<TheatreAndShowTimes>>{}.build();

      return LoaderBloc<BuiltList<TheatreAndShowTimes>>(
        loaderFunction: () {
          final showTimesByDay$ = cityRepo.selectedCity$
              .map((city) => city.location)
              .distinct()
              .scan(
                (_, value, index) => Tuple2(value, index),
                Tuple2(null, -1),
              )
              .switchMap(
            (tuple) {
              final s$ = movieRepo.getShowTimes(
                movieId: widget.movieId,
                location: tuple.item1,
              );
              return tuple.item2 == 0 ? s$ : s$.startWith(emptyMap);
            },
          );

          return Rx.combineLatest2(
              showTimesByDay$,
              selectedDayS,
              (
                BuiltMap<DateTime, BuiltList<TheatreAndShowTimes>>
                    showTimesByDay,
                DateTime day,
              ) =>
                  showTimesByDay[day] ?? emptyList);
        },
        enableLogger: true,
        initialContent: emptyList,
      )..fetch();
    }();
  }

  @override
  void dispose() {
    print('$this::dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final textTheme = Theme.of(context).textTheme;
    final weekDayStyle = textTheme.button;
    final ddMMStyle = textTheme.subtitle1.copyWith(fontSize: 15);
    final weekDaySelectedStyle = weekDayStyle.copyWith(color: Colors.white);
    final ddMMSelectedStyle = ddMMStyle.copyWith(color: Colors.white);
    final accentColor = Theme.of(context).accentColor;

    return SafeArea(
      child: Column(
        children: [
          Card(
            elevation: 5,
            child: Column(
              children: [
                const SelectCityWidget(),
                const SizedBox(height: 8),
                RxStreamBuilder<DateTime>(
                  stream: selectedDayS,
                  builder: (context, snapshot) {
                    final selectedDay = snapshot.data;

                    return Row(
                      children: [
                        const SizedBox(width: 4),
                        for (final day in days)
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () => selectedDayS.add(day),
                              child: AnimatedContainer(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: day == selectedDay
                                      ? accentColor
                                      : Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      day == startDay
                                          ? 'Today'
                                          : weekdayOf(day),
                                      style: day == selectedDay
                                          ? weekDaySelectedStyle
                                          : weekDayStyle,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dateFormat.format(day),
                                      style: day == selectedDay
                                          ? ddMMSelectedStyle
                                          : ddMMStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                      ],
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Today, ${fullDateFormat.format(startDay)}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              child:
                  RxStreamBuilder<LoaderState<BuiltList<TheatreAndShowTimes>>>(
                stream: bloc.state$,
                builder: (context, snapshot) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildBottom(snapshot.data),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(LoaderState<BuiltList<TheatreAndShowTimes>> state) {
    if (state.error != null) {
      return MyErrorWidget(
        errorText: 'Error: ${getErrorMessage(state.error)}',
        onPressed: bloc.fetch,
      );
    }

    if (state.isLoading) {
      return Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: LoadingIndicator(
            indicatorType: Indicator.ballClipRotatePulse,
          ),
        ),
      );
    }

    final list = state.content;

    if (list.isEmpty) {
      return Center(
        child: EmptyWidget(
          message: 'Empty show times',
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) => ShowTimeItem(
        key: ValueKey(list[index].theatre.id),
        theatreAndShowTimes: list[index],
        showTimeDateFormat: showTimeDateFormat,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class SelectCityWidget extends StatelessWidget {
  const SelectCityWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cityRepo = Provider.of<CityRepository>(context);

    return Row(
      children: [
        const SizedBox(width: 16),
        Text(
          'Chọn khu vực: ',
          style: textTheme.headline6.copyWith(fontSize: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: RxStreamBuilder<City>(
            stream: cityRepo.selectedCity$,
            builder: (context, snapshot) {
              final selected = snapshot.data;

              return PopupMenuButton<City>(
                initialValue: selected,
                onSelected: cityRepo.change,
                offset: Offset(0, 200),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        selected.name,
                        style: textTheme.subtitle1,
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) {
                  return [
                    for (final city in cityRepo.allCities)
                      PopupMenuItem<City>(
                        child: Text(city.name),
                        value: city,
                      )
                  ];
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ShowTimeItem extends StatelessWidget {
  final DateFormat showTimeDateFormat;
  final TheatreAndShowTimes theatreAndShowTimes;

  ShowTimeItem(
      {Key key,
      @required this.theatreAndShowTimes,
      @required this.showTimeDateFormat})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theatre = theatreAndShowTimes.theatre;
    final showTimes = theatreAndShowTimes.showTimes;
    final textTheme = Theme.of(context).textTheme;

    return ExpansionTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(theatre.name),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.map_rounded,
                color: Colors.grey.shade500,
                size: 20,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  theatre.address,
                  style: textTheme.caption.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: [
            for (final show in showTimes)
              InkWell(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xffD1DBE2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      showTimeDateFormat.format(show.start_time),
                      textAlign: TextAlign.center,
                      style: textTheme.subtitle1.copyWith(
                        fontSize: 18,
                        color: const Color(0xff687189),
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ],
    );
  }
}