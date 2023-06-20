import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final panelData = <Map<String, dynamic>>[];
  late final CartaBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = context.read<CartaBloc>();
    _buildPanelData();
  }

  Future _buildPanelData() async {
    // debugPrint('buildPanelData');
    final cards = await bloc.getSampleBookCards();

    for (final card in cards) {
      // if no genre, assign it to Others
      card.genre ??= 'Others';
      try {
        // panel title matches card genre
        final panel = panelData.where((e) => e['title'] == card.genre).first;
        // add card under the panel
        panel['cards'].add(card);
      } catch (_) {
        // create a new panel
        panelData.add({
          'title': card.genre,
          'isExpanded': false,
          'cards': [card],
        });
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carta Selected'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ExpansionPanelList(
            expansionCallback: (index, isExpanded) {
              setState(() {
                panelData[index]['isExpanded'] = !isExpanded;
              });
            },
            children: panelData.map(
              (e) {
                return ExpansionPanel(
                  // pane header
                  headerBuilder: (context, isExpanded) => ListTile(
                      title: Text(
                    e['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  body: ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: e['cards'].length,
                    itemBuilder: (context, index) {
                      bool added = false;
                      return StatefulBuilder(builder: (context, setState) {
                        return ListTile(
                          // dense: true,
                          onTap: added
                              ? null
                              : () async {
                                  final card = e['cards'][index];
                                  final book =
                                      await bloc.getAudioBookFromCard(card);
                                  if (book != null) {
                                    bloc.addAudioBook(book);
                                    added = true;
                                    setState(() {});
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('book added'),
                                      ));
                                    }
                                  }
                                },
                          title: Text(
                            e['cards'][index].title,
                            style: TextStyle(
                              color: added ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Text(e['cards'][index].authors,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              )),
                        );
                      });
                    },
                  ),
                  isExpanded: e['isExpanded'],
                  canTapOnHeader: true,
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }
}
