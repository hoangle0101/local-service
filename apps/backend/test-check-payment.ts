// Test the check payment status endpoint
const API_URL = 'http://localhost:3000';

async function testCheckPaymentStatus() {
  const orderId = 'BOOKING_113_1766680664066'; // From user's logs

  console.log('Testing GET /bookings/check-payment-status');
  console.log('OrderId:', orderId);
  console.log('---');

  try {
    // First, get a token (you'll need to login first)
    // For now, let's just test without auth to see the error
    const url = `${API_URL}/bookings/check-payment-status?orderId=${orderId}`;
    console.log('URL:', url);

    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        // Add auth token here if you have one
        // 'Authorization': 'Bearer YOUR_TOKEN'
      },
    });

    console.log('Status:', response.status);
    const data = await response.json();
    console.log('Response:', JSON.stringify(data, null, 2));
  } catch (error: any) {
    console.error('Error:', error.message);
  }
}

testCheckPaymentStatus();

// Export to make this a module and avoid global scope conflicts
export {};
