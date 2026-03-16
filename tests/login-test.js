import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../scripts/config.js';
import { rampStages } from '../scripts/ramp-config.js';
import { handleSummary as summaryTemplate } from '../scripts/reportTemplate.js';
import { users } from '../data/users.js';

export const options = {
    stages: rampStages
};

export default function () {
    // Assign a user to each VU
    const user = users[(__VU - 1) % users.length];

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

    sleep(Math.random() * 2 + 1);
}

export function handleSummary(data) {
    return summaryTemplate(data, "Login API");
}