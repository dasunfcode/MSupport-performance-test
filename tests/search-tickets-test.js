import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../scripts/config.js';
import { generateTokenPool } from '../scripts/generate_tokens.js';
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";
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

    console.log(`Generated ${tokens.length} tokens`);

    return { tokens };
}

export default function (data) {
    const tokens = data.tokens;

    // assign token per virtual user
    const token = tokens[__VU % tokens.length];

    const payload = JSON.stringify({
        limit: 20,
        offset: 0,
        sortBy: "createdAt",
        sortOrder: "desc",
        filters: {
            ticketType: ["problem"],
            classificationType: [],
            ticketPriority: [],
            status: [],
            creatorId: [],
            assigneeId: [],
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
        `${BASE_URL}/tickets/search`,
        payload,
        params
    );

    check(res, {
        'tickets search successful': (r) => r.status === 200
    });

    sleep(1);
}

export function handleSummary(data) {
    // Pass a custom test name to the template
    return summaryTemplate(data, "Search Tickets API");
}