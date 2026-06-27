// lib/services/api_config.dart

const String kBaseUrl = 'https://safecar-api.onrender.com'; // ← cambia si tienes otra URL

// Endpoints
const String kTowEndpoint       = '$kBaseUrl/tow';
const String kBookingsEndpoint  = '$kBaseUrl/bookings';
const String kOrdersEndpoint    = '$kBaseUrl/orders/admin/all';
const String kQuotesEndpoint    = '$kBaseUrl/quote-requests';
const String kRegisterToken     = '$kBaseUrl/notifications/register-token';
const String kNotifLog          = '$kBaseUrl/notifications/log';
