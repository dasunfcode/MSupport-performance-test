# MSupport Load Tests

A **k6-based test suite** to measure the performance of the MSupport API, covering login, ticket creation, searching, updating tickets, and more.

---

## Requirements

* **Windows**
* **PowerShell**
* **k6** installed:

```powershell
choco install k6
```

---

## Quick Setup

1. **Clone the repository**

```bash
git clone <your-repo-url>
cd MSupport-performance-test
```

2. **Create a `.env` file** in the project root:

```env
BASE_URL=https://qa.msupport.mone.am/api/v1
```

3. **Run all tests**

```powershell
.\run-all-tests.ps1
```

---

## Running Tests

**Run all tests**:

```powershell
.\run-all-tests.ps1
```

**Run a single test**:

```powershell
.\run-k6.ps1 run tests/create-tickets-test.js
```

**Customize load** (VUs or duration):

```powershell
.\run-k6.ps1 run -e VUS=20 -e DURATION=2m tests/login-test.js
```

---

## Ramping Scenarios

Some tests use **ramping** to simulate real-world traffic:

```javascript
export const options = {
    scenarios: {
        ramp_up: {
            executor: 'ramping-vus',
            startVUs: 1,
            stages: [
                { duration: '30s', target: 10 },
                { duration: '1m', target: 50 },
                { duration: '30s', target: 0 }
            ]
        }
    }
};
```

---

## Adding a New API Test

1. **Create a new test** in `tests/`, e.g., `tests/new-endpoint-test.js`.
2. **Import utilities**:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../scripts/config.js';
import { generateTokenPool } from '../scripts/generate_tokens.js';
```

3. **Setup tokens** (if needed):

```javascript
export function setup() {
    const tokens = generateTokenPool();
    return { tokens };
}
```

4. **Write test logic**:

```javascript
export default function (data) {
    const token = data.tokens[__VU % data.tokens.length];
    const headers = { Authorization: `Bearer ${token}` };

    const res = http.get(`${BASE_URL}/new-endpoint`, { headers });
    check(res, { 'status is 200': (r) => r.status === 200 });

    sleep(Math.random() * 3);
}
```

5. **Define test options**:

```javascript
export const options = {
    vus: 10,
    duration: '1m'
};
```

6. **Add HTML report** (optional):

```javascript
import { handleSummary as summaryTemplate } from '../scripts/reportTemplate.js';

export function handleSummary(data) {
    return summaryTemplate(data, 'new-endpoint');
}
```

7. **Include in `run-all-tests.ps1`** if desired.

---

## Settings

**Change API URL**:

```env
BASE_URL=https://your-api-url.com/api/v1
```

**Change test load** (per test or via CLI):

```javascript
export const options = { vus: 10, duration: '1m' };
```

Override via CLI:

```powershell
.\run-k6.ps1 run -e VUS=20 -e DURATION=2m tests/new-endpoint-test.js
```

---

