// import fetch from 'node-fetch'; // Using global fetch

const API_URL = 'http://localhost:3000';

async function main() {
  try {
    console.log('🚀 Starting Bookings Module Test Flow...');

    // 1. Login as Provider (User 1)
    console.log('\n1️⃣  Logging in as Provider...');
    const providerLogin = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: '0901234567', password: 'Test123!@#' }),
    });
    const providerData = await providerLogin.json();
    if (!providerData.accessToken) throw new Error('Provider login failed');
    const providerToken = providerData.accessToken;
    console.log('✅ Provider logged in');

    // 2. Register/Login as Customer
    console.log('\n2️⃣  Registering/Logging in as Customer...');
    const customerPhone = '0987654321';
    const customerPass = 'Customer123!@#';
    
    // Try login first
    let customerLogin = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: customerPhone, password: customerPass }),
    });

    let customerToken;
    if (customerLogin.status === 401 || customerLogin.status === 404) {
      // Register if not exists
      console.log('   Registering new customer...');
      const register = await fetch(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          phone: customerPhone, 
          password: customerPass,
          fullName: 'Test Customer' 
        }),
      });
      const regData = await register.json();
      customerToken = regData.accessToken;
    } else {
      const loginData = await customerLogin.json();
      customerToken = loginData.accessToken;
    }
    
    if (!customerToken) throw new Error('Customer login/register failed');
    console.log('✅ Customer logged in');

    // 3. Estimate Booking
    console.log('\n3️⃣  Estimating Booking...');
    const estimateRes = await fetch(`${API_URL}/bookings/estimate`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${customerToken}`
      },
      body: JSON.stringify({
        serviceId: 1,
        scheduledAt: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
        latitude: 10.762622,
        longitude: 106.660172
      }),
    });
    const estimate = await estimateRes.json();
    console.log('   Estimate:', JSON.stringify(estimate, null, 2));
    if (!estimate.totalAmount) throw new Error('Estimation failed');
    console.log('✅ Estimation successful');

    // 4. Create Booking
    console.log('\n4️⃣  Creating Booking...');
    const createRes = await fetch(`${API_URL}/bookings`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${customerToken}`
      },
      body: JSON.stringify({
        serviceId: 1,
        scheduledAt: new Date(Date.now() + 86400000).toISOString(),
        addressText: '123 Test Street, HCMC',
        latitude: 10.762622,
        longitude: 106.660172,
        notes: 'Please be on time'
      }),
    });
    const booking = await createRes.json();
    console.log('   Booking Created:', JSON.stringify(booking, null, 2));
    if (!booking.id) throw new Error('Booking creation failed');
    const bookingId = booking.id;
    console.log(`✅ Booking created with ID: ${bookingId}`);

    // 5. Provider Accepts Booking
    console.log('\n5️⃣  Provider Accepting Booking...');
    const acceptRes = await fetch(`${API_URL}/provider/bookings/${bookingId}/accept`, {
      method: 'PATCH',
      headers: { 
        'Authorization': `Bearer ${providerToken}`
      },
    });
    const acceptData = await acceptRes.json();
    console.log('   Response:', acceptData);
    if (acceptData.status !== 'accepted') throw new Error('Accept booking failed');
    console.log('✅ Booking accepted');

    // 6. Provider Starts Booking
    console.log('\n6️⃣  Provider Starting Service...');
    const startRes = await fetch(`${API_URL}/provider/bookings/${bookingId}/start`, {
      method: 'PATCH',
      headers: { 
        'Authorization': `Bearer ${providerToken}`
      },
    });
    const startData = await startRes.json();
    console.log('   Response:', startData);
    if (startData.status !== 'in_progress') throw new Error('Start booking failed');
    console.log('✅ Service started');

    // 7. Provider Completes Booking
    console.log('\n7️⃣  Provider Completing Service...');
    const completeRes = await fetch(`${API_URL}/provider/bookings/${bookingId}/complete`, {
      method: 'PATCH',
      headers: { 
        'Authorization': `Bearer ${providerToken}`
      },
    });
    const completeData = await completeRes.json();
    console.log('   Response:', completeData);
    if (completeData.status !== 'completed') throw new Error('Complete booking failed');
    console.log('✅ Service completed');

    // 8. Customer Reviews Booking
    console.log('\n8️⃣  Customer Reviewing...');
    const reviewRes = await fetch(`${API_URL}/bookings/${bookingId}/review`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${customerToken}`
      },
      body: JSON.stringify({
        rating: 5,
        comment: 'Excellent service! Highly recommended.'
      }),
    });
    const reviewData = await reviewRes.json();
    console.log('   Response:', reviewData);
    if (!reviewData.id) throw new Error('Review failed');
    console.log('✅ Review submitted');

    // 9. Verify Final State
    console.log('\n9️⃣  Verifying Final Booking State...');
    const getRes = await fetch(`${API_URL}/bookings/${bookingId}`, {
      headers: { 
        'Authorization': `Bearer ${customerToken}`
      },
    });
    const finalBooking = await getRes.json();
    console.log('   Final Booking:', JSON.stringify(finalBooking, null, 2));
    
    if (finalBooking.status !== 'completed' || !finalBooking.review) {
      throw new Error('Final verification failed');
    }
    console.log('✅ Final state verified correctly');

    console.log('\n🎉 ALL TESTS PASSED SUCCESSFULLY!');

  } catch (error) {
    console.error('\n❌ TEST FAILED:', error);
    // console.error(error);
  }
}

main();
