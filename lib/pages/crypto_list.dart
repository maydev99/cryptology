import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout/database/coin_big_data.dart';
import 'package:layout/database/coin_big_data_dao.dart';
import 'package:layout/pages/detail_page.dart';
import 'package:layout/repository/repository.dart';
import 'package:logger/logger.dart';

class CryptoListPage extends StatefulWidget {
  const CryptoListPage({Key? key}) : super(key: key);

  @override
  _CryptoListPageState createState() => _CryptoListPageState();
}

class _CryptoListPageState extends State<CryptoListPage> {
  var log = Logger();
  var repository = MyRepository();

  //final SymbolDao symbolDao = Get.find();
  final CoinBigDataDao coinBigDataDao = Get.find();
  List<CoinBigData> coins = [];

  @override
  void initState() {
    repository.refreshData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cryptology'),
          backgroundColor: Colors.blueGrey,
          actions: [
            IconButton(
                onPressed: () {
                  repository.refreshData();
                },
                icon: const Icon(Icons.refresh)),
          ],
        ),
        body: StreamBuilder<List<CoinBigData>>(
            stream: coinBigDataDao.getAllCoins(),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                coins.clear();
                coins = snapshot.data!;
                return ListView.builder(
                    itemCount: coins.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DetailPage(
                                        symbol: coins[index].symbol,
                                      )));
                        },
                        child: coinCard(index, coins),
                      );
                    });
              }
              return const Center(child: CircularProgressIndicator());
            }));
  }
}

Card coinCard(int index, List<CoinBigData> coins) {
  bool isNegative = false;
  coins[index].D1PriceChangePct.contains('-')
      ? isNegative = true
      : isNegative = false;

  return Card(
    elevation: 10,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: coins[index].logoUrl.contains('svg')
                      ? SvgPicture.network(
                          coins[index].logoUrl,
                          semanticsLabel: coins[index].symbol,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          coins[index].logoUrl,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                        )),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  coins[index].symbol,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coins[index].name,
                style: const TextStyle(fontSize: 30),
                overflow: TextOverflow.fade,
              ),
              Text(
                '\$${coins[index].price}',
                style: const TextStyle(fontSize: 23),
              ),
              Text(
                '${(double.parse(coins[index].D1PriceChangePct) * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                    color: isNegative ? Colors.red : Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )
      ],
    ),
  );
}
