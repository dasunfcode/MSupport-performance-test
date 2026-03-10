import http from 'k6/http';
import { check } from 'k6';

export default function () {
    let res = http.get('https://test.k6.io'); // a public test site
    check(res, { 'status is 200': (r) => r.status === 200 });
}