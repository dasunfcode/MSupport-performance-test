import http from 'k6/http';
import { check, sleep } from 'k6';
import { generateTokenPool } from '../scripts/generate_tokens.js';
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";

export const options = {
    vus: 5,
    duration: '30s'
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
        includeOCM: false,
        query: "test",
        offset: 0,
        limit: 20,
        sortBy: "companyId",
        sortOrder: "desc",
        filters: {
            companyType: [],
            country: [],
            city: [],
            timezone: [],
            status: [],
            language: [],
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
        'https://qa.msupport.mone.am/api/v1/organizations/search',
        payload,
        params
    );

    check(res, {
        'request successful': (r) => r.status === 201
    });

    sleep(1);
}

export function handleSummary(data) {
  return {
    "summary.html": htmlReport(data),
  };
}