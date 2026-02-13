const axios = require('axios');

const API_BASE = 'http://localhost:3000';

async function testAllAdminEndpoints() {
  try {
    // 1. Login first
    console.log('🔐 Logging in...');
    const loginRes = await axios.post(`${API_BASE}/auth/login`, {
      phone: '0900000000',
      password: 'Admin123!@#',
    });
    
    const token = loginRes.data.data.accessToken;
    console.log('✅ Login successful\n');

    const headers = { Authorization: `Bearer ${token}` };

    // 2. Test /admin/dashboard
    console.log('📊 Testing /admin/dashboard...');
    const dashboardRes = await axios.get(`${API_BASE}/admin/dashboard`, { headers });
    console.log('Response structure:', JSON.stringify(dashboardRes.data, null, 2));
    console.log('Has wrapper:', !!dashboardRes.data.statusCode);
    console.log('Data path:', dashboardRes.data.data ? 'response.data.data' : 'response.data');
    console.log('');

    // 3. Test /admin/users
    console.log('👥 Testing /admin/users...');
    const usersRes = await axios.get(`${API_BASE}/admin/users?page=1&limit=5`, { headers });
    console.log('Response structure:', JSON.stringify(usersRes.data, null, 2).substring(0, 500) + '...');
    console.log('Has wrapper:', !!usersRes.data.statusCode);
    console.log('Data path:', usersRes.data.data ? 'response.data.data' : 'response.data');
    console.log('Has pagination:', !!usersRes.data.data?.pagination);
    console.log('');

    // 4. Test /admin/providers
    console.log('🏢 Testing /admin/providers...');
    const providersRes = await axios.get(`${API_BASE}/admin/providers?page=1&limit=5`, { headers });
    console.log('Response structure:', JSON.stringify(providersRes.data, null, 2).substring(0, 500) + '...');
    console.log('Has wrapper:', !!providersRes.data.statusCode);
    console.log('Data path:', providersRes.data.data ? 'response.data.data' : 'response.data');
    console.log('Has pagination:', !!providersRes.data.data?.pagination);
    console.log('');

    // 5. Test /admin/bookings
    console.log('📅 Testing /admin/bookings...');
    try {
      const bookingsRes = await axios.get(`${API_BASE}/admin/bookings?page=1&limit=5`, { headers });
      console.log('Response structure:', JSON.stringify(bookingsRes.data, null, 2).substring(0, 500) + '...');
      console.log('Has wrapper:', !!bookingsRes.data.statusCode);
      console.log('Data path:', bookingsRes.data.data ? 'response.data.data' : 'response.data');
      console.log('');
    } catch (err) {
      console.log('❌ Error:', err.response?.status, err.response?.data?.message || err.message);
      console.log('');
    }

    // 6. Test /admin/disputes
    console.log('⚖️  Testing /admin/disputes...');
    try {
      const disputesRes = await axios.get(`${API_BASE}/admin/disputes?page=1&limit=5`, { headers });
      console.log('Response structure:', JSON.stringify(disputesRes.data, null, 2).substring(0, 500) + '...');
      console.log('Has wrapper:', !!disputesRes.data.statusCode);
      console.log('Data path:', disputesRes.data.data ? 'response.data.data' : 'response.data');
      console.log('');
    } catch (err) {
      console.log('❌ Error:', err.response?.status, err.response?.data?.message || err.message);
      console.log('');
    }

    // 7. Test /admin/withdrawals
    console.log('💰 Testing /admin/withdrawals...');
    try {
      const withdrawalsRes = await axios.get(`${API_BASE}/admin/withdrawals?page=1&limit=5`, { headers });
      console.log('Response structure:', JSON.stringify(withdrawalsRes.data, null, 2).substring(0, 500) + '...');
      console.log('Has wrapper:', !!withdrawalsRes.data.statusCode);
      console.log('Data path:', withdrawalsRes.data.data ? 'response.data.data' : 'response.data');
      console.log('');
    } catch (err) {
      console.log('❌ Error:', err.response?.status, err.response?.data?.message || err.message);
      console.log('');
    }

    // 8. Test /admin/payments
    console.log('💳 Testing /admin/payments...');
    try {
      const paymentsRes = await axios.get(`${API_BASE}/admin/payments?page=1&limit=5`, { headers });
      console.log('Response structure:', JSON.stringify(paymentsRes.data, null, 2).substring(0, 500) + '...');
      console.log('Has wrapper:', !!paymentsRes.data.statusCode);
      console.log('Data path:', paymentsRes.data.data ? 'response.data.data' : 'response.data');
      console.log('');
    } catch (err) {
      console.log('❌ Error:', err.response?.status, err.response?.data?.message || err.message);
      console.log('');
    }

    // 9. Test /services/categories
    console.log('📁 Testing /services/categories...');
    try {
      const categoriesRes = await axios.get(`${API_BASE}/services/categories`, { headers });
      console.log('Response structure:', JSON.stringify(categoriesRes.data, null, 2).substring(0, 500) + '...');
      console.log('Has wrapper:', !!categoriesRes.data.statusCode);
      console.log('Data path:', categoriesRes.data.data ? 'response.data.data' : 'response.data');
      console.log('');
    } catch (err) {
      console.log('❌ Error:', err.response?.status, err.response?.data?.message || err.message);
      console.log('');
    }

    // 10. Test /users/me
    console.log('👤 Testing /users/me...');
    const meRes = await axios.get(`${API_BASE}/users/me`, { headers });
    console.log('Response structure:', JSON.stringify(meRes.data, null, 2).substring(0, 500) + '...');
    console.log('Has wrapper:', !!meRes.data.statusCode);
    console.log('Data path:', meRes.data.data ? 'response.data.data' : 'response.data');
    console.log('');

    console.log('✅ All tests completed!');

  } catch (error) {
    console.error('❌ Fatal error:', error.message);
    if (error.response) {
      console.error('Response:', error.response.data);
    }
  }
}

testAdminEndpoints();
