import 'package:flutter/material.dart';
import '../models/filter_item.dart';

class VisualFilterSelector extends StatefulWidget {
  final List<FilterItem> filterItems;
  final FilterItem currentFilter;
  final Function(FilterItem) onFilterChanged;
  final VoidCallback onCloseMenu;

  const VisualFilterSelector({
    super.key,
    required this.filterItems,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onCloseMenu,
  });

  @override
  State<VisualFilterSelector> createState() => _VisualFilterSelectorState();
}

class _VisualFilterSelectorState extends State<VisualFilterSelector> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.filterItems.indexOf(widget.currentFilter);
    _pageController = PageController(initialPage: initialIndex, viewportFraction: 0.28); // Elemanların birbirine olan yakınlığı (0.28 idealdir)
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.filterItems.length,
            onPageChanged: (index) {
              widget.onFilterChanged(widget.filterItems[index]);
            },
            itemBuilder: (context, index) {
              final filter = widget.filterItems[index];
              double scale = (1 - ((index - _currentPage).abs() * 0.2)).clamp(0.7, 1.0);
              final bool isSelected = filter.name == widget.currentFilter.name;

              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? Border.all(color: Colors.blueAccent, width: 3) : null,
                        boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10)] : [],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.primaries[index % Colors.primaries.length].withOpacity(0.8),
                                  Colors.grey[900]!
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              filter.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 25),
        
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 32),
          onPressed: widget.onCloseMenu,
        ),
      ],
    );
  }
}