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

    const token = tokens[0];
    const searchRes = http.post(
        `${BASE_URL}/assets/search`,
        JSON.stringify({ offset: 0, limit: 1 }),
        {
            headers: {
                'Content-Type': 'application/json',
                'Cookie': `access_token=${token}`
            }
        }
    );

    let assetId = 'sample-asset-id';
    if (searchRes.status === 200 || searchRes.status === 201) {
        const body = JSON.parse(searchRes.body);
        if (body.items && body.items.length > 0) {
            assetId = body.items[0].id;
        }
    }

    return { tokens, assetId };
}

export default function (data) {
    const { tokens, assetId } = data;
    const token = tokens[__VU % tokens.length];

    const params = {
        headers: {
            'Accept': 'application/json',
            'Cookie': `access_token=${token}`
        }
    };

    const res = http.get(
        `${BASE_URL}/assets/${assetId}/mcare-package`,
        params
    );

    check(res, {
        'get asset mcare package successful': (r) => r.status === 200
    });

    sleep(Math.random() * 2 + 1);
}

export function handleSummary(data) {
    return summaryTemplate(data, "Get Asset MCare Package API");
}
