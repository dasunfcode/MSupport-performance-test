import http from 'k6/http';

const BASE_URL = 'https://qa.msupport.mone.am/api/v1';

const users = [
  { email: "testuser1@example.com", password: "Test@1234" },
  { email: "testuser2@example.com", password: "Test@1234" },
  { email: "testuser3@example.com", password: "Test@1234" },
  { email: "testuser4@example.com", password: "Test@1234" },
  { email: "testuser5@example.com", password: "Test@1234" }
];

export function generateTokenPool(userList = users) {

    const tokens = [];

    userList.forEach((user, index) => {

        const payload = JSON.stringify({
            email: user.email,
            password: user.password
        });

        const params = {
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const res = http.post(`${BASE_URL}/auth/login`, payload, params);

        if (res.status !== 200) {
            console.error(`Login failed for ${user.email} | Status: ${res.status}`);
            return;
        }

        const setCookie = res.headers['Set-Cookie'] || res.headers['set-cookie'];

        let token = null;

        if (setCookie) {
            const match = setCookie.match(/access_token=([^;]+);/);
            if (match) {
                token = match[1];
            }
        }

        if (!token) {
            console.error(`No token found for ${user.email}`);
            return;
        }

        tokens.push(token);

        console.log(`TOKEN_${index + 1} generated for ${user.email}`);
    });

    console.log(`Finished generating tokens for ${tokens.length} users`);

    return tokens;
}