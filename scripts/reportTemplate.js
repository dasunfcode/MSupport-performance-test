// scripts/reportTemplate.js

/**
 * Generates a minimal HTML load test report with crucial metrics
 * @param {Object} data - k6 summary data
 * @param {string} testName - Optional name of the test / API
 * @returns {Object} - HTML only, with filename based on API name
 */
export function handleSummary(data, testName = "Load Test Summary") {
    // Metrics (safe fallback to 0)
    const httpReq = data.metrics.http_req_duration?.values ?? {};
    const totalReqs = data.metrics.http_reqs?.values?.count ?? 0;
    const failedReqs = data.metrics.http_req_failed?.values?.count ?? 0;
    const throughput = data.metrics.iterations?.values?.rate ?? 0;

    // Sanitize testName for filename (remove spaces/special chars)
    const safeFileName = testName.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');

    // Build HTML
    const html = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>${testName}</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            h1 { text-align: center; color: #333; }
            table { width: 50%; margin: 20px auto; border-collapse: collapse; }
            th, td { border: 1px solid #ccc; padding: 10px; text-align: center; }
            th { background-color: #f4f4f4; }
            tr:nth-child(even) { background-color: #fafafa; }
        </style>
    </head>
    <body>
        <h1>${testName}</h1>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Total Requests</td><td>${totalReqs}</td></tr>
            <tr><td>Failed Requests</td><td>${failedReqs}</td></tr>
            <tr><td>Avg Response Time (ms)</td><td>${httpReq.avg?.toFixed(2) ?? 0}</td></tr>
            <tr><td>Min Response Time (ms)</td><td>${httpReq.min?.toFixed(2) ?? 0}</td></tr>
            <tr><td>Max Response Time (ms)</td><td>${httpReq.max?.toFixed(2) ?? 0}</td></tr>
            <tr><td>p90 (ms)</td><td>${httpReq["p(90)"]?.toFixed(2) ?? 0}</td></tr>
            <tr><td>p95 (ms)</td><td>${httpReq["p(95)"]?.toFixed(2) ?? 0}</td></tr>
            <tr><td>Throughput (req/sec)</td><td>${throughput?.toFixed(2) ?? 0}</td></tr>
        </table>
    </body>
    </html>
    `;

    // Return with dynamic filename based on API name
    return { [`${safeFileName}.html`]: html };
}