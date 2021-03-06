import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:layout/database/coin_big_data.dart';
import 'package:layout/database/coin_big_data_dao.dart';
import 'package:layout/database/favorites_dao.dart';
import 'package:layout/database/provider.dart';
import 'package:layout/repository/repository.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../utils/util.dart';

class DetailPage extends StatefulWidget {
  final String symbol;

  const DetailPage({Key? key, required this.symbol}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Logger log = Logger();
  var repository = MyRepository();
  final CoinBigDataDao coinBigDataDao = Get.find();
  final FavoritesDao favoritesDao = Get.find();
  CoinBigData? coinBigData;
  List<String> symList = [];
  final box = GetStorage();

  List<String> symbols = [];

  bool favIsSelected = false;
  bool isNegative = false;

  @override
  void initState() {
    super.initState();
  }

  setFavoriteIcon(bool isFavoriteSelected) {
    if (isFavoriteSelected) {
      favIsSelected = true;
    } else {
      favIsSelected = false;
    }
    setState(() {
      favIsSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    var mySymbol = widget.symbol;
    symList = context.watch<ListProvider>().symList;
    symList.contains(mySymbol) ? favIsSelected = true : favIsSelected = false;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Detail'),
          backgroundColor: Colors.blueGrey,
          actions: [
            IconButton(
                onPressed: () async {
                  //log.i(symbols);
                  if (favIsSelected) {
                    context
                        .read<ListProvider>()
                        .deleteFromSymList(symList, mySymbol);
                    setFavoriteIcon(false);
                  } else {
                    context.read<ListProvider>().addToList(mySymbol);
                    setFavoriteIcon(true);
                  }
                },
                icon: favIsSelected
                    ? const Icon(Icons.favorite)
                    : const Icon((Icons.favorite_border)))
          ],
        ),
        body: StreamBuilder<CoinBigData?>(
            stream: coinBigDataDao.getCoinDataBySymbol(mySymbol),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                coinBigData = snapshot.data;
                //calculateSupplyPercentage(coinBigData!);
                coinBigData!.price.contains('-')
                    ? isNegative = true
                    : isNegative = false;

                return Stack(
                  children: [
                    // logoImage(),
                    // glassLayer(),
                    InfoLayer(coinBigData: coinBigData)
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            }));
  }
}

class InfoLayer extends StatelessWidget {
  const InfoLayer({
    Key? key,
    required this.coinBigData,
  }) : super(key: key);

  final CoinBigData? coinBigData;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        var utils = Utils();
        var repository = MyRepository();
        utils.makeASnackBar('Refreshing Data', context);
        return repository.refreshData();
      },
      child: ListView(
        children: [
          TitleCard(coinBigData: coinBigData),
          highSupplyCard(),
          oneDayCard(),
          sevenDayCard(),
          thirtyDayCard(),
          yearCard()
        ],
      ),
    );
  }

  Padding highSupplyCard() {
    var utils = Utils();
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
          elevation: 2,
          color: Colors.blueGrey.withOpacity(0.8),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'High Price:',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        '\$${coinBigData!.high}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        '${utils.convertUTC(coinBigData!.highTimestamp, false)}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${utils.calculatePercentFromHigh(coinBigData!.high, coinBigData!.price)}% from High',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),

                      Text(
                        '${utils.calculateSupplyPercentage(coinBigData!.maxSupply, coinBigData!.circulatingSupply)}% Circulating',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),

                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }

  Padding oneDayCard() {
    bool isRed = false;
    coinBigData!.D1PriceChangePct.contains('-') ? isRed = true : isRed = false;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 2,
        color: isRed
            ? const Color(0xffffabab).withOpacity(0.8)
            : const Color(0xffabffae).withOpacity(0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Day',
                  style: TextStyle(fontSize: 25),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Text(
                'Change: ${(double.parse(coinBigData!.D1PriceChangePct) * 100).toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Text(
                'Change: \$${coinBigData!.D1PriceChange}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Text(
                'Volume: ${coinBigData!.D1Volume}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Text(
                'Vol Change: ${(double.parse(coinBigData!.D1VolChangeOct) * 100).toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding sevenDayCard() {
    bool isRed = false;
    coinBigData!.D7PriceChangePct.contains('-') ? isRed = true : isRed = false;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 2,
        color: isRed
            ? const Color(0xffffabab).withOpacity(0.8)
            : const Color(0xffabffae).withOpacity(0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Week',
                  style: TextStyle(fontSize: 25),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Text(
                'Change: ${(double.parse(coinBigData!.D7PriceChangePct) * 100).toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Text(
                'Change: \$${coinBigData!.D7PriceChange}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Text(
                'Volume: ${coinBigData!.D7Volume}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Text(
                'Vol Change: ${(double.parse(coinBigData!.D7VolChangeOct) * 100).toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding thirtyDayCard() {
    bool isRed = false;
    coinBigData!.D30PriceChangePct.contains('-') ? isRed = true : isRed = false;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 2,
        color: isRed
            ? const Color(0xffffabab).withOpacity(0.8)
            : const Color(0xffabffae).withOpacity(0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Month',
                  style: TextStyle(fontSize: 25),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Text(
                'Change: ${(double.parse(coinBigData!.D30PriceChangePct) * 100).toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Text(
                'Change: \$${coinBigData!.D30PriceChange}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Text(
                'Volume: ${coinBigData!.D30Volume}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Text(
                'Vol Change: ${(double.parse(coinBigData!.D30VolChangePct) * 100).toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding yearCard() {
    bool isRed = false;
    coinBigData!.D365PriceChangePct.contains('-')
        ? isRed = true
        : isRed = false;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 2,
        color: isRed
            ? const Color(0xffffabab).withOpacity(0.8)
            : const Color(0xffabffae).withOpacity(0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Year',
                  style: TextStyle(fontSize: 25),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Text(
                'Change: ${(double.parse(coinBigData!.D365PriceChangePct) * 100).toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Text(
                'Change: \$${coinBigData!.D365PriceChange}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Text(
                'Volume: ${coinBigData!.D365Volume}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Text(
                'Vol Change: ${(double.parse(coinBigData!.D365VolChangePct) * 100).toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleCard extends StatelessWidget {
  const TitleCard({
    Key? key,
    required this.coinBigData,
  }) : super(key: key);

  final CoinBigData? coinBigData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 2,
        color: const Color(0xff3e5666).withOpacity(0.8),
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: coinBigData!.logoUrl.contains('svg')
                    ? SvgPicture.network(
                        coinBigData!.logoUrl,
                        semanticsLabel: coinBigData!.symbol,
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        coinBigData!.logoUrl,
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                      )),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                coinBigData!.name,
                style: const TextStyle(fontSize: 35, color: Colors.white),
              ),
            ),
            Text(
              coinBigData!.symbol,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                '\$${coinBigData!.price}',
                style: const TextStyle(fontSize: 30, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                coinBigData!.timestamp,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
