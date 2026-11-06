import 'auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Products',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: AuthGate(),
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final CollectionReference<Map<String, dynamic>> _products =
      FirebaseFirestore.instance.collection('campus_products');

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _productStream;

  final _searchController = TextEditingController();
  final _minimumController = TextEditingController();
  final _maximumController = TextEditingController();

  String _search = '';
  String _sort = 'Name A to Z';
  double? _minimum;
  double? _maximum;
  String? _filterError;

  @override
  void initState() {
    super.initState();
    _productStream = _products.snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void _applyRange() {
    final minText = _minimumController.text.trim();
    final maxText = _maximumController.text.trim();

    final min = minText.isEmpty ? null : double.tryParse(minText);
    final max = maxText.isEmpty ? null : double.tryParse(maxText);

    String? error;

    if ((minText.isNotEmpty && min == null) ||
        (maxText.isNotEmpty && max == null)) {
      error = 'Enter valid numbers for the price range.';
    } else if ((min != null && (!min.isFinite || min < 0)) ||
        (max != null && (!max.isFinite || max < 0))) {
      error = 'Prices must be finite numbers of zero or more.';
    } else if (min != null && max != null && min > max) {
      error = 'Minimum price cannot be greater than maximum price.';
    }

    setState(() {
      _filterError = error;

      if (error == null) {
        _minimum = min;
        _maximum = max;
      }
    });
  }

  void _reset() {
    _searchController.clear();
    _minimumController.clear();
    _maximumController.clear();

    setState(() {
      _search = '';
      _minimum = null;
      _maximum = null;
      _filterError = null;
      _sort = 'Name A to Z';
    });
  }

  Future<void> _showProductDialog([
    QueryDocumentSnapshot<Map<String, dynamic>>? document,
  ]) async {
    final data = document?.data();

    final nameController = TextEditingController(
      text: data?['name'] is String ? data!['name'] as String : '',
    );

    final priceController = TextEditingController(
      text: data?['price'] is num ? data!['price'].toString() : '',
    );

    final formKey = GlobalKey<FormState>();
    bool saving = false;
    String? saveError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: !saving,
              child: AlertDialog(
                title: Text(
                  document == null ? 'Add product' : 'Edit product',
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a product name.';
                            }

                            return null;
                          },
                        ),
                        TextFormField(
                          controller: priceController,
                          enabled: !saving,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Price',
                          ),
                          validator: (value) {
                            final price = double.tryParse(
                              value?.trim() ?? '',
                            );

                            if (price == null ||
                                !price.isFinite ||
                                price < 0) {
                              return 'Enter a finite price of zero or more.';
                            }

                            return null;
                          },
                        ),
                        if (saving)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'Waiting for server confirmation. If offline, '
                              'reconnect to finish saving.',
                            ),
                          ),
                        if (saveError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              saveError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setDialogState(() {
                              saving = true;
                              saveError = null;
                            });

                            final product = <String, dynamic>{
                              'name': nameController.text.trim(),
                              'price': double.parse(
                                priceController.text.trim(),
                              ),
                            };

                            try {
                              if (document == null) {
                                await _products.add(product);
                              } else {
                                await _products
                                    .doc(document.id)
                                    .update(product);
                              }

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);
                              _message(
                                'Product save confirmed by server.',
                              );
                            } catch (error) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() {
                                saving = false;
                                saveError = 'Save failed: $error';
                              });
                            }
                          },
                    child: Text(saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Allow the dialog closing animation to finish.
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    nameController.dispose();
    priceController.dispose();
  }

  Future<void> _deleteProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete product'),
          content: Text(
            'Delete ${document.data()['name']}?\n'
            'ID: ${document.id}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    _message('Delete requested. Waiting for server confirmation.');

    try {
      await _products.doc(document.id).delete();
      _message('Product deletion confirmed by server.');
    } catch (error) {
      _message('Delete failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Products'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        tooltip: 'Add product',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search product name',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _search = value.trim().toLowerCase();
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minimumController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Minimum price',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maximumController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Maximum price',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_filterError != null)
                  Text(
                    _filterError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _applyRange,
                      child: const Text('Apply'),
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: _sort,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Name A to Z',
                      child: Text('Name A to Z'),
                    ),
                    DropdownMenuItem(
                      value: 'Name Z to A',
                      child: Text('Name Z to A'),
                    ),
                    DropdownMenuItem(
                      value: 'Price low to high',
                      child: Text('Price low to high'),
                    ),
                    DropdownMenuItem(
                      value: 'Price high to low',
                      child: Text('Price high to low'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sort = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Load failed: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final all = snapshot.data!.docs;

                final valid = all.where((document) {
                  final data = document.data();
                  final price = data['price'];

                  return data['name'] is String &&
                      price is num &&
                      price.isFinite &&
                      price >= 0;
                }).toList();

                final visible = valid.where((document) {
                  final data = document.data();
                  final name = (data['name'] as String).toLowerCase();
                  final price = (data['price'] as num).toDouble();

                  return name.contains(_search) &&
                      (_minimum == null || price >= _minimum!) &&
                      (_maximum == null || price <= _maximum!);
                }).toList();

                visible.sort((a, b) {
                  final first = a.data();
                  final second = b.data();
                  int result;

                  if (_sort.startsWith('Price')) {
                    result = (first['price'] as num).compareTo(
                      second['price'] as num,
                    );

                    if (_sort == 'Price high to low') {
                      result = -result;
                    }
                  } else {
                    result = (first['name'] as String)
                        .toLowerCase()
                        .compareTo(
                          (second['name'] as String).toLowerCase(),
                        );

                    if (_sort == 'Name Z to A') {
                      result = -result;
                    }
                  }

                  return result == 0
                      ? a.id.compareTo(b.id)
                      : result;
                });

                return Column(
                  children: [
                    Text(
                      'Showing ${visible.length} of '
                      '${all.length} products',
                    ),
                    if (all.length != valid.length)
                      Text(
                        '${all.length - valid.length} '
                        'invalid records hidden.',
                      ),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(
                              child: Text(
                                all.isEmpty
                                    ? 'No products yet.'
                                    : 'No products match your filters.',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                bottom: 88,
                              ),
                              itemCount: visible.length,
                              itemBuilder: (context, index) {
                                final document = visible[index];
                                final data = document.data();

                                return ListTile(
                                  title: Text(
                                    data['name'] as String,
                                  ),
                                  subtitle: Text(
                                    '\$${(data['price'] as num).toStringAsFixed(2)}'
                                    '\nID: ${document.id}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit product',
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _showProductDialog(document);
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Delete product',
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _deleteProduct(document);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}