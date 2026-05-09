import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/splash_screen.dart';
import '../screens/update_screen.dart';
import '../screens/myAccount/login_screen.dart';
import '../screens/myAccount/signup_step1.dart';
import '../screens/myAccount/signup_step2.dart';
import '../screens/myAccount/signup_step3.dart';
import '../screens/myAccount/signup_step4.dart';
import '../screens/home_screen.dart';
import '../screens/myAccount/inactive_screen.dart';
import '../screens/options/add_product_screen.dart';
import '../screens/options/add_offer_screen.dart';
import '../screens/options/add_discount_screen.dart';
import '../screens/options/add_section_screen.dart';
import '../screens/myAccount/update_account_screen.dart';
import '../screens/options/price_adjustment_screen.dart';
import '../screens/options/customer_withdrawals_screen.dart';
import '../screens/options/complaints_screen.dart';
import '../screens/options/suggestions_screen.dart';
import '../screens/options/about_screen.dart';
import '../screens/options/job_vacancies_screen.dart';
import '../screens/options/add_job_vacancy_screen.dart';
import '../screens/options/edit_job_vacancy_screen.dart';
import '../screens/options/customer_withdrawals_details_screen.dart';
import '../screens/options/monthly_dues_screen.dart';
import '../screens/options/add_slider_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/edit_product_screen.dart';
import '../screens/offer_detail_screen.dart';
import '../screens/edit_slider_screen.dart';
import 'account_provider.dart';

// Define route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup1 = '/signup-step-1';
  static const String signup2 = '/signup-step-2';
  static const String signup3 = '/signup-step-3';
  static const String signup4 = '/signup-step-4';
  static const String signupStep1 = '/signup-step-1';
  static const String signupStep2 = '/signup-step-2';
  static const String signupStep3 = '/signup-step-3';
  static const String signupStep4 = '/signup-step-4';
  static const String home = '/home';
  static const String inactive = '/inactive';
  static const String update = '/update';
  static const String addProduct = '/add-product';
  static const String addOffer = '/add-offer';
  static const String addDiscount = '/add-discount';
  static const String addSection = '/add-section';
  static const String updateAccount = '/update-account';
  static const String priceAdjustment = '/price-adjustment';
  static const String customerWithdrawals = '/customer-withdrawals';
  static const String complaints = '/complaints';
  static const String suggestions = '/suggestions';
  static const String about = '/about';
  static const String jobVacancies = '/job-vacancies';
  static const String addJobVacancy = '/add-job-vacancy';
  static const String editJobVacancy = '/edit-job-vacancy';
  static const String customerWithdrawalsDetails = '/customer-withdrawals-details';
  static const String monthlyDues = '/monthly-dues';
  static const String addSlider = '/add-slider';
  static const String productDetail = '/product-detail';
  static const String editProduct = '/edit-product';
  static const String offerDetail = '/offer-detail';
  static const String editSlider = '/edit-slider';
}

