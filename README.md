# MSUPPORT Load Test
## **Prerequisites**

* Install **k6** before starting.
* Git and a Windows/PowerShell environment are recommended.

---

## **Run Sample Test**

1. Clone the repository:

```powershell
git clone <your-repo-url>
cd MSUPPORT-performance-test
```

2. Run the sample script:

```powershell
k6 run tests/sample.js
```

3. You should see output like:

```text
✓ status is 200
http_req_duration: avg=xxx ms
```

> This confirms that k6 is installed and the test ran successfully.

---

## **Next Steps**

* Modify `sample.js` to test your own APIs.
* Increase **Virtual Users (VUs)** or **iterations** for proper load testing.
