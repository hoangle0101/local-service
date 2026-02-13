// Test admin login and dashboard access
const axios = require('axios');

const API_BASE = 'http://localhost:3000';

async function testAdminLogin() {
  try {
    console.log('1️⃣  Testing login...');
    const loginResponse = await axios.post(`${API_BASE}/auth/login`, {
      phone: '0900000000',
      password: 'Admin123!@#',
    });

    console.log('✅ Login successful!');
    const { accessToken } = loginResponse.data;
    console.log(`   Token: ${accessToken.substring(0, 50)}...\n`);

    console.log('2️⃣  Testing /users/me...');
    try {
      const meResponse = await axios.get(`${API_BASE}/users/me`, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });
      console.log('✅ /users/me successful!');
      console.log(`   User: ${JSON.stringify(meResponse.data, null, 2)}\n`);
    } catch (error) {
      console.log('❌ /users/me failed!');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Message: ${error.response?.data?.message || error.message}\n`);
    }

    console.log('3️⃣  Testing /admin/dashboard...');
    try {
      const dashboardResponse = await axios.get(`${API_BASE}/admin/dashboard`, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });
      console.log('✅ /admin/dashboard successful!');
      console.log(`   Data keys: ${Object.keys(dashboardResponse.data).join(', ')}\n`);
    } catch (error) {
      console.log('❌ /admin/dashboard failed!');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Message: ${error.response?.data?.message || error.message}\n`);
    }
  } catch (error) {
    console.log('❌ Login failed!');
    console.log(`   Status: ${error.response?.status}`);
    console.log(`   Message: ${error.response?.data?.message || error.message}`);
  }
}

testAdminLogin();
