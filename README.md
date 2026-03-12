---

# MSupport Load Test Framework

A simple K6-based load testing framework for the MSupport API. Designed to simulate user logins and API requests under load.

---

##  Quick Start

### 1. Install prerequisites

**Install Chocolatey (Windows)**

```powershell id="choco-install"
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**Install K6**

```bash id="k6-install"
choco install k6
```

---

### 2. Clone the repository

```bash id="repo-clone"
git clone <repository-url>
cd MSupport-performance-test
```

---

### 3. Run basic tests

```bash id="run-sample"
k6 run sample.js
k6 run tests/login-test.js
```

**Override options if needed:**

```bash id="run-custom"
k6 run -e VUS=50 -e DURATION=5m tests/organizations-search-test.js
```

---

##  Repository Structure

```id="repo-structure"
MSupport-performance-test/
├── config/                  # Config files
├── data/    
├── scripts/                 # Token generation utilities
├── tests/                   # Test scripts (login, search, etc.)
├── sample.js                # Example K6 test
└── README.md
```

---

##  Token Management

### How Tokens Work

1. Test users are loaded from hardcoded test users.
2. Each user logs in via `POST /auth/login`.
3. Tokens (`access_token`) are extracted from response headers.
4. Tokens are stored in a pool and reused in tests.

### Use Tokens in Tests

```javascript id="tokens-usage"
export function setup() {
    return generateTokenPool(users); // Generates token pool
}

export default function(tokens) {
    const token = tokens[(__VU - 1) % tokens.length];
    http.get(`${BASE_URL}/organizations`, {
        headers: { Authorization: `Bearer ${token}` }
    });
}
```

### Generate Tokens Standalone

```bash id="generate-tokens"
k6 run scripts/generate_tokens.js
```

---

##  Adding New Tests

1. Create a new file in `tests/`.
2. Import modules:

```javascript id="new-test-import"
import http from 'k6/http';
import { check } from 'k6';
import { generateTokenPool } from '../scripts/generate_tokens.js';
```

3. Generate tokens in `setup()`.
4. Implement API calls in `default()`.
5. Add checks:

```javascript id="new-test-check"
check(res, { 'status is 200': (r) => r.status === 200 });
```

---

##  Customizing Load

```javascript id="custom-load"
export const options = {
    vus: 10,
    duration: '2m'
};

// Or ramping scenarios
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

This version includes **Chocolatey and K6 installation steps**, keeps cloning and running tests simple, and explains token usage clearly.

If you want, I can **also add a tiny “new endpoint template” section** at the bottom so any developer can just copy-paste to load test a new API quickly.

Do you want me to add that?
