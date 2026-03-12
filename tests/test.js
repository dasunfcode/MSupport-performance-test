import http from 'k6/http';
import { check } from 'k6';

export default function () {

    // Step 1: Login
    const loginRes = http.post('https://qa.msupport.mone.am/api/v1/login', {
        email: 'testuser1@example.com',
        password: 'Test@1234'
    });

    console.log('Login status:', loginRes.status);

    // Step 2: Extract token from cookie
    let token;
    const cookie = loginRes.headers['Set-Cookie'];

    if (cookie) {
        const match = cookie.match(/access_token=([^;]+)/);
        token = match ? match[1] : null;
    } else {
        const bodyJson = JSON.parse(loginRes.body);
        token = bodyJson.data?.token || bodyJson.data?.access_token;
    }

    console.log('Token:', token);

    check(token, { 'token exists': (t) => t !== null });

    // Step 3: Call search endpoint using token
    const params = {
        headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
    };

    const searchRes = http.get(
        'https://qa.msupport.mone.am/api/v1/organizations/search?q=test',
        params
    );

    console.log('Search status:', searchRes.status);
    console.log('Search body:', searchRes.body);

    check(searchRes, {
        'search status is 200': (r) => r.status === 200,
    });
}