# MSupport Performance Tests

This project uses k6 to test the MSupport API performance. It includes tests for login, creating tickets, searching, and more.

## What You Need

- Windows computer
- PowerShell
- k6 (install with `choco install k6`)

## Quick Setup

1. **Clone the repo:**
   ```bash
   git clone <your-repo-url>
   cd MSupport-performance-test
   ```

2. **Create `.env` file:**
   ```env
   BASE_URL=https://qa.msupport.mone.am/api/v1
   ```

3. **Run tests:**
   ```powershell
   .\run-all-tests.ps1
   ```

## How to Run Tests

### Run All Tests
```powershell
.\run-all-tests.ps1
```
This runs all tests at the same time in random order.

### Run One Test
```powershell
.\run-k6.ps1 run tests/create-tickets-test.js
```

### Change Test Settings
```powershell
.\run-k6.ps1 run -e VUS=20 -e DURATION=2m tests/login-test.js
```

## Project Files

```
MSupport-performance-test/
├── .env                    # API URL settings
├── run-k6.ps1             # Runs k6 with .env
├── run-all-tests.ps1      # Runs all tests together
├── scripts/
│   ├── config.js          # Shared settings
│   ├── generate_tokens.js # Login helper
│   └── reportTemplate.js  # Report maker
└── tests/
    ├── create-tickets-test.js
    ├── login-test.js
    ├── organizations-search-test.js
    ├── search-tickets-test.js
    └── update-tickets-status-test.js
```

## Settings

### Change API URL
Edit `.env`:
```env
BASE_URL=https://your-api-url.com/api/v1
```

### Change Test Load
In any test file, edit `options`:
```javascript
export const options = {
    vus: 10,        // Number of users
    duration: '1m'  // How long to run
};
```

## Reports

After running tests, check:
- `summary.html` - Web page with results
- Console output - Basic info

## Common Issues

- **"k6 not found"** → Install k6: `choco install k6`
- **API errors** → Check `BASE_URL` in `.env`
- **Login fails** → Check user passwords in `scripts/generate_tokens.js`
- **Tests slow** → Reduce `vus` in test options

## Need Help?

- Check the test files for examples
- Look at `scripts/` for shared code
- Run one test first to debug
