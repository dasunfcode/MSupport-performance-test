import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../scripts/config.js';
import { generateTokenPool } from '../scripts/generate_tokens.js';
import { rampStages } from '../scripts/ramp-config.js';
import { handleSummary as summaryTemplate } from '../scripts/reportTemplate.js';

export const options = {
    stages: rampStages
};

export function setup() {
    const tokens = generateTokenPool();

    if (!tokens.length) {
        throw new Error('No tokens generated!');
    }

    return { tokens };
}

export default function (data) {
    const tokens = data.tokens;
    const token = tokens[__VU % tokens.length];

    const payload = JSON.stringify({
        query: "",
        filters: {
            assetType: [],
            status: [],
            organizationId: [],
            createdAt: {
                from: null,
                to: null
            }
        }
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': `access_token=${token}`
        }
    };

    const res = http.post(
        `${BASE_URL}/assets/export`,
        payload,
        params
    );

    check(res, {
        'assets export successful': (r) => r.status === 200 || r.status === 201
    });

    sleep(Math.random() * 2 + 1);
}

export function handleSummary(data) {
    return summaryTemplate(data, "Assets Export API");
}
