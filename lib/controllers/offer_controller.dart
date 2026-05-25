import '../models/offer_model.dart';
import '../services/offer_service.dart';

class OfferController {
  final OfferService _offerService = OfferService();

  Future<OfferModel> createOffer({
    required int conversationId,
    required int productId,
    required int sellerId,
    required double offeredPrice,
  }) async {
    if (offeredPrice <= 0) {
      throw Exception('Offer amount must be greater than 0');
    }

    return await _offerService.createOffer(
      conversationId: conversationId,
      productId: productId,
      sellerId: sellerId,
      offeredPrice: offeredPrice,
    );
  }

  Future<void> acceptOffer(int offerId) async {
    await _offerService.acceptOffer(offerId);
  }

  Future<void> declineOffer(int offerId) async {
    await _offerService.declineOffer(offerId);
  }
}