// GoRouter provider
final goRouterProvider = Provider<GoRouter>((ref) {
  // DO NOT watch accountProvider here!
  // Watching it causes GoRouter to recreate on every state change,
  // which resets navigation to initialLocation (splash screen).
  // Auth navigation is handled by individual screens (splash_screen, home_screen).

  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.signupStep1,
        name: 'signup-step-1',
        builder: (context, state) => const SignupStep1(),
      ),

      GoRoute(
        path: AppRoutes.signupStep2,
        name: 'signup-step-2',
        builder: (context, state) => const SignupStep2(),
      ),

      GoRoute(
        path: AppRoutes.signupStep3,
        name: 'signup-step-3',
        builder: (context, state) => const SignupStep3(),
      ),

      GoRoute(
        path: AppRoutes.signupStep4,
        name: 'signup-step-4',
        builder: (context, state) => const SignupStep4(),
      ),

      // Home Screen
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) {
          final initialTabIndex = state.uri.queryParameters['tab'] != null
              ? int.tryParse(state.uri.queryParameters['tab']!) ?? 0
              : 0;
          return HomeScreen(initialTabIndex: initialTabIndex);
        },
      ),

      // Inactive Screen
      GoRoute(
        path: AppRoutes.inactive,
        name: 'inactive',
        builder: (context, state) => const InactiveScreen(),
      ),

      // Update Screen
      GoRoute(
        path: AppRoutes.update,
        name: 'update',
        builder: (context, state) {
          final storeUrl =
              state.uri.queryParameters['url'] ?? 'https://altallmarketdelivery.carrd.co';
          return OptionalUpdateScreen(storeUrl: storeUrl);
        },
      ),

      // Product Management
      GoRoute(
        path: AppRoutes.addProduct,
        name: 'add-product',
        builder: (context, state) => const AddProductScreen(),
      ),

      GoRoute(
        path: AppRoutes.editProduct,
        name: 'edit-product',
        builder: (context, state) {
          final args = (state.extra is Map<String, dynamic>)
              ? state.extra as Map<String, dynamic>
              : <String, dynamic>{};
          return EditProductScreen(
            product: (args['product'] as Map<String, dynamic>?) ?? <String, dynamic>{},
            offer: args['offer'] as Map<String, dynamic>?,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.productDetail,
        name: 'product-detail',
        builder: (context, state) {
          final args = (state.extra is Map<String, dynamic>)
              ? state.extra as Map<String, dynamic>
              : <String, dynamic>{};
          return ProductDetailScreen(
            product: (args['product'] as Map<String, dynamic>?) ?? <String, dynamic>{},
            offer: args['offer'] as Map<String, dynamic>?,
          );
        },
      ),

      // Offer Management
      GoRoute(
        path: AppRoutes.addOffer,
        name: 'add-offer',
        builder: (context, state) => const AddOfferScreen(),
      ),

      GoRoute(
        path: AppRoutes.offerDetail,
        name: 'offer-detail',
        builder: (context, state) {
          final args = (state.extra is Map<String, dynamic>)
              ? state.extra as Map<String, dynamic>
              : <String, dynamic>{};
          return OfferDetailScreen(
            offer: (args['offer'] as Map<String, dynamic>?) ?? <String, dynamic>{},
            product: (args['product'] as Map<String, dynamic>?) ?? <String, dynamic>{},
          );
        },
      ),

      // Discount Management
      GoRoute(
        path: AppRoutes.addDiscount,
        name: 'add-discount',
        builder: (context, state) => const AddDiscountScreen(),
      ),

      // Section Management
      GoRoute(
        path: AppRoutes.addSection,
        name: 'add-section',
        builder: (context, state) => const AddSectionPage(),
      ),

      // Account Management
      GoRoute(
        path: AppRoutes.updateAccount,
        name: 'update-account',
        builder: (context, state) => const UpdateAccountPage(),
      ),

      // Options & Settings
      GoRoute(
        path: AppRoutes.priceAdjustment,
        name: 'price-adjustment',
        builder: (context, state) => const PriceAdjustmentScreen(),
      ),

      GoRoute(
        path: AppRoutes.customerWithdrawals,
        name: 'customer-withdrawals',
        builder: (context, state) => const CustomerWithdrawalsScreen(),
      ),

      GoRoute(
        path: AppRoutes.customerWithdrawalsDetails,
        name: 'customer-withdrawals-details',
        builder: (context, state) {
          final args = (state.extra is Map<String, dynamic>)
              ? state.extra as Map<String, dynamic>
              : <String, dynamic>{};
          return CustomerWithdrawalsDetailsScreen(
            customerId: args['customerId'] ?? 0,
            fullName: args['fullName'] ?? '',
            filter: args['filter'] ?? 'all',
          );
        },
      ),

      GoRoute(
        path: AppRoutes.monthlyDues,
        name: 'monthly-dues',
        builder: (context, state) => const MonthlyDuesScreen(),
      ),

      GoRoute(
        path: AppRoutes.complaints,
        name: 'complaints',
        builder: (context, state) => const ComplaintsScreen(),
      ),

      GoRoute(
        path: AppRoutes.suggestions,
        name: 'suggestions',
        builder: (context, state) => const SuggestionsScreen(),
      ),

      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),

      // Job Management
      GoRoute(
        path: AppRoutes.jobVacancies,
        name: 'job-vacancies',
        builder: (context, state) => const JobVacanciesScreen(),
      ),

      GoRoute(
        path: AppRoutes.addJobVacancy,
        name: 'add-job-vacancy',
        builder: (context, state) => const AddJobVacancyScreen(),
      ),

      GoRoute(
        path: AppRoutes.editJobVacancy,
        name: 'edit-job-vacancy',
        builder: (context, state) {
          final vacancy = (state.extra is Map)
              ? Map<String, dynamic>.from(state.extra as Map)
              : null;
          return EditJobVacancyScreen(vacancy: vacancy);
        },
      ),

      // Slider Management
      GoRoute(
        path: AppRoutes.addSlider,
        name: 'add-slider',
        builder: (context, state) => const AddSliderScreen(),
      ),

      GoRoute(
        path: AppRoutes.editSlider,
        name: 'edit-slider',
        builder: (context, state) {
          final slider = (state.extra is Map<String, dynamic>)
              ? state.extra as Map<String, dynamic>
              : <String, dynamic>{};
          return EditSliderScreen(slider: slider);
        },
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('الخطأ')),
        body: Center(
          child: Text('الصفحة غير موجودة: ${state.uri}'),
        ),
      );
    },
  );
});
