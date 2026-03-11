import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 10,        // 10 virtual users
  duration: '1m',  // run test for 1 minutes
};

export default function () {

  const payload = JSON.stringify({
    email: "dasuntest5@gmail.com",
    password: "Ddh@sivalicc*99"
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'x-timezone': 'Asia/Colombo'
    }
  };

  const res = http.post(
    'https://uat.msupport.mone.am/api/v1/auth/login',
    payload,
    params
  );

  check(res, {
    'login succeeded': (r) => r.status === 200,
  });

  console.log(`VU ${__VU} LOGIN STATUS: ${res.status}`);
}