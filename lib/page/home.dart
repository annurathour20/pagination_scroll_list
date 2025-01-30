import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List userData = [];
  int page = 1;
  int pageLimit = 5;
  bool isLoadingMore = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer ?_debounce;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoadingMore) {
        fetchUserData();
      }
    });
  }
  void callSearchData(String query){
   if( _debounce?.isActive??false) {
     _debounce?.cancel();
   }
   _debounce= Timer( const Duration(microseconds: 500),(){
     if (query.isEmpty) {
       setState(() {
         fetchUserData();
       });
     }
    else if(query.length>=3) {
       setState(() {
         filterUserListData(query);
       });

     }
   });
  }

  void filterUserListData(String query) {

    setState(() {
      userData = userData
          .where((user) =>
              user['name'].toLowerCase().contains(query.toLowerCase())||user['gender'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> fetchUserData() async {
    setState(() => isLoadingMore = true);
    final url = 'https://rickandmortyapi.com/api/character/?page=$page';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userData += data['results'];
          page++;
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Pagination')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  callSearchData(value);
                });
              },
              decoration: InputDecoration(
                  hintText: 'Saerch user data',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0))),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                controller: _scrollController,
                itemCount:
                    isLoadingMore ? userData.length + 1 : userData.length,
                itemBuilder: (context, index) {
                  final user = userData[index];
                  if (index == userData.length) {
                    return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()));
                  }

                  return ListTile(
                    leading: CircleAvatar(
                        backgroundImage: NetworkImage(user['image'])),
                    title: Text(user['name']),
                    subtitle: Text(user['gender']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
