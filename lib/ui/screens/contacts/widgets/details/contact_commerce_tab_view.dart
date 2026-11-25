import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_pro/data/models/contact_details_aggregate.dart';

class ContactCommerceTabView extends StatelessWidget {
  final ContactEcommerceData ecommerce;
  final String? selectedStoreId;
  final bool isLoading;
  final bool isDark;
  final bool isArabic;
  final ValueChanged<String?> onSelectStore;
  final VoidCallback onRefresh;
  final ValueChanged<EcommerceStoreData> onLoadMoreOrders;

  const ContactCommerceTabView({
    super.key,
    required this.ecommerce,
    required this.selectedStoreId,
    required this.isLoading,
    required this.isDark,
    required this.isArabic,
    required this.onSelectStore,
    required this.onRefresh,
    required this.onLoadMoreOrders,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFF353C45).withValues(alpha: 0.16);
    final primaryText = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF282E34);
    final secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF626F7F);

    if (!ecommerce.enabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1D22) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined, size: 28, color: secondaryText),
                const SizedBox(height: 10),
                Text(
                  isArabic
                      ? 'تكامل المتجر الإلكتروني غير مفعل في مساحة العمل هذه'
                      : 'Ecommerce integration is not enabled in this workspace',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: secondaryText),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stores = selectedStoreId == null
        ? ecommerce.stores
        : ecommerce.stores.where((s) => s.connectionId == selectedStoreId).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedStoreId,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1C1D22) : Colors.white,
                      style: TextStyle(fontSize: 13.5, color: primaryText),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(isArabic ? 'كل المتاجر' : 'All stores'),
                        ),
                        ...ecommerce.stores.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s.connectionId,
                            child: Text(s.storeName, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: onSelectStore,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: isLoading ? null : onRefresh,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh_rounded, color: secondaryText),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final store = stores[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Store Match Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              store.isMatched
                                  ? (isArabic ? 'العميل مربوط بالمتجر' : 'Customer linked')
                                  : (isArabic ? 'العميل غير مربوط' : 'Customer not linked'),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: primaryText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: store.isMatched
                                    ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                    : const Color(0xFF4162E3).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                store.isMatched
                                    ? (isArabic ? 'مربوط' : 'matched')
                                    : (isArabic ? 'غير مربوط' : 'unmatched'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: store.isMatched
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF4162E3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${store.storeName}${store.storeDomain.isNotEmpty ? ' • ${store.storeDomain}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: secondaryText),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Provider error must be displayed as error, NOT "no orders found"
                  if (store.error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 17,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'خطأ في تحميل المتجر' : 'Store loading error',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            store.error!.code != null
                                ? '[${store.error!.code}] ${store.error!.message}'
                                : store.error!.message,
                            style: TextStyle(fontSize: 12.5, color: primaryText),
                          ),
                        ],
                      ),
                    )
                  else if (store.orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        isArabic
                            ? 'لا توجد طلبات لهذا العميل.'
                            : 'No orders found for this customer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: secondaryText),
                      ),
                    )
                  else ...[
                    for (final order in store.orders)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1D22) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.orderNumber,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                if (order.totalPrice != null)
                                  Text(
                                    '${order.totalPrice} ${order.currency ?? ''}'.trim(),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4162E3),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (order.financialStatus != null &&
                                    order.financialStatus!.isNotEmpty)
                                  _statusBadge(order.financialStatus!, const Color(0xFF10B981)),
                                if (order.fulfillmentStatus != null &&
                                    order.fulfillmentStatus!.isNotEmpty)
                                  _statusBadge(order.fulfillmentStatus!, const Color(0xFFF59E0B)),
                              ],
                            ),
                            if (order.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('MMM dd, yyyy hh:mm a').format(order.createdAt!),
                                style: TextStyle(fontSize: 11.5, color: secondaryText),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (store.hasNextPage)
                      Center(
                        child: TextButton(
                          onPressed: isLoading ? null : () => onLoadMoreOrders(store),
                          child: Text(
                            isArabic ? 'تحميل المزيد من الطلبات' : 'Load more orders',
                            style: const TextStyle(color: Color(0xFF4162E3)),
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
