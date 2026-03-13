import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../scripts/config.js';
import { rampStages } from '../scripts/ramp-config.js';
import { handleSummary as summaryTemplate } from '../scripts/reportTemplate.js';

// Hardcoded test users
const usersData = [
  { email: "testuser1@example.com", password: "Test@1234" },
  { email: "testuser2@example.com", password: "Test@1234" },
  { email: "testuser3@example.com", password: "Test@1234" },
  { email: "testuser4@example.com", password: "Test@1234" },
  { email: "testuser5@example.com", password: "Test@1234" }
];

export const options = {
    stages: rampStages
};

export default function () {
    // Assign a user to each VU
    const user = usersData[(__VU - 1) % usersData.length];

    const payload = JSON.stringify({
        email: user.email,
        password: user.password
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
            'x-timezone': 'Asia/Colombo'
        }
    };

    const res = http.post(`${BASE_URL}/auth/login`, payload, params);

    check(res, {
        'login successful': (r) => r.status === 200,
    });

    console.log(`VU ${__VU} logged in with ${user.email} - status: ${res.status}`);

    sleep(1);
}

export function handleSummary(data) {
    // Pass a custom test name to the template
    return summaryTemplate(data, "Login API");
}