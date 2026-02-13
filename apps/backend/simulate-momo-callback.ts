const SIM_API_URL = 'http://localhost:3000';

async function simulateMomoCallback(bookingId: string) {
  console.log(`🚀 Simulating MoMo Callback for Booking #${bookingId}...`);

  const callbackData = {
    partnerCode: 'MOMO',
    orderId: 'BOOKING_' + bookingId + '_' + Date.now(),
    requestId: 'REQ_' + Date.now(),
    amount: 100000,
    orderInfo: 'Thanh toán dịch vụ',
    orderType: 'momo_wallet',
    transId: 'TRANS_' + Date.now(),
    resultCode: 0,
    message: 'Success',
    payType: 'qr',
    responseTime: Date.now(),
    extraData: JSON.stringify({
      type: 'booking_payment',
      bookingId: bookingId,
    }),
    signature: 'mock_signature',
  };

  try {
    const response = await fetch(`${SIM_API_URL}/payments/momo/callback`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(callbackData),
    });

    const data = await response.json();
    console.log('✅ Callback response:', data);
    console.log('---');

    // Check booking status
    console.log('🔍 Checking Booking Status...');
    // We need a token to check, but let's assume we can check via DB if needed
    // Or just check the logs.
  } catch (error: any) {
    console.error('❌ Callback failed:', error.message);
  }
}

// Get bookingId from command line args
const bookingId = process.argv[2];
if (!bookingId) {
  console.error('Usage: ts-node simulate-momo-callback.ts <bookingId>');
  process.exit(1);
}

simulateMomoCallback(bookingId);
