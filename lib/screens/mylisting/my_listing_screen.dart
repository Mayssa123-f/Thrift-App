import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "MY LISTINGS",
          style: GoogleFonts.syne(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: "ACTIVE"),
            Tab(text: "SOLD"),
            Tab(text: "DRAFTS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListingGrid(isActive: true),
          _buildListingGrid(isActive: false),
          _buildDraftsList(),
        ],
      ),
      // Floating Action Button to quickly add a new item
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Navigate to your MultiStepSellScreen here
        },
      ),
    );
  }

  Widget _buildListingGrid({required bool isActive}) {
    // Dummy data for visual representation
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: 4, // Replace with your actual list length
      itemBuilder: (context, index) {
        return _buildItemCard(isActive);
      },
    );
  }

  Widget _buildItemCard(bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage("https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=500"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!isActive)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      "SOLD",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.more_vert, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Vintage Bag",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        Text(
          "\$45.00",
          style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDraftsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Untitled Draft", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    Text("Last edited 2 days ago", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 20),
            ],
          ),
        );
      },
    );
  }
}