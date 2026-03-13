import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../scripts/config.js';
import { generateTokenPool } from '../scripts/generate_tokens.js';
import { rampStages } from '../scripts/ramp-config.js';
import { handleSummary as summaryTemplate } from '../scripts/reportTemplate.js';

// Use ramp stages instead of fixed vus/duration
export const options = {
    stages: rampStages
};

export function setup() {
    const tokens = generateTokenPool();

    if (!tokens.length) {
        throw new Error('No tokens generated!');
    }

    console.log(`Generated ${tokens.length} tokens`);

    return { tokens };
}

export default function (data) {
    const tokens = data.tokens;

    // Assign token per virtual user
    const token = tokens[__VU % tokens.length];

    const payload = JSON.stringify({
        name: "test",
        description: "test",
        type: "problem",
        assetSerialNumber: "MPRDEV1",
        assetStatus: "running",
        assigneeId: "47f7e5bf-4c8b-4578-ba1e-eb8f24bc2608",
        classificationTypeKey: "failure_without_downtime",
        files: [],
        priority: "low",
        status: "to_do"
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': `access_token=${token}`
        }
    };

    const res = http.post(
        `${BASE_URL}/tickets`,
        payload,
        params
    );

    check(res, {
        'ticket created successfully': (r) => r.status === 201
    });

    sleep(1);
}

export function handleSummary(data) {
    // Pass a custom test name to the template
    return summaryTemplate(data, "Create Tickets API");
}