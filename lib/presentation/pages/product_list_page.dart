import 'package:flutter/material.dart';
import 'package:watch_store/data/models/product.dart';
import 'package:watch_store/data/services/api_service.dart';
import 'package:watch_store/presentation/widgets/bottom_nav_bar.dart';
import 'product_detail_page.dart';
import 'package:watch_store/data/models/category.dart';
import 'package:watch_store/data/services/category_service.dart';
import 'package:watch_store/data/services/banner_service.dart';
import 'package:watch_store/data/models/banner_item.dart';
import 'dart:async'; // For auto-scrolling banners
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ApiService apiService = ApiService();
  final BannerService bannerService = BannerService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<BannerItem> _banners = [];
  Category? _selectedCategory;

  int _currentBannerIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSearching = false;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerTimer() {
    // Cancel existing timer if any
    _bannerTimer?.cancel();

    // Only start timer if we have more than one banner
    if (_banners.length <= 1) return;

    _bannerTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      int nextPage = _currentBannerIndex + 1;
      if (nextPage >= _banners.length) {
        nextPage = 0;
      }

      _bannerController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  Future<void> _initializeData() async {
    print("Starting to initialize data");
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print("Making API calls...");
      // Fetch products, categories, and banners in parallel
      final productsResult = await apiService.fetchProducts();
      final categoriesResult = await _categoryService.getAllCategories();
      final bannersResult = await bannerService.fetchBanners();
      
      print("API calls completed");
      print("Products: ${productsResult.length}");
      print("Categories: ${categoriesResult.length}");
      print("Banners: ${bannersResult.length}");
      
      if (mounted) {
        setState(() {
          _allProducts = productsResult;
          _filteredProducts = _allProducts;
          _categories = categoriesResult;
          _banners = bannersResult;
          _isLoading = false;
        });
      }
      
      _startBannerTimer();
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBanners() async {
    try {
      print('Loading banners...');
      final banners = await bannerService.fetchBanners();
      print('Loaded ${banners.length} banners');
      if (mounted) {
        setState(() {
          _banners = banners;
        });
      }
    } catch (e) {
      print('Error loading banners: $e');
    }
  }

  Future<void> _initializeProducts() async {
    try {
      final products = await apiService.fetchProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _errorMessage = '';
        });
      }
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products. Please try again.';
        });
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty && _selectedCategory == null) {
        _filteredProducts = _allProducts;
      } else {
        // Start with all products or category-filtered products
        var baseProducts = _selectedCategory == null
            ? _allProducts
            : _allProducts
                .where((p) => p.categoryId == _selectedCategory!.id)
                .toList();

        // Then apply text search
        if (query.isNotEmpty) {
          _filteredProducts = baseProducts
              .where((product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()) ||
                  product.description
                      .toLowerCase()
                      .contains(query.toLowerCase()))
              .toList();
        } else {
          _filteredProducts = baseProducts;
        }
      }
    });
  }

  void _filterByCategory(Category? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        // If no category is selected, show all products (but still respect search)
        if (_searchController.text.isEmpty) {
          _filteredProducts = _allProducts;
        } else {
          _filterProducts(_searchController.text);
        }
      } else {
        // Filter by selected category - fix the property name
        _filteredProducts = _allProducts
            .where((product) => product.categoryId == category.id)
            .toList();

        // Also apply search filter if there's any
        if (_searchController.text.isNotEmpty) {
          _filteredProducts = _filteredProducts
              .where((product) =>
                  product.name
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()) ||
                  product.description
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()))
              .toList();
        }
      }
    });
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeData,
            child: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No watches found matching "${_searchController.text}"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _filterProducts('');
            },
            child: Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    if (_banners.isEmpty) {
      print('No banners to display');
      return SizedBox();
    }

    print('Building carousel with ${_banners.length} banners');
    _banners.forEach((banner) {
      print('Banner URL: ${banner.imageUrl}');
    });

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 200,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return CachedNetworkImage(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) {
                  print('Error loading banner image: $error');
                  return Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        Text('Error loading image'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SmoothPageIndicator(
            controller: _bannerController,
            count: _banners.length,
            effect: WormEffect(
              dotWidth: 8,
              dotHeight: 8,
              activeDotColor: Theme.of(context).primaryColor,
              dotColor: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filterProducts,
        decoration: InputDecoration(
          hintText: 'Search watches...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterProducts('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty && _isSearching) {
      return _buildEmptySearchResults();
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          ).then((_) =>
              setState(() {})), // Refresh state when returning from details
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: Hero(
                      tag: 'product-${product.id}',
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.watch,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Luxury Watches',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: Colors.black87,
              size: 28,
            ),
            onPressed: () => Navigator.pushNamed(context, '/cart')
                .then((_) => setState(() {})),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? _buildErrorWidget()
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[50]!,
                          Colors.grey[100]!,
                          Colors.grey[200]!,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 12),
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _buildBannerCarousel(),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterProducts,
                            decoration: InputDecoration(
                              hintText: 'Search luxury watches...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search,
                                  color: Theme.of(context).primaryColor),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterProducts('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            padding: EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailPage(product: product),
                                  ),
                                ).then((_) => setState(() {})),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                            child: Hero(
                                              tag: 'product-${product.id}',
                                              child: Image.network(
                                                product.imageUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                letterSpacing: 0.5,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '\$${product.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushReplacementNamed(context, '/orders');
          if (index == 2) Navigator.pushReplacementNamed(context, '/profile');
        },
      ),
    );
  }

  // Add this new method to build the horizontal category list
  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return SizedBox(height: 8);
    }

    return Container(
      height: 100,
      margin: EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1, // +1 for "All" category
        itemBuilder: (context, index) {
          // First item is "All" category
          if (index == 0) {
            return _buildCategoryItem(
              null,
              'All',
              'https://res.cloudinary.com/dsklww89x/image/upload/v1741691808/p3xnwiig6cup2icadsih.jpg', // Use a default image for "All"
            );
          }
          
          final category = _categories[index - 1];
          // You can add category images to your backend or use placeholder images
          String imageUrl = 'https://via.placeholder.com/100?text=${category.name}';
          
          return _buildCategoryItem(
            category,
            category.name,
            imageUrl,
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(Category? category, String name, String imageUrl) {
    final isSelected = category == _selectedCategory || 
                      (category == null && _selectedCategory == null);
    
    return GestureDetector(
      onTap: () => _filterByCategory(category),
      child: Container(
        width: 80,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Icon(Icons.watch, size: 30),
              ),
            ),
            SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ... rest of your existing methods ...
}
