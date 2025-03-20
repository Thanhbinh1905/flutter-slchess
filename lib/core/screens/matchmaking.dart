import 'package:flutter/material.dart';

class MatchMakingScreen extends StatefulWidget {
  const MatchMakingScreen({super.key});

  @override
  State<MatchMakingScreen> createState() => _MatchMakingScreenState();
}

class _MatchMakingScreenState extends State<MatchMakingScreen> {
  bool isQueued = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: mainContainer(
        child: Center(
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Avatar User
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25), // Bo góc tròn
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset(
                            'assets/default_avt.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      if (isQueued) ...[
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Image.asset(
                              'assets/weapon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ] else
                        const CircularProgressIndicator(),
                      const SizedBox(width: 10),

                      // Avatar Enemy
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset(
                            'assets/default_avt.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isQueued ? "Queued" : "Queueing.....",
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {}, child: const Text("Cancel")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget mainContainer({Widget? child}) {
  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/bg_dark.png"),
        fit: BoxFit.cover,
      ),
    ),
    child: child ?? const Center(),
  );
}
