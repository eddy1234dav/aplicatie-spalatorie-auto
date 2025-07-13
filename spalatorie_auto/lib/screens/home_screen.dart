import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spalatorie_auto/services/auth_service.dart';
import 'package:spalatorie_auto/screens/store_screen.dart';
import 'package:spalatorie_auto/screens/bluetooth_screen.dart';
import 'package:spalatorie_auto/screens/wash_options_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const WashTab(),
    const BluetoothTab(),
    const StoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_car_wash), label: 'Wash'),
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'Bluetooth'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('utilizatori').doc(uid).get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FD),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('JetWash - Panou Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Delogare',
            onPressed: () async {
              await AuthService.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: user != null
          ? FutureBuilder<Map<String, dynamic>>(
        future: getUserData(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? {};
          final name = user.displayName ?? data['nume'] ?? 'Utilizator';
          final tokens = data['jetoane'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.indigo, Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.account_circle, size: 30, color: Colors.indigo),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.token, color: Colors.amber, size: 20),
                                const SizedBox(width: 6),
                                Text('Jetoane: $tokens',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.storefront),
                  label: const Text('Cumpără jetoane'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StoreTab()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Istoric activități:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('utilizatori')
                        .doc(user.uid)
                        .collection('istoric')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text('Niciun istoric disponibil.');
                      }
                      return ListView.separated(
                          separatorBuilder: (context,index) => const Divider(height: 1),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                      final item = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                      leading: const Icon(Icons.history, color: Colors.indigo),
                      title: Text(item['actiune'] ?? '---'),
                      subtitle: Text(item['timestamp']?.toDate().toString() ?? ''),
                      );
                      },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      )
          : const Center(child: Text('Nicio sesiune activă.')),
    );
  }
}
