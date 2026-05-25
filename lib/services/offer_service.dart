import 'package:dio/dio.dart';

import '../models/offer_model.dart';
import 'api_client.dart';

class OfferService {
  final Dio dio = ApiClient.dio;

  Future<OfferModel> createOffer({
    required int conversationId,
    required int productId,
    required int sellerId,
    required double offeredPrice,
  }) async {
    try {
      final response = await dio.post(
        '/offers',
        data: {
          'conversation_id': conversationId,
          'product_id': productId,
          'seller_id': sellerId,
          'offered_price': offeredPrice,
        },
      );

      return OfferModel.fromJson(response.data['offer']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create offer',
      );
    }
  }

  Future<void> acceptOffer(int offerId) async {
    try {
      await dio.patch('/offers/$offerId/accept');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to accept offer',
      );
    }
  }

  Future<void> declineOffer(int offerId) async {
    try {
      await dio.patch('/offers/$offerId/decline');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to decline offer',
      );
    }
  }
}