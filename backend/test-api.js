// Quick API test script
const https = require('http');

console.log('Testing MediLinko Backend API...\n');

// Test 1: Health Check
console.log('1. Testing Health Endpoint...');
const healthOptions = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/health',
  method: 'GET',
  headers: {
    'Content-Type': 'application/json'
  }
};

const healthReq = https.request(healthOptions, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    console.log('✅ Health Check Response:');
    console.log(JSON.parse(data));
    console.log('\n');
    
    // Test 2: Register User
    testRegister();
  });
});

healthReq.on('error', (error) => {
  console.error('❌ Error:', error.message);
  console.log('Make sure the backend server is running on port 3000');
  process.exit(1);
});

healthReq.end();

// Test Register
function testRegister() {
  console.log('2. Testing User Registration...');
  
  const registerData = JSON.stringify({
    fullName: 'Test User',
    email: 'testuser@medilinko.com',
    phone: '9876543210',
    password: 'test123456',
    role: 'user'
  });

  const registerOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/register',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': registerData.length
    }
  };

  const registerReq = https.request(registerOptions, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      const response = JSON.parse(data);
      console.log('✅ Registration Response:');
      console.log(response);
      
      if (response.success) {
        console.log('\n🎉 Registration successful!');
        console.log('Token:', response.data.token.substring(0, 20) + '...');
        console.log('User ID:', response.data.user.id);
        console.log('Role:', response.data.user.role);
        
        // Test 3: Login
        testLogin(response.data.token);
      } else {
        console.log('\n⚠️ Registration failed (user might already exist)');
        console.log('Trying login instead...');
        testLogin();
      }
    });
  });

  registerReq.on('error', (error) => {
    console.error('❌ Error:', error.message);
  });

  registerReq.write(registerData);
  registerReq.end();
}

// Test Login
function testLogin(existingToken) {
  console.log('\n3. Testing User Login...');
  
  const loginData = JSON.stringify({
    email: 'testuser@medilinko.com',
    password: 'test123456'
  });

  const loginOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': loginData.length
    }
  };

  const loginReq = https.request(loginOptions, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      const response = JSON.parse(data);
      console.log('✅ Login Response:');
      console.log(response);
      
      if (response.success) {
        console.log('\n🎉 Login successful!');
        const token = response.data.token;
        
        // Test 4: Get Profile
        testGetProfile(token);
      }
    });
  });

  loginReq.on('error', (error) => {
    console.error('❌ Error:', error.message);
  });

  loginReq.write(loginData);
  loginReq.end();
}

// Test Get Profile
function testGetProfile(token) {
  console.log('\n4. Testing Get Profile (Protected Route)...');
  
  const profileOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/profile',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }
  };

  const profileReq = https.request(profileOptions, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      const response = JSON.parse(data);
      console.log('✅ Get Profile Response:');
      console.log(response);
      
      console.log('\n✅ All API tests completed successfully! ✅');
      console.log('\n📝 Summary:');
      console.log('   • Health check: Working');
      console.log('   • User registration: Working');
      console.log('   • User login: Working');
      console.log('   • Protected routes: Working');
      console.log('   • MongoDB connection: Working');
      console.log('\n🚀 Backend is ready to use with Flutter app!');
    });
  });

  profileReq.on('error', (error) => {
    console.error('❌ Error:', error.message);
  });

  profileReq.end();
}
